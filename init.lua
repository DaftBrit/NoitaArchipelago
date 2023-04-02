-- Copyright (c) 2022 DaftBrit
--
-- This software is released under the MIT License.
-- https://opensource.org/licenses/MIT

-- CREDITS:
-- Noita API wrapper (for requires) taken from Dadido3/noita-mapcap
-- pollnet library (for websocket implementation) probable-basilisk/pollnet
-- noita-ws-api (for reference and initial websocket setup) probable-basilisk/noita-ws-api
-- cheatgui (for reference) probable-basilisk/cheatgui

-- TODO: We need to make sure we sync items per
-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#synchronizing-items

-- Apply patches to data files
dofile_once("data/archipelago/scripts/apply_ap_patches.lua")
ModMaterialsFileAdd("data/archipelago/materials.xml")

--LIBS
local pollnet = dofile("data/archipelago/lib/pollnet/init.lua")
local Log = dofile("data/archipelago/scripts/logger.lua")

local JSON = dofile("data/archipelago/lib/json.lua")
function JSON:onDecodeError(message, text, location, etc)
	Log.Error(message)
end

-- SCRIPTS
dofile_once("data/archipelago/scripts/ap_utils.lua")
dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/lib/mod_settings.lua")
dofile_once("data/archipelago/scripts/item_utils.lua")

local item_table = dofile("data/archipelago/scripts/item_mappings.lua")
local AP = dofile("data/archipelago/scripts/constants.lua")
local Biomes = dofile("data/archipelago/scripts/ap_biome_mapping.lua")

-- Modules
local Globals = dofile("data/archipelago/scripts/globals.lua")
local Cache = dofile("data/archipelago/scripts/caches.lua")


-- See Options.py on the AP-side
-- Can also use to indicate whether AP sent the connected packet
local slot_options = nil

local last_death_time = 0
local Games = {}
local player_slot_to_name = {}
local current_player_slot = -1
local sock = nil
local game_is_paused = true
local index = -1

-- Locations:
-- 110000-110499 Chests
-- 111000-111034 Holy mountain shops (5 each)
-- 111035-111038 Secret shop below the hourglass room by the Hiisi Base

----------------------------------------------------------------------------------------------------
-- DEATHLINK
----------------------------------------------------------------------------------------------------

-- Toggles DeathLink
local function SetDeathLinkEnabled(enabled)
	local conn_tags = { "AP", "WebHost" }
	if enabled ~= 0 and enabled ~= nil then
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
	if slot_options.victory_condition == 0 then
		CheckVictoryConditionFor("ap_greed_ending", "we're rich")
	elseif slot_options.victory_condition == 1 then
		CheckVictoryConditionFor("ap_pure_ending", "we're rich and alive")
	elseif slot_options.victory_condition == 2 then
		CheckVictoryConditionFor("ap_peaceful_ending", "I love nature")
	elseif slot_options.victory_condition == 3 then
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
	local item_name = Cache.ItemNames:get(item_id)
	if item_name == nil then
		error("item_name is nil")
	end

	if bit.band(flags, AP.ITEM_FLAG_TRAP) ~= 0 then
		item_name = TRAP_ITEM_NAMES[Random(1, #TRAP_ITEM_NAMES)]
	end

	if player_id == current_player_slot then
		return item_name
	end

	return GameTextGet("$ap_shopitem_name", player_slot_to_name[player_id], item_name)
end


-- Used to check and report any locations that have been discovered by external lua components
local function CheckComponentItemsUnlocked()
	local locations = Globals.LocationUnlockQueue:get_table()
	if #locations > 0 then
		SendCmd("LocationChecks", { locations = locations })
	end
	Globals.LocationUnlockQueue:reset()
end


local function ShouldDeliverItem(item)
	if item["player"] == current_player_slot then
		if item["location"] >= AP.FIRST_ITEM_LOCATION_ID and item["location"] <= AP.LAST_ITEM_LOCATION_ID then
			return false	-- Don't deliver shopitems, they are given locally
		elseif item["location"] >= AP.FIRST_PED_LOCATION_ID and item["location"] <= AP.LAST_PED_LOCATION_ID then
			return false	-- Don't deliver pedestal items, they are given locally
		elseif item["location"] >= AP.FIRST_HC_LOCATION_ID and item["location"] <= AP.LAST_HC_LOCATION_ID then
			return false
		end
	end
	return true
end


----------------------------------------------------------------------------------------------------
-- CACHE SETUP
----------------------------------------------------------------------------------------------------
-- Share location scouts with other Lua contexts via Noita globals
-- This workaround is necessary because the `io` module isn't accessible in other scripts.
local function ShareLocationScouts()
	local cache = Cache.LocationInfo:reference()
	Globals.LocationScouts:set_table(cache)
end

-- Request items we need to display (i.e. shops)
local function SetupLocationScouts()
	if Cache.LocationInfo:is_empty() then
		local locations = {}
		for i = AP.FIRST_ITEM_LOCATION_ID, AP.LAST_ITEM_LOCATION_ID do
			if Globals.MissingLocationsSet:has_key(i) then
				table.insert(locations, i)
			end
		end
		for i = AP.FIRST_ORB_LOCATION_ID, AP.LAST_ORB_LOCATION_ID do
			if Globals.MissingLocationsSet:has_key(i) then
				table.insert(locations, i)
			end
		end
		for _, biome_data in pairs(Biomes) do
			for i = biome_data.first_hc, biome_data.first_hc + 19 do
				if Globals.MissingLocationsSet:has_key(i) then
					table.insert(locations, i)
				end
			end
			for i = biome_data.first_ped, biome_data.first_ped + 19 do
				if Globals.MissingLocationsSet:has_key(i) then
					table.insert(locations, i)
				end
			end
		end
		SendCmd("LocationScouts", { locations = locations })
	else
		Log.Info("Restored LocationInfo from cache")
		ShareLocationScouts()
	end
end


local function SetupDataPackage()
	if Cache.ItemNames:is_empty() or Cache.LocationNames:is_empty() then
		SendCmd("GetDataPackage", { games = Games })
	else
		Log.Info("Restored DataPackage from cache")
		SetupLocationScouts()
	end
end


----------------------------------------------------------------------------------------------------
-- SPECIFIC MESSAGE HANDLING
----------------------------------------------------------------------------------------------------

-- Function names must match corresponding command name
local RECV_MSG = {}

local LOAD_KEY = "AP_FIRST_LOAD_DONE"

-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#Connected
function RECV_MSG.Connected(msg)
	SendCmd("Sync")
	GamePrint("$ap_connected_to_server")
	current_player_slot = msg["slot"]
	slot_options = msg["slot_data"]

	Globals.Seed:set(slot_options.seed)
	Globals.PlayerSlot:set(current_player_slot)
	-- todo: figure out why the below block doesn't work
	--if Globals.LoadKey:get() ~= "1" then
	--	print("new game has been started")
	--	Globals.LoadKey:set("1")
	--	Cache.ItemDelivery:reset()
	--	ResetOrbID()
	--	give_debug_items()
	--	--putting fully_heal() here doesn't work, it heals the player before redelivery of hearts
	--else
	--	print("continued the game")
	--end
	APConnectedNotifier()
	SetTimeOut(2, "data/archipelago/scripts/spawn_kill_saver.lua")
	if GlobalsGetValue(LOAD_KEY, "0") == "1" then
		APConnectedNotifier()
	else
		Cache.ItemDelivery:reset()
		--GlobalsSetValue(LOAD_KEY, "1")
		ResetOrbID() -- todo: check that this actually matters anymore
		if ModSettingGet("archipelago.debug_items") == true then
			give_debug_items()
		end
		--putting fully_heal() here doesn't work, it heals the player before redelivery of hearts
	end

	-- Retrieve all chest location ids the server is considering
	local missing_locations_set = {}
	local peds_checklist = {}
	for _, location in ipairs(msg["missing_locations"]) do
		missing_locations_set[location] = true
		if location >= AP.FIRST_PED_LOCATION_ID and location <= AP.LAST_PED_LOCATION_ID then
			peds_checklist[location] = true
		end
	end
	Globals.MissingLocationsSet:set_table(missing_locations_set)
	Globals.PedestalLocationsSet:set_table(peds_checklist)

	for k, plr in pairs(msg["players"]) do
		player_slot_to_name[plr["slot"]] = plr["name"]
	end

	for key, val in pairs(msg["slot_info"]) do
		table.insert(Games, val["game"])
	end

	-- Request DataPackage
	SetupDataPackage()

	-- Enable deathlink if the setting on the server said so
	SetDeathLinkEnabled(slot_options.death_link)
end

-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#receiveditems
function RECV_MSG.ReceivedItems(msg)
	if GlobalsGetValue(LOAD_KEY, "0") == "1" then
		-- we're in sync or we're continuing the game and receiving items in async
		local recv_index = msg["index"]
		for _, item in pairs(msg["items"]) do
			local item_id = item["item"]
			local sender = item["player"]
			local location_id = item["location"]

			local cache_key = Cache.make_key(sender, location_id)
			if not Cache.ItemDelivery:is_set(cache_key) then
				Cache.ItemDelivery:set(cache_key)

				if not GameHasFlagRun("ap_spawn_kill_saver") and item_table[item_id].redeliverable then
					SpawnItem(item_id, false)
				elseif GameHasFlagRun("ap_spawn_kill_saver") then
					if ShouldDeliverItem(item) then
						SpawnItem(item_id, true)
					end
				end
				index = index + 1
				if index ~= recv_index then
					SendCmd("Sync")
				end
			end
		end
	else
		-- we're starting a new game
		local ng_items = {}
		local sender = -1
		local table_length = 0
		for _, item in pairs(msg["items"]) do
			index = index + 1
			table_length = table_length + 1
			local item_id = item["item"]
			sender = item["player"]
			local location_id = item["location"]
			local cache_key = Cache.make_key(sender, location_id)
			Cache.ItemDelivery:set(cache_key)
			-- count up the items that should be delivered on new game
			if item_table[item_id].newgame then
				if ng_items[item_id] == nil then
					ng_items[item_id] = 1
				else
					ng_items[item_id] = ng_items[item_id] + 1
				end
			end
		end
		if sender == current_player_slot and index == 0 and table_length == 1 then
			-- player found their own item as their first item
		elseif table_length == 1 then
			-- first received item was sent by another player
			print("if an error is happening it's probably here in the received items script")
			for item, _ in ng_items do
				if GameHasFlagRun("ap_spawn_kill_saver") and item_table[item].redeliverable == true then
					SpawnItem(item, false)
				else
					SpawnItem(item, true)
				end
			end
		else
			NGSpawnItems(ng_items)
		end
		GlobalsSetValue(LOAD_KEY, "1")
	end
end


-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#datapackage
function RECV_MSG.DataPackage(msg)
	local item_names = Cache.ItemNames:reference()
	local location_names = Cache.LocationNames:reference()

	for _, game in pairs(msg["data"]["games"]) do
		for item_name, item_id in pairs(game["item_name_to_id"]) do
			-- Some games like Hollow Knight use underscores for whatever reason
			item_names[item_id] = string.gsub(item_name, "_", " ")
		end

		for location_name, location_id in pairs(game["location_name_to_id"]) do
			location_names[location_id] = string.gsub(location_name, "_", " ")
		end
	end

	Cache.ItemNames:write()
	Cache.LocationNames:write()
	SetupLocationScouts()
end


function ParseJSONPart(part)
	local result = ""
	if part["type"] == "player_id" then
		result = player_slot_to_name[tonumber(part["text"])]
	elseif part["type"] == "item_id" then
		result = Cache.ItemNames:get(tonumber(part["text"]))
	elseif part["type"] == "location_id" then
		result = Cache.LocationNames:get(tonumber(part["text"]))
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
			local item_name = Cache.ItemNames:get(item_id)
			GamePrintImportant(item_name, msg_str)
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
		if not slot_options.death_link or not UpdateDeathTime() then return end

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
-- This is the reply to the LocationScouts request
function RECV_MSG.LocationInfo(msg)
	local cache = Cache.LocationInfo:reference()

	-- Set global shop item names to share with the shop lua context
	for _, net_item in ipairs(msg["locations"]) do
		local item_id = net_item.item

		cache[net_item.location] = {
			item_name = GetItemName(net_item.player, item_id, net_item.flags),
			item_flags = net_item.flags,
			item_id = item_id,
			-- Differentiate between our items and items for other Noita worlds
			is_our_item = net_item.player == current_player_slot
		}
	end
	Cache.LocationInfo:write()
	ShareLocationScouts()
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
	local player_name = ModSettingGet("archipelago.slot_name")
	local password = ModSettingGet("archipelago.passwd") or ""
	local host = ModSettingGet("archipelago.server_address")
	local port = ModSettingGet("archipelago.server_port")

	local url = "ws://" .. host .. ":" .. port
	Log.Info("Connecting to " .. url .. "...")

	sock = pollnet.open_ws(url)

	if not sock then
		Log.Error("Failed to open socket")
		return
	end

	SendCmd("Connect", {
		password = password,
		game = "Noita",
		name = player_name,
		uuid = "NoitaClient",
		tags = { "AP", "WebHost" },
		version = { major = 0, minor = 3, build = 4, class = "Version" },
		items_handling = 7
	})
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

-- Gets network messages waiting on the socket and processes them
local function CheckNetworkMessages()
	while sock:poll() do
		local msg = GetNextMessage()
		if msg == nil then break end
		ProcessMsg(msg)
	end
end


-- Checks data toggled by external lua scripts that init.lua doesn't have access to
local function CheckGlobalsAndFlags()
	if slot_options ~= nil then
		CheckVictoryConditionFlag()
		CheckComponentItemsUnlocked()
		CheckLocationFlags()
	end
end


local function CheckPlayerMovement()
	local movement = isMovingRight()
    if movement then
        GlobalsSetValue(LOAD_KEY, "1")
    end
end


function InitializeArchipelagoThread()
	if not sock then
		InitSocket()
		if not sock then
			Log.Error("Unable to establish Archipelago connection")
		end
	end
end

----------------------------------------------------------------------------------------------------
-- NOITA CALLBACKS
----------------------------------------------------------------------------------------------------

-- Called every update frame in Noita
-- https://noita.wiki.gg/wiki/Modding:_Lua_API#OnWorldPostUpdate
function OnWorldPostUpdate()
	if sock ~= nil then
		CheckNetworkMessages()
		CheckGlobalsAndFlags()
	end
	if GlobalsGetValue(LOAD_KEY, "0") == "0" then
		CheckPlayerMovement()
	end
end


-- Called when the game is paused or unpaused
-- https://noita.wiki.gg/wiki/Modding:_Lua_API#OnPausedChanged
function OnPausedChanged(is_paused, is_inventory_pause)
	-- Workaround: When the player creates a new game, OnPlayerDied gets called (triggers DeathLink).
	-- However we know they have to pause the game (menu) to start a new game.
	game_is_paused = is_paused and not is_inventory_pause
end


-- Called when the player dies
-- https://noita.wiki.gg/wiki/Modding:_Lua_API#OnPlayerDied
function OnPlayerDied(player)
    if sock == nil or slot_options.death_link ~= 1 or game_is_paused or not UpdateDeathTime() then return end
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



-- Called when the player spawns
-- https://noita.wiki.gg/wiki/Modding:_Lua_API#OnPlayerSpawned
function OnPlayerSpawned(player)
	game_is_paused = false
	InitializeArchipelagoThread()
	APNotConnectedNotifier()
end
