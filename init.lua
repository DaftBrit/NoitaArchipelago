-- Copyright (c) 2022 Heinermann, Scipio Wright, DaftBrit
--
-- This software is released under the MIT License.
-- https://opensource.org/licenses/MIT

-- CREDITS:
-- Noita API wrapper (for requires) taken from Dadido3/noita-mapcap
-- pollnet library (for websocket implementation) probable-basilisk/pollnet
-- noita-ws-api (for reference and initial websocket setup) probable-basilisk/noita-ws-api
-- cheatgui (for reference) probable-basilisk/cheatgui


-- Apply patches to data files
dofile_once("data/archipelago/scripts/apply_ap_patches.lua")
ModMaterialsFileAdd("data/archipelago/materials.xml")
ModMagicNumbersFileAdd("data/archipelago/magic_numbers.xml")

--LIBS
local pollnet = dofile("data/archipelago/lib/pollnet/pollnet.lua")
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
local ConnIcon = dofile("data/archipelago/ui/connection_icon.lua")

-- See Options.py on the AP-side
-- Can also use to indicate whether AP sent the connected packet
local slot_options = nil

local last_death_time = 0
local game_list = {}
local player_slot_to_name = {}
local current_player_slot = -1
local sock = nil
local game_is_paused = false
local stored_index = -1
local new_checksums = false
local is_player_spawned = false
local goal_reached = false

----------------------------------------------------------------------------------------------------
-- DEATHLINK
----------------------------------------------------------------------------------------------------

-- Toggles DeathLink
local function SetDeathLinkEnabled(enabled)
	local conn_tags = { "AP" }
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


local function IsDeathLinkEnabled()
	return slot_options.death_link == 1 and ModSettingGet("archipelago.death_link")
end


----------------------------------------------------------------------------------------------------
-- VICTORY CONDITIONS
----------------------------------------------------------------------------------------------------

local function CheckVictoryConditionFor(flag, msg)
	if GameHasFlagRun(flag) then
		Log.Info(msg)
		SendCmd("StatusUpdate", {status = 30})
		GameRemoveFlagRun(flag)
		goal_reached = true
		if ModSettingGet("archipelago.auto_release") then
			SendCmd("Say", { text = "!release"})
		end
		if ModSettingGet("archipelago.auto_collect") then
			SendCmd("Say", { text = "!collect"})
		end
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
-- Creates a name based on the player_id, item_id, and flags to be presented as the name of an AP item
local function GetItemName(player_id, item_id, flags)
	local game_name = Cache.PlayerGames:get(player_id)
	local item_names = Cache.ItemNames:get(game_name)
	local item_name = item_names[tostring(item_id)]
	if item_name == nil then
		error("item_name is nil")
		item_name = "problem with LocationScouts"
	end

	if bit.band(flags, AP.ITEM_FLAG_TRAP) ~= 0 then
		item_name = GameTextGetTranslatedOrNot("$ap_trapname" .. Random(1, 10))
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
	local location_id = item["location"]
	if item["player"] == current_player_slot then
		if GameHasFlagRun("ap" .. location_id) then
			if location_id >= AP.FIRST_SHOP_LOCATION_ID and location_id <= AP.LAST_SHOP_LOCATION_ID or
					location_id >= AP.FIRST_SHOP_LOCATION_ID + AP.WEST_OFFSET and location_id <= AP.LAST_SHOP_LOCATION_ID + AP.WEST_OFFSET or
					location_id >= AP.FIRST_SHOP_LOCATION_ID + AP.EAST_OFFSET and location_id <= AP.LAST_SHOP_LOCATION_ID + AP.EAST_OFFSET then
				return false	-- Don't deliver shop items, they are given locally
			elseif location_id >= AP.FIRST_BIOME_LOCATION_ID and location_id <= AP.LAST_BIOME_LOCATION_ID or
					location_id >= AP.FIRST_BIOME_LOCATION_ID + AP.WEST_OFFSET and location_id <= AP.LAST_BIOME_LOCATION_ID + AP.WEST_OFFSET or
					location_id >= AP.FIRST_BIOME_LOCATION_ID + AP.EAST_OFFSET and location_id <= AP.LAST_BIOME_LOCATION_ID + AP.EAST_OFFSET then
				return false	-- Don't deliver pedestal or chest items, they're given locally
			end
			GameRemoveFlagRun("ap" .. location_id)
		else
			-- this is an item your co-op partner picked up in slot co-op
			remove_collected_item(location_id)
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
	GameAddFlagRun("AP_LocationInfo_received")
end

-- Request items we need to display (i.e. shops)
local function SetupLocationScouts(new_checksum)
	if Cache.LocationInfo:is_empty() or new_checksum == true then
		local locations = {}
		for i = AP.FIRST_SHOP_LOCATION_ID, AP.LAST_SHOP_LOCATION_ID do
			if Globals.MissingLocationsSet:has_key(i) then
				table.insert(locations, i)
				if slot_options.path_option == 4 and i < AP.FIRST_NON_PW_SHOP then -- no lab or secret shop
					table.insert(locations, i + AP.WEST_OFFSET)
					table.insert(locations, i + AP.EAST_OFFSET)
				end
			end
		end
		for i = AP.FIRST_ORB_LOCATION_ID, AP.LAST_ORB_LOCATION_ID do
			if Globals.MissingLocationsSet:has_key(i) then
				table.insert(locations, i)
				if slot_options.orbs_as_checks == 4 and i ~= 110661 then -- lava lake orb
					table.insert(locations, i + AP.WEST_OFFSET)
					table.insert(locations, i + AP.EAST_OFFSET)
				end
			end
		end
		for _, biome_data in pairs(Biomes) do
			for i = biome_data.first_hc, biome_data.first_hc + 19 do
				if Globals.MissingLocationsSet:has_key(i) then
					table.insert(locations, i)
					if slot_options.path_option == 4 then
						table.insert(locations, i + AP.WEST_OFFSET)
						table.insert(locations, i + AP.EAST_OFFSET)
					end
				end
			end
			for i = biome_data.first_ped, biome_data.first_ped + 19 do
				if Globals.MissingLocationsSet:has_key(i) then
					table.insert(locations, i)
					if slot_options.path_option == 4 then
						table.insert(locations, i + AP.WEST_OFFSET)
						table.insert(locations, i + AP.EAST_OFFSET)
					end
				end
			end
		end
		SendCmd("LocationScouts", { locations = locations })
	else
		Log.Info("Restored LocationInfo from cache")
		ShareLocationScouts()
	end
end


----------------------------------------------------------------------------------------------------
-- SPECIFIC MESSAGE HANDLING
----------------------------------------------------------------------------------------------------

-- Function names must match corresponding command name
local RECV_MSG = {}

local function ConnectionError(msg_str)
	-- commented out since it makes the user think there's a problem when there isn't one
	-- Log.Error(msg_str)
	ConnIcon:setDisconnected(msg_str)
end

function RECV_MSG.RoomInfo(msg)
	Globals.Seed:set(msg["seed_name"])
	local checksum_info = msg["datapackage_checksums"]
	-- todo: modify this after figuring out how to not overwrite entire cache when one checksum is different
	local checksum_hax
	for game, checksum in pairs(checksum_info) do
		if Cache.ChecksumVersions:get(game) ~= checksum then
			checksum_hax = true
			--table.insert(game_list, game)
		end
		table.insert(game_list, game)
	end

	--new_checksums = (#game_list ~= 0)
	if checksum_hax then
		new_checksums = true
		SendCmd("GetDataPackage", {games = game_list})
	else
		SendConnect()
	end
end


function SendConnect()
	local player_name = ModSettingGet("archipelago.slot_name")
	local password = ModSettingGet("archipelago.passwd") or ""
	SendCmd("Connect", {
		password = password,
		game = "Noita",
		name = player_name,
		uuid = "NoitaClient",
		tags = { "AP" },
		version = { major = 0, minor = 4, build = 1, class = "Version" },
		items_handling = 7
	})
end


local function SpawnReceivedItem(item)
	local item_id = item["item"]
	if ShouldDeliverItem(item) then
		if GameHasFlagRun("ap_spawn_kill_saver") then
			SpawnItem(item_id, true)
		elseif item_table[item_id].redeliverable then
			SpawnItem(item_id, false)
		end
	end
end


local function SpawnAllNewGameItems()
	local ng_items = {}
	for _, item in ipairs(Cache.ItemDelivery:reference()) do
		local item_id = item["item"]
		if item_table[item_id].newgame then
			ng_items[item_id] = (ng_items[item_id] or 0) + 1
		end
	end
	Log.Info("spawning starting items: " .. JSON:encode(ng_items))

	NGSpawnItems(ng_items)
end


local function RestoreNewGameItems()
	if not Globals.FirstLoadDone:is_set() then
		Globals.FirstLoadDone:set(1)

		ResetOrbID()
		SpawnAllNewGameItems()

		if ModSettingGet("archipelago.debug_items") then
			give_debug_items()
		end
	end
end


-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#Connected
function RECV_MSG.Connected(msg)
	GamePrint("$ap_connected_to_server")
	current_player_slot = msg["slot"]
	slot_options = msg["slot_data"]

	-- PlayerGames cache is a table showing what game each slot is playing, necessary for removing data version from ap
	local players_info = Cache.PlayerGames:reference()
	for slot, info in pairs(msg["slot_info"]) do
		players_info[slot] = info["game"]
	end
	Cache.PlayerGames:write()

	-- need these elsewhere
	if slot_options.victory_condition == 1 then
		GameAddFlagRun("ap_pure_goal")
	end
	if slot_options.victory_condition == 2 then
		GameAddFlagRun("ap_peaceful_goal")
	end
	if slot_options.shop_price ~= nil then
		GlobalsSetValue("ap_shop_price", slot_options.shop_price)
	end
	if slot_options.path_option == 4 then
		GameAddFlagRun("ap_parallel_worlds")
	end

	Globals.PlayerSlot:set(current_player_slot)
	ConnIcon:setConnected()

	-- spawn kill saver makes it so you won't get traps in the first couple seconds after connecting
	GameRemoveFlagRun("ap_spawn_kill_saver")
	SetTimeOut(2, "data/archipelago/scripts/spawn_kill_saver.lua")
	RestoreNewGameItems()

	-- Retrieve all chest location ids the server is considering
	local missing_locations_set = {}
	local peds_list = {}
	local peds_checklist = {}
	for _, biome_data in pairs(Biomes) do
		-- TODO move this out to biome_mapping.lua as `is_pedestal_location`
		for i = biome_data.first_ped, biome_data.first_ped + 19 do
			peds_list[i] = true
			if slot_options.path_option == 4 and i <= biome_data.first_ped + 9 then
				peds_list[i + AP.WEST_OFFSET] = true
				peds_list[i + AP.EAST_OFFSET] = true
			end
		end
	end
	for _, location in ipairs(msg["missing_locations"]) do
		missing_locations_set[location] = true
		if peds_list[location] == true then
			peds_checklist[location] = true
		end
	end
	Globals.MissingLocationsSet:set_table(missing_locations_set)
	Globals.PedestalLocationsSet:set_table(peds_checklist)

	for _, plr in pairs(msg["players"]) do
		player_slot_to_name[plr["slot"]] = plr["name"]
	end

	SetupLocationScouts(new_checksums)
	-- Enable deathlink if the setting on the server said so
	SetDeathLinkEnabled(slot_options.death_link)
end


-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#datapackage
function RECV_MSG.DataPackage(msg)
	local item_names = Cache.ItemNames:reference()
	local location_names = Cache.LocationNames:reference()
	local checksums = Cache.ChecksumVersions:reference()

	for game, data in pairs(msg["data"]["games"]) do
		local item_data = {}
		local location_data = {}
		for item_name, item_id in pairs(data["item_name_to_id"]) do
			-- Some games like Hollow Knight use underscores for whatever reason
			item_data[tostring(item_id)] = string.gsub(item_name, "_", " ")
		end

		for location_name, location_id in pairs(data["location_name_to_id"]) do
			location_data[tostring(location_id)] = string.gsub(location_name, "_", " ")
		end

		item_names[game] = item_data
		location_names[game] = location_data
		checksums[game] = data["checksum"]
	end

	Cache.ItemNames:write()
	Cache.LocationNames:write()
	Cache.ChecksumVersions:write()
	SendConnect()
end


local function CheckItemSync(msg)
	local next_item_index = msg["index"]

	local num_received_items = Cache.ItemDelivery:num_items()
	if next_item_index ~= num_received_items then
		local items_missed = next_item_index - num_received_items
		Log.Error("Missed " .. tostring(items_missed) .. " item(s) from the server, attempting to resync.")
		SendCmd("Sync")
		-- TODO: We also need to send LocationChecks for everything we've checked, per the network API specification
		-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#synchronizing-items
		return false
	end
	return true
end


-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#receiveditems
function RECV_MSG.ReceivedItems(msg)
	local next_item_index = msg["index"]
	if next_item_index ~= 0 then
		if not CheckItemSync(msg) then return end
	else
		-- TODO: Abandon previous inventory?
		-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#synchronizing-items
	end

	local is_first_time_connected = Cache.ItemDelivery:num_items() == 0
	for i, item in ipairs(msg["items"]) do
		local current_item_index = next_item_index + i

		-- we're in sync or we're continuing the game and receiving items in async
		if not Cache.ItemDelivery:is_set(current_item_index) then
			Cache.ItemDelivery:set(current_item_index, item)
			local item_id = item["item"]
			-- when connected for the first time, you get receiveditems along with connected
			-- but also, you want to give the player gold and stuff that got sent before spawning
			if is_first_time_connected and not item_table[item_id].newgame and item_table[item_id].redeliverable then
				SpawnReceivedItem(item)
			elseif not is_first_time_connected or GameHasFlagRun("ap_spawn_kill_saver") then
				SpawnReceivedItem(item)
			end
		end
	end

	if is_first_time_connected and not GameHasFlagRun("ap_spawn_kill_saver") then
		SpawnAllNewGameItems()
	end
end


local function ParseJSONPart(part)
	local result = ""
	if part["type"] == "player_id" then
		result = player_slot_to_name[tonumber(part["text"])]
	elseif part["type"] == "item_id" then
		local game = Cache.PlayerGames:get(part["player"])
		local item_names = Cache.ItemNames:get(game)
		result = item_names[tostring(part["text"])]
	elseif part["type"] == "location_id" then
		local game = Cache.PlayerGames:get(part["player"])
		local location_names = Cache.LocationNames:get(game)
		result = location_names[tostring(part["text"])]
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


-- Builds the JSON message
local function ParseJSONParts(data)
	local msg_strs = {}
	for _, part in ipairs(data) do
		table.insert(msg_strs, ParseJSONPart(part))
	end
	return table.concat(msg_strs)
end


local prev_countdown_number = -1
-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#PrintJSON
function RECV_MSG.PrintJSON(msg)
	if msg["type"] == "ItemSend" then
		local destination_player_id = msg["receiving"]
		local source_player_id = msg["item"]["player"]
		local item_id = msg["item"]["item"]

		local msg_str = ParseJSONParts(msg["data"])

		local is_destination_player = destination_player_id == current_player_slot
		local is_source_player = source_player_id == current_player_slot

		if (is_destination_player or is_source_player) and destination_player_id ~= source_player_id then
			local game = Cache.PlayerGames:get(destination_player_id)
			local item_names = Cache.ItemNames:get(game)
			local item_name = item_names[tostring(item_id)]
			GamePrintImportant(item_name, msg_str)
		else
			GamePrint(msg_str)
		end
	elseif msg["type"] == "Countdown" then
		local countdown_number = msg["countdown"]
		if countdown_number == 0 then
			countdown_fun()
			GamePrint("GO!")
		else
			-- it displays the first number twice otherwise
			if countdown_number ~= prev_countdown_number then
				GamePrint(countdown_number)
			end
			prev_countdown_number = countdown_number
		end
	else
		local msg_type = msg["type"] or "none"
		Log.Warn("Unsupported PrintJSON type " .. msg_type)
		if msg["data"] ~= nil then
			local msg_str = ParseJSONParts(msg["data"])
			GamePrint(msg_str)
		end
	end
end


-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#ConnectionRefused
function RECV_MSG.ConnectionRefused(msg)
	local msg_str = "Connection Refused"
	if msg["errors"] then
		msg_str = msg_str .. ": " .. table.concat(msg["errors"], ",")
	end
	ConnectionError(msg_str)
end


-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#bounced
function RECV_MSG.Bounced(msg)
	if contains_element(msg["tags"], "DeathLink") then
		if not IsDeathLinkEnabled() or not UpdateDeathTime() then return end
		local game_msg = GameTextGet("$ap_died", msg["data"]["source"])
		GamePrintImportant(game_msg, msg["data"]["cause"])

		local cause = msg["data"]["cause"]
		if cause == nil or cause == "" then
			cause = game_msg
		end

		local player = get_player()
		if not DecreaseExtraLife(player) then
			local gsc_id = EntityGetFirstComponentIncludingDisabled(player, "GameStatsComponent")
			if gsc_id ~= nil then
				ComponentSetValue2(gsc_id, "extra_death_msg", cause)
			end
			EntityKill(player)
		end

	else
		Log.Warn("Unsupported Bounced type received. " .. JSON:encode(msg))
	end
end


-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#LocationInfo
-- This is the reply to the LocationScouts request
function RECV_MSG.LocationInfo(msg)
	Cache.LocationInfo:reset() -- this is a workaround, if this isn't here it throws an error at Cache.LocationInfo:write()
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


function RECV_MSG.RoomUpdate(msg)
	for _, v in pairs(msg["checked_locations"]) do
		remove_collected_item(v)
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
function InitSocket(secure)
	local host = ModSettingGet("archipelago.server_address")
	local port = ModSettingGet("archipelago.server_port")

	local prefix = "ws://"
	if secure then
		prefix = "wss://"
	end
	-- if the user puts in ws:// or wss:// or http:// or https://, don't add a prefix
	if string.find(host, "//") then
		prefix = ""
	end
	local url = prefix .. host .. ":" .. port
	Log.Info("Connecting to " .. url .. "...")

	sock = pollnet.open_ws(url, 10 * 1024 * 1024)

	local error_msg = sock:error_msg()
	if error_msg ~= nil then
		ConnectionError("Failed to connect to the Archipelago server. " .. error_msg)
	end
end


-- Retrieves the last message from the socket and parses it into a Lua-digestible format
function GetMessages()
	local raw_msg = sock:last_message()
	if not raw_msg then return nil end

	Log.Info("RECV: " .. raw_msg)
	return JSON:decode(raw_msg)
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
	while true do
		local success, errmsg = sock:poll()
		if success == false then
			if errmsg ~= nil then
				ConnectionError(errmsg)
				if errmsg:find("TLS") or errmsg:find("-2146893048") then
					Log.Error("Connecting on an unsecure protocol...")
					InitSocket(false)
				end
			end
			break
		end

		local messages = GetMessages()
		if messages == nil then break end
		for _, msg in ipairs(messages) do
			ProcessMsg(msg)
		end
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


----------------------------------------------------------------------------------------------------
-- NOITA CALLBACKS
----------------------------------------------------------------------------------------------------

-- Called every update frame in Noita
-- https://noita.wiki.gg/wiki/Modding:_Lua_API#OnWorldPostUpdate
function OnWorldPostUpdate()
	ConnIcon:update()

	if is_player_spawned then
		CheckNetworkMessages()
		CheckGlobalsAndFlags()
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
	if slot_options == nil or not IsDeathLinkEnabled() or game_is_paused or not UpdateDeathTime() then return end
	local death_msg = GetCauseOfDeath() or "skill issue"
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

-- Called at the earliest possible time
-- https://noita.wiki.gg/wiki/Modding:_Lua_API#OnModInit
function OnModInit()
	GameRemoveFlagRun("AP_LocationInfo_received")
	create_dir("archipelago_cache")
	ConnIcon:create()
	InitSocket(true)
end

function OnPlayerSpawned()
	is_player_spawned = true
	GlobalsSetValue("ap_random_hax", 23)
end
