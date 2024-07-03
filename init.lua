-- Copyright (c) 2022 Heinermann, Scipio Wright, DaftBrit
--
-- This software is released under the MIT License.
-- https://opensource.org/licenses/MIT


-- Apply patches to data files
dofile_once("data/archipelago/scripts/apply_ap_patches.lua")
ModMaterialsFileAdd("data/archipelago/materials.xml")
ModMagicNumbersFileAdd("data/archipelago/magic_numbers.xml")

--LIBS
local APLIB = require("mods.archipelago.bin.lua-apclientpp")
local Log = dofile("data/archipelago/scripts/logger.lua")

local JSON = dofile("data/archipelago/lib/json.lua")
function JSON:onDecodeError(message, text, location, etc)
	Log.Warn(message)
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
local current_player_slot = -1
local game_is_paused = false
local is_player_spawned = false
local death_link_status = false

local ap = nil

----------------------------------------------------------------------------------------------------
-- DEATHLINK
----------------------------------------------------------------------------------------------------

-- Toggles DeathLink
local function SetDeathLinkEnabled(enabled)
	local conn_tags = { "Lua-APClientPP" }
	if enabled then
		table.insert(conn_tags, "DeathLink")
		death_link_status = true
	end
	ap:ConnectUpdate(nil, conn_tags)
end


-- Updates a death timer to prevent immediate re-sends of deaths that have been received.
local function UpdateDeathTime()
	local curr_death_time = os.time()
	if curr_death_time - last_death_time <= 1 then return false end
	last_death_time = curr_death_time
	return true
end


local function IsDeathLinkEnabled()
	if slot_options == nil then
		return 0
	end
	local death_link_setting = ModSettingGet("archipelago.death_link")
	if slot_options.death_link == 0 then
		return 0
	elseif death_link_setting == "on" then
		return 1
	elseif death_link_setting == "traps" then
		return 2
	else
		Log.Error("Error in IsDeathLinkEnabled")
		return 0
	end
end


----------------------------------------------------------------------------------------------------
-- VICTORY CONDITIONS
----------------------------------------------------------------------------------------------------

local function CheckVictoryConditionFor(flag, msg)
	if GameHasFlagRun(flag) then
		Log.Info(msg)
		ap:StatusUpdate(30)	-- ClientStatus.CLIENT_GOAL
		GameRemoveFlagRun(flag)
		if ModSettingGet("archipelago.auto_release") then
			ap:Say("!release")
		end
		if ModSettingGet("archipelago.auto_collect") then
			ap:Say("!collect")
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
	local item_name = ap:get_item_name(item_id)
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

	return GameTextGet("$ap_shopitem_name", ap:get_player_alias(player_id), item_name)
end


-- Used to check and report any locations that have been discovered by external lua components
local function CheckComponentItemsUnlocked()
	local locations = Globals.LocationUnlockQueue:get_table()
	if #locations > 0 then
		ap:LocationChecks(locations)
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
local function SetupLocationScouts()
	if Cache.LocationInfo:is_empty() then
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

		ap:LocationScouts(locations)
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
	Log.Warn(msg_str)
	ConnIcon:setDisconnected(msg_str)
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
	for _, item in pairs(Cache.ItemDelivery:reference()) do
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
function RECV_MSG.Connected()
	GamePrint("$ap_connected_to_server")
	ConnIcon:setConnected()

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

	current_player_slot = ap:get_player_number()
	Globals.PlayerSlot:set(current_player_slot)

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

	for _, location in ipairs(ap.missing_locations) do
		missing_locations_set[location] = true
		-- print("location is " .. location)
		if peds_list[location] == true then
			peds_checklist[location] = true
		end
	end
	Globals.MissingLocationsSet:set_table(missing_locations_set)
	Globals.PedestalLocationsSet:set_table(peds_checklist)

	SetupLocationScouts()
	-- Enable deathlink if the setting on the server and the mod setting said to
	SetDeathLinkEnabled(IsDeathLinkEnabled())
end

-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#receiveditems
function RECV_MSG.ReceivedItems(items)
	local is_first_time_connected = Cache.ItemDelivery:is_empty()
	for _, item in pairs(items) do
		-- we're in sync or we're continuing the game and receiving items in async
		if not Cache.ItemDelivery:is_set(tostring(item.index)) then
			Cache.ItemDelivery:set(tostring(item.index), item)
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


-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#PrintJSON
function RECV_MSG.PrintJSON(msg, extra)
	local msg_str = ap:render_json(msg, APLIB.RenderFormat.TEXT)

	if extra["type"] == "ItemSend" then
		local destination_player_id = extra["receiving"]
		local source_player_id = extra["item"]["player"]
		local item_id = extra["item"]["item"]

		local is_destination_player = destination_player_id == current_player_slot
		local is_source_player = source_player_id == current_player_slot

		if (is_destination_player or is_source_player) and destination_player_id ~= source_player_id then
			local item_name = ap:get_item_name(item_id)
			GamePrintImportant(item_name, msg_str)
			return
		end
	elseif extra["type"] == "Countdown" then
		local countdown_number = extra["countdown"]
		if countdown_number == 0 then
			countdown_fun()
		end
	end

	GamePrint(msg_str)
	Log.Info(msg_str)
end


-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#bounced
function RECV_MSG.Bounced(msg)
	if contains_element(msg["tags"], "DeathLink") then
		local death_link_option = IsDeathLinkEnabled()
		if death_link_option == 0 or not UpdateDeathTime() then return end

		local cause = msg["data"]["cause"]
		local source = msg["data"]["source"]

		if cause == nil or cause == "" then
			if death_link_option == 1 then
				GamePrintImportant(source .. " died and took you with them")
			else
				GamePrintImportant(source .. " died and is trying to take you with them")
			end
		else
			GamePrintImportant(cause)
		end

		if death_link_option == 1 then
			local player = get_player()
			if not DecreaseExtraLife(player) then
				local gsc_id = EntityGetFirstComponentIncludingDisabled(player, "GameStatsComponent")
				if gsc_id ~= nil then
					ComponentSetValue2(gsc_id, "extra_death_msg", cause)
				end
				EntityKill(player)
			end
		else
			BadTimes()
		end

	else
		Log.Warn("Unsupported Bounced type received. " .. JSON:encode(msg))
	end
end


-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#LocationInfo
-- This is the reply to the LocationScouts request
function RECV_MSG.LocationInfo(items)
	Cache.LocationInfo:reset() -- this is a workaround, if this isn't here it throws an error at Cache.LocationInfo:write()
	local cache = Cache.LocationInfo:reference()
	-- Set global shop item names to share with the shop lua context
	for _, net_item in ipairs(items) do
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
-- ASYNC THREAD
----------------------------------------------------------------------------------------------------

local function CheckLocationFlags()
	local locations_checked = {}
	for location_id, flag in pairs(LocationFlags) do
		if GameHasFlagRun(flag) then
			table.insert(locations_checked, location_id)
			GameRemoveFlagRun(flag)
		end
	end
	if #locations_checked > 0 then
		ap:LocationChecks(locations_checked)
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
-- NEW AP MESSAGE HANDLING
----------------------------------------------------------------------------------------------------
local GAME_NAME = "Noita"
local ITEMS_HANDLING = 7 -- full remote

local function connect()
	local host = ModSettingGet("archipelago.server_address")
	local port = ModSettingGet("archipelago.server_port")
	local slot_name = ModSettingGet("archipelago.slot_name")
	local password = ModSettingGet("archipelago.passwd") or ""
	local uuid = "NoitaClient"

	local function on_socket_connected()
		Log.Info("Socket connected")
	end

	local function on_socket_error(msg)
		ConnectionError(msg)
	end

	local function on_socket_disconnected()
		ConnectionError("Socket disconnected")
	end

	local function on_room_info()
		Log.Info("on_room_info")
		Globals.Seed:set(ap:get_seed())
		-- client version 0.4.1
		ap:ConnectSlot(slot_name, password, ITEMS_HANDLING, {"Lua-APClientPP"}, { 0, 4, 1 })
	end

	local function on_slot_connected(slot_data)
		Log.Info("on_slot_connected: " .. JSON:encode(slot_data))
		slot_options = slot_data
		RECV_MSG.Connected()
	end

	local function on_slot_refused(reasons)
		ConnectionError("Slot refused: " .. table.concat(reasons, ", "))
	end

	local function on_items_received(items)
		Log.Info("on_items_received: " .. JSON:encode(items))
		RECV_MSG.ReceivedItems(items)
	end

	local function on_location_info(items)
		Log.Info("on_location_info: " .. JSON:encode(items))
		RECV_MSG.LocationInfo(items)
	end

	local function on_location_checked(locations)
		Log.Info("on_location_checked: " .. JSON:encode(locations))
		for _, location_id in pairs(locations) do
			remove_collected_item(location_id)
		end
	end

	local function on_print_json(msg, extra)
		RECV_MSG.PrintJSON(msg, extra)
	end

	local function on_bounced(bounce)
		Log.Info("on_bounced: " .. JSON:encode(bounce))
		RECV_MSG.Bounced(bounce)
	end

	ap = APLIB(uuid, GAME_NAME, host .. ":" .. port);

	ap:set_socket_connected_handler(on_socket_connected)
	ap:set_socket_error_handler(on_socket_error)
	ap:set_socket_disconnected_handler(on_socket_disconnected)
	ap:set_room_info_handler(on_room_info)
	ap:set_slot_connected_handler(on_slot_connected)
	ap:set_slot_refused_handler(on_slot_refused)
	ap:set_items_received_handler(on_items_received)
	ap:set_location_info_handler(on_location_info)
	ap:set_location_checked_handler(on_location_checked)
	ap:set_print_json_handler(on_print_json)
	ap:set_bounced_handler(on_bounced)
end


----------------------------------------------------------------------------------------------------
-- NOITA CALLBACKS
----------------------------------------------------------------------------------------------------

-- Called every update frame in Noita
-- https://noita.wiki.gg/wiki/Modding:_Lua_API#OnWorldPostUpdate
function OnWorldPostUpdate()
	ConnIcon:update()

	if is_player_spawned then
		ap:poll()
		CheckGlobalsAndFlags()
	end
end


-- Called when the game is paused or unpaused
-- https://noita.wiki.gg/wiki/Modding:_Lua_API#OnPausedChanged
function OnPausedChanged(is_paused, is_inventory_pause)
	-- Workaround: When the player creates a new game, OnPlayerDied gets called (triggers DeathLink).
	-- However we know they have to pause the game (menu) to start a new game.
	game_is_paused = is_paused and not is_inventory_pause
	if IsDeathLinkEnabled() > 0 and death_link_status == false then
		SetDeathLinkEnabled(true)
		death_link_status = true
	end
	if IsDeathLinkEnabled() == 0 and death_link_status == true then
		SetDeathLinkEnabled(false)
		death_link_status = false
	end
end


-- Called when the player dies
-- https://noita.wiki.gg/wiki/Modding:_Lua_API#OnPlayerDied
function OnPlayerDied(player)
	if slot_options == nil or IsDeathLinkEnabled() == 0 or game_is_paused or not UpdateDeathTime() then return end
	local death_msg = GetCauseOfDeath() or "skill issue"
	local slotname = ModSettingGet("archipelago.slot_name")
	ap:Bounce({
		time = last_death_time,
		cause = slotname .. " died to " .. death_msg,
		source = slotname
	}, nil, nil, {"DeathLink"})
end

-- Called at the earliest possible time
-- https://noita.wiki.gg/wiki/Modding:_Lua_API#OnModInit
function OnModInit()
	GameRemoveFlagRun("AP_LocationInfo_received")
	create_dir("archipelago_cache")
	ConnIcon:create()
	connect()
end

function OnPlayerSpawned()
	is_player_spawned = true
	GlobalsSetValue("ap_random_hax", 23)
end
