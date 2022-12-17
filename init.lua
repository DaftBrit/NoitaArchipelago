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

-- TODO: We need to make sure we sync items per 
-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#synchronizing-items

-- GLOBAL STUFF
local libPath = "data/archipelago/lib/"
dofile_once(libPath .. "noita-api/compatibility.lua")(libPath)
dofile_once("data/scripts/lib/coroutines.lua") -- Loads Noita's coroutines wrapper library

-- Apply patches in this file
dofile_once("data/archipelago/scripts/apply_ap_patches.lua")

--LIBS
local pollnet = require("pollnet.init")
local sqlite = require("sqlite.init")

dofile_once("data/archipelago/lib/json.lua")
function JSON:onDecodeError(message, text, location, etc)
	Log.Error(message)
end

--CONF
dofile_once("data/archipelago/scripts/host.lua")

-- SCRIPTS
dofile_once("data/archipelago/scripts/ap_utils.lua")
dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/lib/mod_settings.lua")
dofile_once("data/archipelago/scripts/item_utils.lua")

local Log = dofile("data/archipelago/scripts/logger.lua")
local item_table = dofile("data/archipelago/scripts/item_mappings.lua")
local AP = dofile("data/archipelago/scripts/constants.lua")

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
local location_id_to_name = {}
local current_player_slot = -1
local sock = nil

-- Locations:
-- 110000-110499 Chests
-- 111000-111034 Holy mountain shops (5 each)
-- 111035-111038 Secret shop below the hourglass room by the Hiisi Base

----------------------------------------------------------------------------------------------------
-- DEATHLINK
----------------------------------------------------------------------------------------------------

-- Toggles DeathLink
local function SetDeathLinkEnabled(enabled)
	death_link = enabled

	local conn_tags = { "AP", "WebHost" }
	if enabled then
		table.insert(conn_tags, "DeathLink")
	end
	SendCmd("ConnectUpdate", { tags = conn_tags })
end


-- Updates a death timer to prevent immediate re-sends of deaths that have been received.
local function UpdateDeathTime()
	local curr_death_time = os.time()
	if curr_death_time - last_death_time <= 1 then return false end
	last_death_time = curr_death_time
	return true
end


----------------------------------------------------------------------------------------------------
-- VICTORY CONDITIONS
----------------------------------------------------------------------------------------------------

local function CheckVictoryConditionFor(flag, msg)
	if GameHasFlagRun(flag) then
		Log.Info(msg)
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


----------------------------------------------------------------------------------------------------
-- SHOP AND ITEM MANAGEMENT
----------------------------------------------------------------------------------------------------
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

-- Creates a name based on the player_id, item_id, and flags to be presented as the name of an AP item
local function GetItemName(player_id, item_id, flags)
	local item_name = item_id_to_name[item_id]
	if bit.band(flags, AP.ITEM_FLAG_TRAP) ~= 0 then
		SetRandomSeed(item_id, flags)
		item_name = TRAP_ITEM_NAMES[Random(1, #TRAP_ITEM_NAMES)]
	end

	if player_id == current_player_slot then
		-- TODO item name localization too?
		return GameTextGet("$ap_your_shopitem_name", item_name)
	end

	return GameTextGet("$ap_shopitem_name", player_slot_to_name[player_id], item_name)
end


-- Used to check and report any locations that have been discovered by external lua components
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


local function ShouldDeliverItem(item)
	-- Was it sent by us, to us?
	if item["player"] == current_player_slot then
		-- Was it in a chest? Then we are relying on this.
		return item["location"] >= AP.FIRST_CHEST_LOCATION_ID and item["location"] <= AP.LAST_CHEST_LOCATION_ID
	end
	return true
end

----------------------------------------------------------------------------------------------------
-- SPECIFIC MESSAGE HANDLING
----------------------------------------------------------------------------------------------------

-- Function names must match corresponding command name
local RECV_MSG = {}

-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#Connected
function RECV_MSG.Connected(msg)
	SendCmd("Sync")
	GamePrint("$ap_connected_to_server")
	current_player_slot = msg["slot"]

	-- Retrieve all chest location ids the server is considering
	check_list = {}
	for _, location in ipairs(msg["missing_locations"]) do
		if location >= AP.FIRST_CHEST_LOCATION_ID and location <= AP.LAST_CHEST_LOCATION_ID then
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


-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#receiveditems
function RECV_MSG.ReceivedItems(msg)
	for _, item in pairs(msg["items"]) do
		if ShouldDeliverItem(item) then
			SpawnItem(item["item"], true)
		end
	end
end


-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#datapackage
function RECV_MSG.DataPackage(msg)
	for _, game in pairs(msg["data"]["games"]) do
		for item_name, item_id in pairs(game["item_name_to_id"]) do
			-- Some games like Hollow Knight use underscores for whatever reason
			item_id_to_name[item_id] = string.gsub(item_name, "_", " ")
		end

		for location_name, location_id in pairs(game["location_name_to_id"]) do
			location_id_to_name[location_id] = string.gsub(location_name, "_", " ")
		end
	end

	-- Request items we need to display (i.e. shops)
	local locations = {}
	for i = AP.FIRST_SHOPITEM_LOCATION_ID, AP.LAST_SHOPITEM_LOCATION_ID do
		table.insert(locations, i)
	end
	SendCmd("LocationScouts", { locations = locations })
end


function ParseJSONPart(part)
	local result = ""
	if part["type"] == "player_id" then
		result = player_slot_to_name[tonumber(part["text"])]
	elseif part["type"] == "item_id" then
		result = item_id_to_name[tonumber(part["text"])]
	elseif part["type"] == "location_id" then
		result = location_id_to_name[tonumber(part["text"])]
	elseif part["type"] == "color" then
		Log.Info("Found colour in message: " .. part["color"])
		result = ""	-- TODO color not supported
	else
		-- text, player_name, item_name, location_name, entrance_name
		result = part["text"]
	end

	if result == nil then
		Log.Error("Failed to retrieve text for " .. part["type"] .. " " .. part["text"])
		return ""
	end
	return result
end

-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#PrintJSON
function RECV_MSG.PrintJSON(msg)
	if msg["type"] == "ItemSend" then
		local destination_player_id = msg["receiving"]
		local source_player_id = msg["item"]["player"]
		local item_id = msg["item"]["item"]

		-- Build the message
		local msg_str = ""
		for _, part in ipairs(msg["data"]) do
			msg_str = msg_str .. ParseJSONPart(part)
		end

		local is_destination_player = destination_player_id == current_player_slot
		local is_source_player = source_player_id == current_player_slot

		if (is_destination_player or is_source_player) and destination_player_id ~= source_player_id then
			GamePrintImportant(item_id_to_name[item_id], msg_str)
		else
			GamePrint(msg_str)
		end
	else
		Log.Warn("Unsupported PrintJSON type " .. msg["type"])
	end
end


-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#Print
function RECV_MSG.Print(msg)
	GamePrint(msg["text"])
end


-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#ConnectionRefused
function RECV_MSG.ConnectionRefused(msg)
	local msg_str = "Connection Refused"
	if msg["errors"] then
		msg_str = msg_str .. ": " .. table.concat(msg["errors"], ",")
	end
	Log.Error(msg_str)
end


-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#bounced
function RECV_MSG.Bounced(msg)
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
		Log.Warn("Unsupported Bounced type received. " .. JSON:encode(msg))
	end
end


-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#LocationInfo
function RECV_MSG.LocationInfo(msg)
	-- Set global shop item names to share with the shop lua context
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

----------------------------------------------------------------------------------------------------
-- CORE MESSAGE HANDLING
----------------------------------------------------------------------------------------------------

-- Note: These functions are not local because of some weird access shenanigans with Lua.
-- It'll break if they are local.

-- Encodes and sends a command over the socket
function SendCmd(cmd, data)
	data = data or {}
	data["cmd"] = cmd

	local cmd_str = JSON:encode({data})
	Log.Info("SENT: " .. cmd_str)
	sock:send(cmd_str)
end


-- Initializes the socket for AP communication
function InitSocket()
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


-- Retrieves the last message from the socket and parses it into a Lua-digestible format
function GetNextMessage()
	local raw_msg = sock:last_message()
	if not raw_msg then return nil end

	Log.Info("RECV: " .. raw_msg)
	return JSON:decode(raw_msg)[1]
end


-- Finds the appropriate function in the lookup table for a message, and calls it
function ProcessMsg(msg)
	local cmd = msg["cmd"]

	if RECV_MSG[cmd] then
		RECV_MSG[cmd](msg)
	else
		Log.Warn("Unsupported command '" .. cmd .. "' received. " .. JSON:encode(msg))
	end
end

----------------------------------------------------------------------------------------------------
-- ASYNC THREAD
----------------------------------------------------------------------------------------------------

local function AsyncThread()
	while sock:poll() do
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

		-- TODO move these chest shenanigans out of here into a remote item_pickup script

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


function InitializeArchipelagoThread()
	-- main function wrapper
	InitSocket()
	if sock then
		async(AsyncThread)
	else
		Log.Error("Unable to establish Archipelago connection")
	end
end

----------------------------------------------------------------------------------------------------
-- NOITA CALLBACKS
----------------------------------------------------------------------------------------------------

-- https://noita.wiki.gg/wiki/Modding:_Lua_API#OnWorldPostUpdate
function OnWorldPostUpdate()
	wake_up_waiting_threads(1)
end


-- https://noita.wiki.gg/wiki/Modding:_Lua_API#OnPausedChanged
function OnPausedChanged(is_paused, is_inventory_pause)
	-- Workaround: When the player creates a new game, OnPlayerDied gets called (triggers DeathLink).
	-- However we know they have to pause the game (menu) to start a new game.
	game_is_paused = is_paused and not is_inventory_pause
end


-- https://noita.wiki.gg/wiki/Modding:_Lua_API#OnPlayerDied
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


local LOAD_KEY = "archipelago_first_load_done"
-- https://noita.wiki.gg/wiki/Modding:_Lua_API#OnPlayerSpawned
function OnPlayerSpawned(player)
	game_is_paused = false
	
	InitializeArchipelagoThread()
	-- ask the game if it's a new game. If no, end here. If yes, do the below actions, which includes marking it as not a new game.
	if GlobalsGetValue(LOAD_KEY, "0") == "1" then
		Log.Info("you loaded")
		return
	end
	GlobalsSetValue(LOAD_KEY, "1")

	-- For debugging
	give_debug_items()
end
