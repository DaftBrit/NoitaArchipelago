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
local libPath = "mods/archipelago/files/libraries/"
dofile(libPath .. "noita-api/compatibility.lua")(libPath)
if not async then
	dofile_once("data/scripts/lib/coroutines.lua") -- Loads Noita's coroutines library from `data/scripts/lib/coroutines.lua`.
end
_G.item_check = 0

-- TRANSLATIONS
local TRANSLATIONS_FILE = "data/translations/common.csv"
local translations = ModTextFileGetContent(TRANSLATIONS_FILE) .. ModTextFileGetContent("data/translations/ap_common.csv")
ModTextFileSetContent(TRANSLATIONS_FILE, translations)

-- SCRIPT EXTENSIONS
ModLuaFileAppend("data/scripts/biomes/temple_altar.lua", "mods/archipelago/files/scripts/ap_extend_temple_altar.lua")
ModLuaFileAppend("data/scripts/biomes/boss_arena.lua", "mods/archipelago/files/scripts/ap_extend_temple_altar.lua")

--LIBS
local pollnet = require("pollnet.init")
local sqlite = require("sqlite.init")

--CONF
dofile("mods/archipelago/files/conf/host.lua")

-- SCRIPTS
dofile("mods/archipelago/files/scripts/ap_utils.lua")
dofile("mods/archipelago/files/scripts/json.lua")
dofile_once("data/scripts/lib/utilities.lua")
dofile("data/scripts/lib/mod_settings.lua")
ModLuaFileAppend("data/scripts/perks/perk_list.lua", "mods/archipelago/files/ap_extend_perk_list.lua")
ModLuaFileAppend("data/entities/animals/boss_centipede/ending/sampo_start_ending_sequence.lua", "mods/archipelago/files/scripts/ap_extend_ending.lua")

-- CURRENT PROBLEMS:
-- Orbs are noisy
-- Double item spawns when being sent items


-- TODO:
-- Shop spawns (heinermann doing this)

local chest_counter = 0
local last_death_time = 0
local death_link = false
local Games = {}
local player_slot_to_name = {}
local check_list = {}
local item_id_to_name = {}
local current_slot = 0

local TRAP_STR = "TRAP"
local item_table = {
	["110000"] = { TRAP_STR, TRAP_STR },

	["110001"] = {EntityLoadAtPlayer, "data/entities/items/pickup/heart.xml" },
	["110002"] = {EntityLoadAtPlayer, "data/entities/items/pickup/spell_refresh.xml" },
	["110003"] = {EntityLoadAtPlayer, "data/entities/items/pickup/potion.xml" },

	["110004"] = {EntityLoadAtPlayer, "data/entities/items/pickup/goldnugget_10.xml" },
	["110005"] = {EntityLoadAtPlayer, "data/entities/items/pickup/goldnugget_50.xml" },
	["110006"] = {EntityLoadAtPlayer, "data/entities/items/pickup/goldnugget_200.xml" },
	["110007"] = {EntityLoadAtPlayer, "data/entities/items/pickup/goldnugget_1000.xml" },

	["110008"] = {EntityLoadAtPlayer, "data/entities/items/wand_level_01.xml" },
	["110009"] = {EntityLoadAtPlayer, "data/entities/items/wand_level_02.xml" },
	["110010"] = {EntityLoadAtPlayer, "data/entities/items/wand_level_03.xml" },
	["110011"] = {EntityLoadAtPlayer, "data/entities/items/wand_level_04.xml" },
	["110012"] = {EntityLoadAtPlayer, "data/entities/items/wand_level_05.xml" },
	["110013"] = {EntityLoadAtPlayer, "data/entities/items/wand_level_06.xml" },

	["110014"] = {give_perk, "PROTECTION_FIRE" },
	["110015"] = {give_perk, "PROTECTION_RADIOACTIVITY" },
	["110016"] = {give_perk, "PROTECTION_EXPLOSION" },
	["110017"] = {give_perk, "PROTECTION_MELEE" },
	["110018"] = {give_perk, "PROTECTION_ELECTRICITY" },
	["110019"] = {give_perk, "EDIT_WANDS_EVERYWHERE" },
	["110020"] = {give_perk, "REMOVE_FOG_OF_WAR" },
	["110021"] = {give_perk, "RESPAWN" },
	["110022"] = {EntityLoadAtPlayer, "data/entities/items/orbs/ap_orb_base_quiet.xml" },
}
--Item table names are weird because there was intent to do something like 
--item_table[item_id][1](item_table[item_id][2]) for spawning stuff, but it didn't work

-- Locations:
-- 110000-110499 Chests
-- 111000-111034 Holy mountain shops (5 each)
-- 111035-111038 Secret shop below the hourglass room by the Hiisi Base

local sock = nil

-- Traps
local function BadTimes()
	--Function to spawn "Bad Times" events, uses the noita streaming integration system
	dofile("mods/archipelago/files/scripts/ap_badtimes.lua")
	math.randomseed(os.time())
	local event_id = math.random(1, #streaming_events)
	for i,v in pairs( streaming_events ) do
		if i == event_id then
			local event_desc = v["id"]:gsub("_", " ")
			GamePrintImportant("$ap_bad_times", event_desc)
			_streaming_run_event(v["id"])
			break
		end
	end
end

dofile_once("data/scripts/perks/perk.lua")
function give_perk(perk_name)
--Function to spawn a perk at the player and then have the player automatically pick it up
	for i, p in ipairs(get_players()) do
		local x, y = EntityGetTransform(p)
		local perk = perk_spawn(x, y, perk_name)
		perk_pickup(perk, p, EntityGetName(perk), false, false)
	end
end

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
	print(message)
end

local function GetNextMessage()
	local raw_msg = sock:last_message()
	if not raw_msg then return nil end

	print("RECV: " .. raw_msg)
	return JSON:decode(raw_msg)[1]
end

-- Not necessary but just so we know that these are globals
check_list = {}
slot_number = -1

local function RecvMsgConnected(msg)
	SendCmd("Sync")
	GamePrint("$ap_connected_to_server")
	slot_number = msg["slot"]

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
			local item_id = tostring(msg["items"][key]["item"])
			if tostring(msg["items"][key]["player"]) == tostring(slot_number) then
				print("Don't resend own items")
			else
				if item_table[item_id][1] == TRAP_STR then
					-- BadTimes()
					print("No badtimes today")
				elseif item_table[item_id][1] == EntityLoadAtPlayer then
					EntityLoadAtPlayer(item_table[item_id][2])
					print("Item spawned!")
				else
					give_perk(item_table[item_id][2])
					print("Perk spawned!")
				end
			end
		end
--			local item_id = msg["items"][key]["item"]
--			local str_item_id = tostring(item_id)
			--Dont repeat bad events
--			if item_table[str_item_id] ~= TRAP_STR then
--				EntityLoadAtPlayer(item_table[str_item_id])
end

local function RecvMsgDataPackage(msg)
	for i, g in pairs(msg["data"]["games"]) do
		for item_name, item_id in pairs(msg["data"]["games"][i]["item_name_to_id"]) do
			item_id_to_name[tostring(item_id)] = item_name
		end
	end

	-- Request items we need to display (i.e. shops)
	local locations = {}
	for i=111000,111034 do
		table.insert(locations, i)
	end
	SendCmd("LocationScouts", { locations = locations })
end

local function RecvMsgPrintJSON(msg)
	if msg["type"] == "ItemSend" then
		local player = players[msg["item"]["player"]]
		--print("player "..player)
		local item_string = msg["data"][2]["text"]
		--print("item string"..item_string)
		local item_id = msg["data"][3]["text"]
		--print("item id "..item_id)
		local item_name = item_id_to_name[item_id]
		local player_to = players[msg["receiving"]]
		local sender = msg["data"][1]["text"]
		local location_id = msg["data"][5]["text"]
		if item_string == " found their " then
			if item_table[item_id] ~= TRAP_STR then
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
			if item_table[item_id] ~= TRAP_STR then
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
		if msg["receiving"] == slot_number then
			if item_table[item_id][1] == TRAP_STR then
				BadTimes()
				print("bad times spawned from recvmsgprintjson")
			elseif item_table[item_id][1] == EntityLoadAtPlayer then
				EntityLoadAtPlayer(item_table[item_id][2])
				print("item spawned from recvmsgprintjson")
			else
				give_perk(item_table[item_id][2])
				print("perk spawned from recvmsgprintjson")
--				item_table[item_id][1](item_table[item_id][2])
--				Couldn't get this to work, if you can figure it out it'd be a much cleaner way to implement item spawning
			end
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

-- Modified from @Priskip in Noita Discord (https://github.com/Priskip)
-- Removes an Extra Life perk and returns true if one exists
local function DecreaseExtraLife(entity_id)
	local children = EntityGetAllChildren(entity_id)
	for _, child in ipairs(children) do
		local effect_component = EntityGetFirstComponentIncludingDisabled(child, "GameEffectComponent")
		local effect_value = ComponentGetValue2(effect_component, "effect")

		if effect_value == "RESPAWN" and ComponentGetValue2(effect_component, "mCounter") == 0 then
			--Remove extra life child
			EntityKill(child)

			--Remove UI component
			for _2, child2 in ipairs(children) do
				local child_ui_icon_component = EntityGetFirstComponentIncludingDisabled(child2, "UIIconComponent")
				local name_value = ComponentGetValue2(child_ui_icon_component, "name")

				if name_value == "$perk_respawn" then
					EntityKill(child2)
					break
				end
			end

			GamePrintImportant("$log_gamefx_respawn", "$logdesc_gamefx_respawn")
			return true
		end
	end
	return false
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

local function GetItemName(player, item)
	if player == current_slot then
		-- TODO item localization?
		return item_id_to_name[item]	-- or "Your itemname"?
	end
	return GameTextGet("$ap_shopitem_name", player_slot_to_name[player], item_id_to_name[item])
end

-- Set global shop item names to share with the shop lua context
local function RecvMsgLocationInfo(msg)
	for _, net_item in ipairs(msg["locations"]) do
		local item = tostring(net_item["item"])
		local location = net_item["location"]
		local player = net_item["player"]
		local flags = net_item["flags"]

		GlobalsSetValue("AP_SHOPITEM_NAME_" .. tostring(location), GetItemName(player, item))
		GlobalsSetValue("AP_SHOPITEM_FLAGS_" .. tostring(location), flags)

		-- TODO: Handle perks
		if item_table[item] ~= nil then
			GlobalsSetValue("AP_SHOPITEM_OVERRIDE_" .. tostring(location), item_table[item][2])
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
	["LocationInfo"] = RecvMsgLocationInfo
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
				EntityLoadAtPlayer("data/entities/items/pickup/ap_chest_random.xml", 20, 0)
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

function GetCauseOfDeath()
	local raw_death_msg = StatsGetValue("killed_by")
	local origin, cause = string.match(raw_death_msg, "(.*) | (.*)")

	if origin then
		origin = GameTextGetTranslatedOrNot(origin)
	end

	local result = 'Noita'
	if not_empty(origin) and not_empty(cause) then
		if origin:sub(-1) == 's' then
			result = GameTextGet("$menugameover_causeofdeath_killer_cause_name_ends_in_s", origin, cause)
		else
			result = GameTextGet("$menugameover_causeofdeath_killer_cause", origin, cause)
		end
	elseif not_empty(origin) then
		result = origin
	elseif not_empty(cause) then
		result = cause
	end

	return result .. StatsGetValue("killed_by_extra")
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
	local x, y = EntityGetTransform(player)
	local items = {
    "data/entities/items/wand_level_10.xml",
    }
	give_perk("PROTECTION_EXPLOSION")
	give_perk("PROTECTION_FIRE")
    add_items_to_inventory(player, items)
	EntityLoad( "data/entities/items/pickup/ap_chest_random.xml", x + 20, y ) -- for testing
	EntityLoad( "data/entities/items/pickup/ap_chest_random.xml", x + 40, y ) -- for testing
	EntityLoad( "data/entities/items/pickup/ap_chest_random.xml", x + 60, y ) -- for testing
	EntityLoad( "data/entities/items/pickup/ap_chest_random.xml", x + 80, y ) -- for testing
	EntityLoad( "data/entities/items/pickup/ap_chest_random.xml", x + 100, y ) -- for testing
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