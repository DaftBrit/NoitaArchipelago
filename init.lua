-- Copyright (c) 2022 DaftBrit
--
-- This software is released under the MIT License.
-- https://opensource.org/licenses/MIT

-- CREDITS:
-- Noita API wrapper (for requires) taken from Dadido3/noita-mapcap
-- pollnet library (for websocket implementation) probable-basilisk/pollnet
-- noita-ws-api (for reference and initial websocket setup) probable-basilisk/noita-ws-api
-- cheatgui (for reference) probable-basilisk/cheatgui
-- sqlite FFI ColonelThirtyTwo/lsqlite3-ffi

-- TODO: We need to make sure we sync items per https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#synchronizing-items

-- GLOBAL STUFF
local libPath = "data/archipelago/lib/"
dofile_once(libPath .. "noita-api/compatibility.lua")(libPath)
if not async then
	dofile_once("data/scripts/lib/coroutines.lua") -- Loads Noita's coroutines library from `data/scripts/lib/coroutines.lua`.
end

-- Apply patches in this file
dofile_once("data/archipelago/scripts/apply_ap_patches.lua")

--LIBS
local pollnet = require("pollnet.init")
local sqlite = require("sqlite.init")

--CONF
dofile_once("data/archipelago/scripts/host.lua")

-- SCRIPTS
dofile_once("data/archipelago/scripts/ap_utils.lua")
dofile_once("data/archipelago/lib/json.lua")
dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/lib/mod_settings.lua")

-- CURRENT PROBLEMS:
-- Orbs are noisy
-- Double item spawns when being sent items


local chest_counter = 0
local last_death_time = 0
local death_link = false
local Games = {}
local player_slot_to_name = {}
local check_list = {}
local item_id_to_name = {}
local current_player_slot = -1

local item_table = dofile("data/archipelago/scripts/item_mappings.lua")

dofile_once("data/archipelago/scripts/item_utils.lua")

-- Locations:
-- 110000-110499 Chests
-- 111000-111034 Holy mountain shops (5 each)
-- 111035-111038 Secret shop below the hourglass room by the Hiisi Base

local sock = nil

local function SendCmd(cmd, data)
	data = data or {}
	data["cmd"] = cmd

	local cmd_str = JSON:encode({data})
	print("SENT: " .. cmd_str)
	sock:send(cmd_str)
end

local function SetDeathLinkEnabled(enabled)
	death_link = enabled

	local conn_tags = { "AP", "WebHost" }
	if enabled then
		table.insert(conn_tags, "DeathLink")
	end
	SendCmd("ConnectUpdate", { tags = conn_tags })
end

local function InitSocket()
	if not sock then
		local PLAYERNAME = ModSettingGet("archipelago.slot_name")
		local PASSWD = ModSettingGet("archipelago.passwd") or ""
		local url = get_ws_host_url() -- comes from data/ws/host.lua
		if not url then return false end
		sock = pollnet.open_ws(url)
		SendCmd("Connect", {
			password = PASSWD,
			game = "Noita",
			name = PLAYERNAME,
			uuid = "NoitaClient",
			tags = { "AP", "WebHost" },
			version = { major = 0, minor = 3, build = 4, class = "Version" },
			items_handling = 7
		})
	end
end

function JSON:onDecodeError(message, text, location, etc)
	print_error(message)
end

local function GetNextMessage()
	local raw_msg = sock:last_message()
	if not raw_msg then return nil end

	print("RECV: " .. raw_msg)
	return JSON:decode(raw_msg)[1]
end

local function RecvMsgConnected(msg)
	SendCmd("Sync")
	GamePrint("$ap_connected_to_server")
	current_player_slot = msg["slot"]

	-- Retrieve all chest location ids the server is considering
	check_list = {}
	for _, location in ipairs(msg["missing_locations"]) do
		if location >= 110000 or location <= 110500 then
			table.insert(check_list, location)
		end
	end

	for k, plr in pairs(msg["players"]) do
		player_slot_to_name[plr["slot"]] = plr["name"]
	end

	for key, val in pairs(msg["slot_info"]) do
		table.insert(Games, val["game"])
	end
	SendCmd("GetDataPackage", { games = Games })

	-- Enable deathlink if the setting on the server said so
	death_link = msg["slot_data"]["deathLink"] == 1
	SetDeathLinkEnabled(death_link)

	bad_effects = msg["slot_data"]["badEffects"]
	victory_condition = msg["slot_data"]["victoryCondition"]
	orbs_as_checks = msg["slot_data"]["orbsAsChecks"]
	bosses_as_checks = msg["slot_data"]["bossesAsChecks"]
end

local function RecvMsgReceivedItems(msg)
	--Item sync for items already sent
--	if ModSettingGet("archipelago.redeliver_items") then -- disabled for testing
		for key, val in pairs(msg["items"]) do
			local item_id = msg["items"][key]["item"]
			if msg["items"][key]["player"] == current_player_slot then
				print("Don't resend own items")
			else
				SpawnItem(item_id, true)
			end
		end
end

local function RecvMsgDataPackage(msg)
	for i, _ in pairs(msg["data"]["games"]) do
		for item_name, item_id in pairs(msg["data"]["games"][i]["item_name_to_id"]) do
			-- Some games like Hollow Knight use underscores for whatever reason
			item_id_to_name[item_id] = string.gsub(item_name, "_", " ")
		end
	end

	-- Request items we need to display (i.e. shops)
	local locations = {}
	for i = AP.FIRST_SHOPITEM_LOCATION_ID, AP.LAST_SHOPITEM_LOCATION_ID do
		table.insert(locations, i)
	end
	SendCmd("LocationScouts", { locations = locations })
end

local function RecvMsgPrintJSON(msg)
	if msg["type"] == "ItemSend" then
		local player = player_slot_to_name[msg["item"]["player"]]
		--print("player "..player)
		local item_string = msg["data"][2]["text"]
		--print("item string"..item_string)
		local item_id = tonumber(msg["data"][3]["text"])
		--print("item id "..item_id)
		local item_name = item_id_to_name[item_id]
		local player_to = player_slot_to_name[msg["receiving"]]
		local sender = msg["data"][1]["text"]
		local location_id = msg["data"][5]["text"]
		if item_string == " found their " then
			if item_id ~= AP.TRAP_ID then
				if player == PLAYERNAME or player_to == PLAYERNAME then
					--We only want popup messages for our items sent / received
					GamePrintImportant(item_name, player .. item_string .. item_name)
				else
					--Less important messaging in the bottom left
					GamePrint(player .. item_string .. item_name)
				end
			end
		end
		if item_string == " sent " then
			local item_string2 = msg["data"][4]["text"]
			if item_id ~= AP.TRAP_ID then
				if player == PLAYERNAME or player_to == PLAYERNAME then
					--We only want popup messages for our items sent / received
					GamePrintImportant(item_name, player .. item_string ..item_name .. item_string2 .. player_to)
				else
					--Less important messaging in the bottom left
					GamePrint(player .. item_string .. item_name .. item_string2 .. player_to)
				end
			end
		end
		-- Item Spawning
		if msg["receiving"] == current_player_slot then
			SpawnItem(item_id)
		end
	end
end

local function RecvMsgPrint(msg)
	GamePrint(msg["text"])
end

local function UpdateDeathTime()
	local curr_death_time = os.time()
	if curr_death_time - last_death_time <= 1 then return false end
	last_death_time = curr_death_time
	return true
end

local function RecvMsgBounced(msg)
	if contains_element(msg["tags"], "DeathLink") then
		if not death_link or not UpdateDeathTime() then return end

		GamePrintImportant(GameTextGet("$ap_died", msg["data"]["source"]), msg["data"]["cause"])

		for i, p in ipairs(get_players()) do
			if not DecreaseExtraLife(p) then
				local gsc_id = EntityGetFirstComponentIncludingDisabled(p, "GameStatsComponent")
				ComponentSetValue2(gsc_id, "extra_death_msg", msg["data"]["cause"])
				EntityKill(p)
			end
		end
	else
		print("Unsupported Bounced type received. " .. JSON:encode(msg))
	end
end

local TRAP_ITEM_NAMES = {
	"Infinite Lives",
	"Godmode",
	"9999 Rupees",
	"Debug Mode",
	"Instant Victory",
	"Unlimited Resources",
	"Unlimited Power",
	"Infinite Energy",
	"Unlimited Food",
	"The Best Item Ever"
}
local function GetItemName(player, item, flags)
	local item_name = item_id_to_name[item]
	if bit.band(flags, AP.ITEM_FLAG_TRAP) ~= 0 then
		SetRandomSeed(item, flags)
		item_name = TRAP_ITEM_NAMES[Random(1, #TRAP_ITEM_NAMES)]
	end

	if player == current_player_slot then
		-- TODO item name localization too?
		return GameTextGet("$ap_your_shopitem_name", item_name)
	end

	return GameTextGet("$ap_shopitem_name", player_slot_to_name[player], item_name)
end

-- Set global shop item names to share with the shop lua context
local function RecvMsgLocationInfo(msg)
	for _, net_item in ipairs(msg["locations"]) do
		local item = net_item.item
		local location = tostring(net_item.location)

		GlobalsSetValue("AP_SHOPITEM_NAME_" .. location, GetItemName(net_item.player, item, net_item.flags))
		GlobalsSetValue("AP_SHOPITEM_FLAGS_" .. location, net_item.flags)
		GlobalsSetValue("AP_SHOPITEM_ITEM_ID_" .. location, tostring(item))

		-- We need a way to determine whether the item is meant for us or a different Noita instance
		if (net_item.player == current_player_slot) then
			GlobalsSetValue("AP_SHOPITEM_IS_OURS_" .. location, "1")
		end
	end
end

local recv_msg_table = {
	["Connected"] = RecvMsgConnected,
	["ReceivedItems"] = RecvMsgReceivedItems,
	["DataPackage"] = RecvMsgDataPackage,
	["PrintJSON"] = RecvMsgPrintJSON,
	["Print"] = RecvMsgPrint,
	["Bounced"] = RecvMsgBounced,
	["LocationInfo"] = RecvMsgLocationInfo,
}

local function ProcessMsg(msg)
	local cmd = msg["cmd"]

	if recv_msg_table[cmd] then
		recv_msg_table[cmd](msg)
	else
		print("Unsupported command '" .. cmd .. "' received. " .. JSON:encode(msg))
	end
end

local function CheckVictoryConditionFor(flag, msg)
	if GameHasFlagRun(flag) then
		print(msg)
		SendCmd("StatusUpdate", {status = 30})
		GameRemoveFlagRun(flag)
	end
end

local function CheckVictoryConditionFlag()
	if victory_condition == 0 then
		CheckVictoryConditionFor("ap_greed_ending", "we're rich")
	elseif victory_condition == 1 then
		CheckVictoryConditionFor("ap_pure_ending", "we're rich and alive")
	elseif victory_condition == 2 then
		CheckVictoryConditionFor("ap_peaceful_ending", "I love nature")
	elseif victory_condition == 3 then
		CheckVictoryConditionFor("ap_yendor_ending", "red pixel pog")
	end
end


local function CheckComponentItemsUnlocked()
	local purchase_queue = GlobalsGetValue("AP_COMPONENT_ITEM_UNLOCK_QUEUE")
	GlobalsSetValue("AP_COMPONENT_ITEM_UNLOCK_QUEUE", "")

	local locations = {}
	for item in string.gmatch(purchase_queue, "[^,]+") do
		table.insert(locations, tonumber(item))
	end
	if #locations > 0 then
		SendCmd("LocationChecks", { locations = locations })
	end
end

local function AsyncThread()
	while sock:poll() do
		-- Message read loop and variable set

		CheckVictoryConditionFlag()
		CheckComponentItemsUnlocked()

		local msg = GetNextMessage()
		if msg then
			ProcessMsg(msg)

			if check_list[1] then
				next_item = check_list[1]
			end
		else
			wait(1)
		end

		-- Item check and message send
		if next_item then
			for i, p in ipairs(get_players()) do
				local x, y = EntityGetTransform(p)
				local radius = 15
				local pickup = EntityGetInRadiusWithTag( x, y, radius, "archipelago")
				if pickup[1] then
					SendCmd("LocationChecks", { locations = { next_item } })
					EntityKill( pickup[1] )
					table.remove(check_list, 1)
				end
			end
		end

		-- Spawn chest on X kills
		if ModSettingGet("archipelago.kill_count") > 0 then
			local kills = StatsGetValue("enemies_killed")
			local per_kill = math.floor(ModSettingGet("archipelago.kill_count"))
			local count = (kills / per_kill) - chest_counter
			if count == 1 then
				EntityLoadAtPlayer("data/entities/items/pickup/chest_random.xml", 20, 0)
				GamePrint(GameTextGet("$ap_kills_spawned_chest", kills))
				chest_counter = chest_counter + 1
			end
		end
	end
end

function archipelago()
	-- main function wrapper
	InitSocket()
	if sock then
		async(AsyncThread)
	else
		print("Unable to establish Archipelago connection")
	end
end

function OnWorldPostUpdate()
	wake_up_waiting_threads(1)
end

-- Workaround: When the player creates a new game, OnPlayerDied gets called.
-- However we know they have to pause the game (menu) to start a new game.
game_is_paused = false
function OnPausedChanged(is_paused, is_inventory_pause)
	game_is_paused = is_paused and not is_inventory_pause
end

function OnPlayerDied(player)
	if not sock or not death_link or game_is_paused or not UpdateDeathTime() then return end

	local death_msg = GetCauseOfDeath()
	local slotname = ModSettingGet("archipelago.slot_name")
	SendCmd("Bounce", {
		tags = { "DeathLink" },
		data = {
			time = last_death_time,
			cause = slotname .. " died to " .. death_msg,
			source = slotname
		}
	})
end

function add_items_to_inventory(player, items)
  for _, path in ipairs(items) do
    local item = EntityLoad(path)
    if item then
      GamePickUpInventoryItem(player, item)
    else
      GamePrint("Error: Couldn't load the item ["..path.."]!")
    end
  end
end

local LOAD_KEY = "archipelago_first_load_done"
function OnPlayerSpawned(player)
	archipelago()
	-- ask the game if it's a new game. If no, end here. If yes, do the below actions, which includes marking it as not a new game.
	if GlobalsGetValue(LOAD_KEY, "0") == "1" then
		print("you loaded")
		return
	end
	GlobalsSetValue(LOAD_KEY, "1")
	local items = {
    "data/entities/items/wand_level_10.xml",
  }
	give_perk("PROTECTION_EXPLOSION")
	give_perk("PROTECTION_FIRE")
  add_items_to_inventory(player, items)
	EntityLoadAtPlayer( "data/entities/items/pickup/chest_random.xml", 20 ) -- for testing
	EntityLoadAtPlayer( "data/entities/items/pickup/chest_random.xml", 40 ) -- for testing
	EntityLoadAtPlayer( "data/entities/items/pickup/chest_random.xml", 60 ) -- for testing
	EntityLoadAtPlayer( "data/entities/items/pickup/chest_random.xml", 80 ) -- for testing
	EntityLoadAtPlayer( "data/entities/items/pickup/chest_random.xml", 100 ) -- for testing
	give_perk("MOVEMENT_FASTER") -- for testing gotta go fast
	give_perk("MOVEMENT_FASTER") -- for testing
	give_perk("HOVER_BOOST") -- for testing
	give_perk("FASTER_LEVITATION") -- for testing
	EntityLoadAtPlayer("data/entities/items/pickup/goldnugget_200000.xml") -- for testing we're rich we're rich
	EntityLoadAtPlayer("data/entities/items/pickup/goldnugget_200000.xml") -- for testing
	EntityLoadAtPlayer("data/entities/items/pickup/goldnugget_200000.xml") -- for testing
	EntityLoadAtPlayer("data/entities/items/pickup/goldnugget_200000.xml") -- for testing
	EntityLoadAtPlayer("data/entities/items/pickup/goldnugget_200000.xml") -- for testing
	EntityLoadAtPlayer("data/entities/items/pickup/heart_better.xml")
	EntityLoadAtPlayer("data/entities/items/pickup/heart_better.xml")
	EntityLoadAtPlayer("data/entities/items/pickup/heart_better.xml")
	EntityLoadAtPlayer("data/entities/items/pickup/heart_better.xml")
	EntityLoadAtPlayer("data/entities/items/pickup/heart_better.xml")
	EntityLoadAtPlayer("data/entities/items/pickup/heart_better.xml")
	EntityLoadAtPlayer("data/entities/items/pickup/heart_better.xml")
end