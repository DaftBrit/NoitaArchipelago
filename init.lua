-- Copyright (c) 2022 Heinermann, Scipio Wright, DaftBrit
--
-- This software is released under the MIT License.
-- https://opensource.org/licenses/MIT

local MOD_VERSION = "1.6.0"

dofile_once("data/archipelago/lib/pathcheck.lua")

-- Apply patches to data files
dofile_once("data/archipelago/scripts/apply_ap_patches.lua")
ModMaterialsFileAdd("data/archipelago/materials.xml")
ModMagicNumbersFileAdd("data/archipelago/magic_numbers.xml")

--LIBS
local APLIB = require(ModPath():gsub("/", ".") .. "bin.lua-apclientpp") ---@type APClient
local Log = dofile("data/archipelago/scripts/logger.lua") ---@type Logger

local JSON = dofile("data/archipelago/lib/json.lua")
function JSON:onDecodeError(message, text, location, etc)
	Log.Warn(message)
end

-- SCRIPTS
dofile_once("data/archipelago/scripts/ap_utils.lua")
dofile_once("data/archipelago/scripts/item_utils.lua")
local UUID = dofile_once("data/archipelago/lib/uuid.lua") --- @type UUID

local item_table = dofile("data/archipelago/scripts/item_mappings.lua")
local AP = dofile("data/archipelago/scripts/constants.lua")
local Biomes = dofile("data/archipelago/scripts/ap_biome_mapping.lua")
local ShopItems = dofile("data/archipelago/scripts/shopitem_utils.lua")

-- Modules
local Globals = dofile("data/archipelago/scripts/globals.lua") --- @type Globals
local Cache = dofile("data/archipelago/scripts/caches.lua") --- @type Caches
local ConnIcon = dofile("data/archipelago/ui/connection_icon.lua") --- @type ConnIcon
local LogWindow = dofile("data/archipelago/ui/log_window.lua") --- @type LogWindow
local PauseMenu = dofile("data/archipelago/ui/pause_menu.lua") --- @type PauseMenu
--local TrapMenu = dofile("data/archipelago/ui/trap_menu.lua") --- @type TrapMenu
local Modlist = dofile("data/archipelago/lib/modlist.lua") --- @type Modlist

-- Links
local LinkManagerCls = dofile("data/archipelago/scripts/links/LinkManager.lua") --- @type LinkManager
local DamageLinkCls = dofile("data/archipelago/scripts/links/DamageLink.lua") --- @type DamageLink
local DeathLinkCls = dofile("data/archipelago/scripts/links/DeathLink.lua") --- @type DeathLink
local KnockbackLinkCls = dofile("data/archipelago/scripts/links/KnockbackLink.lua") --- @type KnockbackLink
local TrapLinkCls = dofile("data/archipelago/scripts/links/TrapLink.lua") --- @type TrapLink

-- See Options.py on the AP-side
-- Can also use to indicate whether AP sent the connected packet

---@class HintTableEntry
---@field receiving_player integer player slot receiving the item
---@field item integer item id of the item
---@field location integer location id of the item inside the world
---@field player integer player slot of the world the item is located in
---@field flags itemflags bit flags for item classification
---@field item_name string (added after receiving) name of the item
---@field player_name string (added after receiving) name of the slot meant to find the item
---@field location_name string (added after receiving) name of the location the item is at
---@field receiver_name string (added after receiving) name of the player receiving the item

---@class SlotOpts
---@field victory_condition integer?
---@field death_link integer?
---@field trap_link integer?
---@field damage_link integer?
---@field knockback_link integer?
---@field path_option integer?
---@field orbs_as_checks integer?
---@field shop_price number?
---@field lock_portals integer?
---@field hints HintTableEntry[]? Tablet hints
---@field room_uid integer? Unique id specific to the room, distinct from other rooms using the same seed


---@type SlotOpts?
local slot_options = nil

local prev_connect_tags_str = ""
local connect_tags = {
	["Lua-APClientPP"] = 1
}

local current_player_slot = -1
local game_is_paused = false
local is_player_spawned = false
local messages_setting = "all"
local forced_disconnect = false
local req_restart = false
local hostname = ""
local hint_location_received = {}

local uuid = UUID.generate()
local ap = nil --- @type APClient
local gui = GuiCreate()

local LinkManager = LinkManagerCls(uuid)
local DamageLink = DamageLinkCls()
local DeathLink = DeathLinkCls()
local KnockbackLink = KnockbackLinkCls()
local TrapLink = TrapLinkCls()
LinkManager:RegisterLinks(DamageLink, DeathLink, KnockbackLink, TrapLink)


----------------------------------------------------------------------------------------------------
-- SLOT
----------------------------------------------------------------------------------------------------

---@param opts SlotOpts?
local function SetSlotOptions(opts)
	slot_options = opts
	LinkManager:SetSlotOptions(opts)
end

---@return string[] taglist
local function GetConnectionTags()
	local tags_arr = {}
	for tag, _ in pairs(connect_tags) do
		table.insert(tags_arr, tag)
	end
	return tags_arr
end

local function UpdateConnectionTags()
	if slot_options == nil then return end

	local new_conn_tags = GetConnectionTags()

	local new_conn_tags_str = table.concat(new_conn_tags, ",")
	if new_conn_tags_str == prev_connect_tags_str then return end
	prev_connect_tags_str = new_conn_tags_str

	ap:ConnectUpdate(nil, new_conn_tags)
end

----------------------------------------------------------------------------------------------------
-- VICTORY CONDITIONS
----------------------------------------------------------------------------------------------------

local function CheckVictoryConditionFor(flag, msg)
	if GameHasFlagRun(flag) then
		Log.Info(msg)
		ap:StatusUpdate(APClient.ClientStatus.GOAL)
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
-- Creates a name based on the player_id, item_id, and flags to be presented as the name of an AP item
local function GetItemName(player_id, item_id, flags)
	local player_game = ap:get_player_game(player_id)
	local item_name = ap:get_item_name(item_id, player_game)
	if item_name == nil then
		error("item_name is nil")
		item_name = "problem with LocationScouts"
	end

	-- if it is trap + some other classification, we don't want to override its name
	if bit.band(flags, AP.ITEM_FLAG_TRAP) ~= 0 and bit.band(flags, AP.ITEM_FLAG_PROGRESSION) == 0 and bit.band(flags, AP.ITEM_FLAG_USEFUL) == 0 then
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

---@param location_id integer
---@return boolean
local function AlreadyHinted(location_id)
	if hint_location_received[tonumber(location_id)] then return true end
	return Globals.ShopScouted:has_key(location_id)
end

-- TODO handle case where you send but lose connection and can't hint again
-- Maybe just remove the cache and always send on a per-game basis
local function CheckShopScouted()
	local hint_queue = Globals.ShopScoutedQueue:get_table()
	if #hint_queue > 0 then
		for _, hint in ipairs(hint_queue) do
			local shop_locations = ShopItems.get_related_shop_locations(hint)
			local check_locations = {}
			for _, location in ipairs(shop_locations) do
				if not AlreadyHinted(location) then
					table.insert(check_locations, location)
				end
			end
			if #check_locations == 0 then goto continue end

			local hints_sent = Globals.ShopScouted:get_table()
			for _, location in ipairs(check_locations) do
				hints_sent[tostring(location)] = true
			end

			Log.Info("Sending request to reveal hints: \n" .. JSON:encode(check_locations))

			-- create_as_hint = 2  reveals the hint and prevents re-notifications
			ap:LocationScouts(check_locations, 2)
			Globals.ShopScouted:set_table(hints_sent)

			::continue::
		end
	end
	Globals.ShopScoutedQueue:reset()
end


local function ShouldDeliverItem(item)
	local location_id = item["location"]
	if item["player"] == current_player_slot then
		if GameHasFlagRun("ap" .. location_id) then
			-- item links is extremely weird, this is the easy way to make it work correctly
			local location = Globals.LocationScouts:get_key(location_id)
			if not location.is_our_item then
				return true
			end
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

--- Share location scouts with other Lua contexts via Noita globals
--- This workaround is necessary because the `io` module isn't accessible in other scripts.
local function ShareLocationScouts()
	local cache = Cache.LocationInfo:reference()
	Globals.LocationScouts:set_table(cache)
	GameAddFlagRun("AP_LocationInfo_received")
end

--- Request items we need to display (i.e. shops, pedestals)
local function SetupLocationScouts()
	if Cache.LocationInfo:is_empty() then
		local locations = {}
		for _, i in ipairs(AP.ALL_SCOUT_LOCATIONS) do
			if Globals.MissingLocationsSet:has_key(i) then
				table.insert(locations, i)
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
	SetSlotOptions(nil)
	Log.Warn(msg_str)
	ConnIcon:setDisconnected(msg_str)
end


---@param item NetworkItem
local function SpawnReceivedItem(item)
	if ShouldDeliverItem(item) then
		local item_id = item.item
		TrySpawnItem(item_id)
	end
end


---Items failed due to being polymorphed so the player entity was not found.
local function CheckRedeliveryQueue()
	local items = Globals.RedeliveryQueue:get_table()
	Globals.RedeliveryQueue:reset()
	for _, item_id in ipairs(items) do
		TrySpawnItem(item_id)
	end
end


local function SpawnAllNewGameItems()
	local ng_items = {}
	for _, item in pairs(Cache.ItemDelivery:reference()) do
		local item_id = item.item
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


local function ForceDisconnect(msg)
	forced_disconnect = true
	ConnectionError(msg .. "\nPlease update the settings and restart the game.")
end

---@param hints HintTableEntry[]
local function SetupHints(hints)
	for _, hint in ipairs(hints) do
		hint.player_name = ap:get_player_alias(hint.player)
		hint.location_name = ap:get_location_name(hint.location, ap:get_player_game(hint.player))
		hint.receiver_name = ap:get_player_alias(hint.receiving_player)
		hint.item_name = ap:get_item_name(hint.item, ap:get_player_game(hint.receiving_player))
	end
	Globals.HiddenHints:set_table(hints)
end

-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#Connected
function RECV_MSG.Connected()
	if GameHasFlagRun("ap_connected_once") then
		if tostring(ap:get_player_number()) ~= Globals.PlayerSlot:get() then
			ForceDisconnect("Reconnected to wrong slot for this save file")
			return
		end
	end
	current_player_slot = ap:get_player_number()
	Globals.PlayerSlot:set(current_player_slot)
	Globals.RoomID:set(tostring(slot_options.room_uid or 0))

	GamePrint("$ap_connected_to_server")
	local connmsg = string.format("Connected to slot %s", ap:get_slot())
	ConnIcon:setConnected(connmsg)

	GameAddFlagRun("ap_connected_once")

	-- need these elsewhere
	if slot_options.victory_condition == 1 then
		GameAddFlagRun("ap_pure_goal")
	end
	if slot_options.victory_condition == 2 then
		GameAddFlagRun("ap_peaceful_goal")
	end
	if slot_options.shop_price ~= nil then
		GlobalsSetValue("ap_shop_price", tostring(slot_options.shop_price))
	end
	if slot_options.path_option == 4 then
		GameAddFlagRun("ap_parallel_worlds")
	end
	if slot_options.lock_portals ~= nil then
		GameAddFlagRun("ap_portals_locked")
	end

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
	if slot_options.hints ~= nil then
		SetupHints(slot_options.hints)
	end

	-- Enable deathlink if the setting on the server and the mod setting said to
	LinkManager:InitSettings(connect_tags)
	UpdateConnectionTags()

	local hints_key = "_read_hints_" .. ap:get_team_number() .. "_" .. ap:get_player_number()
	ap:SetNotify({hints_key})
	ap:Get({hints_key})
end

---@param location integer
local function PrintLocationCheckedIfNoText(location)
	if messages_setting ~= "none" then return end

	local msg = {
		{ text = "Checked " },
		{ type = "location_id", text = tostring(location), player = tostring(current_player_slot) },
	}
	local extra = {}

	RECV_MSG.PrintJSON(msg, extra)
end

---@param item NetworkItem
local function PrintItemReceiveMessageIfNoText(item)
	if messages_setting ~= "none" then return end

	local msg = {
		{ text = "Received " },
		{ type = "item_id", text = tostring(item.item), player = tostring(current_player_slot), flags = tostring(item.flags) },
		{ text = " from "},
		{ type = "player_id", text = tostring(item.player) },
		{ text = " (" },
		{ type = "location_id", text = tostring(item.location), player = tostring(item.player) },
		{ text = ")" },
	}
	local extra = {
		type = "ItemSend",
		receiving = current_player_slot,
		item = item,
	}

	RECV_MSG.PrintJSON(msg, extra)
end

-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#receiveditems
---@param items NetworkItem[]
function RECV_MSG.ReceivedItems(items)
	local is_first_time_connected = Cache.ItemDelivery:is_empty()
	for _, item in ipairs(items) do
		-- we're in sync or we're continuing the game and receiving items in async
		if not Cache.ItemDelivery:is_set(tostring(item.index)) then
			Cache.ItemDelivery:set(tostring(item.index), item)
			local item_id = item["item"]
			-- when connected for the first time, you get receiveditems along with connected
			-- but also, you want to give the player gold and stuff that got sent before spawning
			if not item_table[item_id] then
				Log.Error("[AP] spawn_item: Item id " .. tostring(item_id) .. " does not exist!")
			elseif is_first_time_connected and not item_table[item_id].newgame and item_table[item_id].redeliverable then
				SpawnReceivedItem(item)
			elseif not is_first_time_connected or GameHasFlagRun("ap_spawn_kill_saver") then
				SpawnReceivedItem(item)
			end
		end

		if not is_first_time_connected and GameHasFlagRun("ap_spawn_kill_saver") then
			PrintItemReceiveMessageIfNoText(item)
		end
	end

	if is_first_time_connected and not GameHasFlagRun("ap_spawn_kill_saver") then
		SpawnAllNewGameItems()
	end
end


local function ParseMessage(msg)
	local result = {}
	for _, token in ipairs(msg) do
		if token.type ~= nil then
			if token.type == "player_id" then
				local player_id = tonumber(token.text)
				if player_id ~= nil then
					local name = ap:get_player_alias(player_id)
					table.insert(result, name)
				end
			elseif token.type == "item_id" then
				local item_id = tonumber(token.text)
				local player_slot = tonumber(token.player)
				if item_id ~= nil and player_slot ~= nil then
					local game = ap:get_player_game(player_slot)
					local name = ap:get_item_name(item_id, game)
					table.insert(result, name)
				end
			elseif token.type == "location_id" then
				local location_id = tonumber(token.text)
				local player_slot = tonumber(token.player)
				if location_id ~= nil and player_slot ~= nil then
					local game = ap:get_player_game(player_slot)
					local name = ap:get_location_name(location_id, game)
					table.insert(result, name)
				end
			elseif token.text ~= nil then
				table.insert(result, token.text)
			end
		elseif token.text ~= nil then
			table.insert(result, token.text)
		end
	end
	return table.concat(result, "")
end

local recent_messages = {}
local function ShouldPrintMessage(msg_str)
	local current_time = GameGetRealWorldTimeSinceStarted()
	local last_time = recent_messages[msg_str] or -1
	if current_time - last_time < 1 then
		return false
	end

	recent_messages[msg_str] = current_time
	return true
end

-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#PrintJSON
---@param msg {[string]: any}
---@param extra {[string]: any}
function RECV_MSG.PrintJSON(msg, extra)
	local msg_str = ParseMessage(msg)

	if not ShouldPrintMessage(msg_str) then
		Log.Info(msg_str)
		return
	end

	local msg_type = extra["type"]
	if msg_type == "ItemSend" then
		local destination_player_id = extra["receiving"]
		local source_player_id = extra["item"]["player"]
		local item_id = extra["item"]["item"]

		local is_destination_player = destination_player_id == current_player_slot
		local is_source_player = source_player_id == current_player_slot

		if (is_destination_player or is_source_player) and destination_player_id ~= source_player_id then
			local destination_game = ap:get_player_game(destination_player_id)
			local item_name = ap:get_item_name(item_id, destination_game)
			GamePrintImportant(item_name, msg_str)
			return
		end

		if messages_setting ~= "all" and not is_destination_player and not is_source_player then
			return
		end
	elseif msg_type == "Countdown" then
		local countdown_number = extra["countdown"]
		if countdown_number == 0 then
			countdown_fun()
		end
	elseif msg_type == "Join" or msg_type == "Part" then
		if ModSettingGet("archipelago.join_leave_messages") == false then
			return
		end
	elseif msg_type == "Hint" then
		local is_destination_player = extra["receiving"] == current_player_slot
		local is_source_player = extra["item"]["player"] == current_player_slot

		if messages_setting ~= "all" and not is_destination_player and not is_source_player then
			return
		end
	end

	Log.Info(msg_str)
	GamePrint(msg_str)
	LogWindow:addLogMessage(msg)
end


-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#bounced
---@param msg {[string]: any}
function RECV_MSG.Bounced(msg)
	if not LinkManager:ProcessBounce(msg) then
		Log.Warn("Unsupported Bounced type received. " .. JSON:encode(msg))
	end
end


-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#LocationInfo
-- This is the reply to the LocationScouts request
---@param items NetworkItem[]
function RECV_MSG.LocationInfo(items)
	local cache = Cache.LocationInfo:reference()
	-- Set global shop item names to share with the shop lua context
	for _, net_item in ipairs(items) do
		local item_id = net_item.item

		cache[tostring(net_item.location)] = {
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


---@param data {[string]: any}
function RECV_MSG.SetReply(data)
	local hints_key = "_read_hints_" .. ap:get_team_number() .. "_" .. ap:get_player_number()
	for k, v in pairs(data) do
		if k == hints_key then
			LogWindow:setHints(v)

			for _, hint in ipairs(v) do
				if hint.finding_player == ap:get_player_number() then
					hint_location_received[hint.location] = true
				end
			end
		end
	end
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
local check_timer_1s = 0
local check_timer_10f = 0
local check_timer_20f = 0
local function CheckGlobalsAndFlags()
	if slot_options ~= nil then
		CheckVictoryConditionFlag()

		check_timer_10f = check_timer_10f + 1
		if check_timer_10f > 10 then
			check_timer_10f = 0
			CheckComponentItemsUnlocked()
			CheckLocationFlags()
			TrapLink:CheckTrapLinkQueue()
		end

		check_timer_20f = check_timer_20f + 1
		if check_timer_20f > 20 then
			check_timer_20f = 0
			DamageLink:CheckDamageLinkQueue()
			KnockbackLink:CheckKnockbackLinkQueue()
		end

		check_timer_1s = check_timer_1s + 1
		if check_timer_1s > 60 then
			check_timer_1s = 0
			CheckShopScouted()
			CheckRedeliveryQueue()
		end
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
	local slot_name = tostring(ModSettingGet("archipelago.slot_name"))
	local password = tostring(ModSettingGet("archipelago.passwd") or "")

	local function on_socket_connected()
		Log.Info("Socket connected")
	end

	---@param reason string
	local function on_socket_error(reason)
		if reason:find("actively refused") then
			-- Don't keep reconnecting if there's no chance it will work
			ForceDisconnect(reason)
		else
			ConnectionError(reason)
		end
	end

	local function on_socket_disconnected()
		ConnectionError("Socket disconnected")
	end

	local function on_room_info()
		Log.Info("on_room_info")

		if GameHasFlagRun("ap_connected_once") then
			if ap:get_seed() ~= Globals.Seed:get() then
				ForceDisconnect("Reconnected to wrong room for this save file")
				return
			end
		end

		Globals.Seed:set(ap:get_seed())

		if messages_setting == "none" then
			connect_tags["NoText"] = 1
		end

		local connection_tags = GetConnectionTags()
		prev_connect_tags_str = table.concat(connection_tags, ",")
		ap:ConnectSlot(slot_name, password, ITEMS_HANDLING, connection_tags, { 0, 6, 2 })
	end

	---@param slot_data {[string]: any}
	local function on_slot_connected(slot_data)
		Log.Info("on_slot_connected: " .. JSON:encode(slot_data))
		SetSlotOptions(slot_data)
		RECV_MSG.Connected()
	end

	---@param reasons string[]
	local function on_slot_refused(reasons)
		ForceDisconnect("Slot refused: " .. table.concat(reasons, ", "))
	end

	---@param items NetworkItem[]
	local function on_items_received(items)
		Log.Info("on_items_received: " .. JSON:encode(items))
		RECV_MSG.ReceivedItems(items)
	end

	---@param items NetworkItem[]
	local function on_location_info(items)
		Log.Info("on_location_info: " .. JSON:encode(items))
		RECV_MSG.LocationInfo(items)
	end

	---@param locations integer[]
	local function on_location_checked(locations)
		Log.Info("on_location_checked: " .. JSON:encode(locations))
		for _, location_id in pairs(locations) do
			remove_collected_item(location_id)
			if GameHasFlagRun("ap_spawn_kill_saver") then
				PrintLocationCheckedIfNoText(location_id)
			end
		end
	end

	---@param data {[string]: any}
	---@param command {[string]: any}
	local function on_print_json(data, command)
		RECV_MSG.PrintJSON(data, command)
	end

	---@param command {[string]: any}
	local function on_bounced(command)
		Log.Info("on_bounced: " .. JSON:encode(command))
		RECV_MSG.Bounced(command)
	end

	---@param data {[string]: any}
	---@param keys string[]
	---@param command {[string]: any}
	local function on_set_retrieved(data, keys, command)
		RECV_MSG.SetReply(data)
	end

	---@param command {[string]:any}
	local function on_set_reply(command)
		RECV_MSG.SetReply({ [command.key] = command.value })
	end

	hostname = tostring(host) .. ":" .. tostring(port)
	Log.Warn("Connecting on " .. hostname)
	ap = APLIB(uuid, GAME_NAME, hostname)
	LogWindow:SetAP(ap)

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
	ap:set_retrieved_handler(on_set_retrieved)
	ap:set_set_reply_handler(on_set_reply)
end

local function UpdateUI()
	ConnIcon:update()
	if ConnIcon:pressed() then
		LogWindow:toggle()
	end
	LogWindow:update()

	if (forced_disconnect or slot_options == nil) and req_restart then
		GuiStartFrame(gui)
		GuiColorSetForNextWidget(gui, 1, 0, 0, 1)
		GuiLayoutBeginVertical(gui, 1, 1)
		GuiText(gui, 0, 0, "Mod restart required for updated settings to take effect")
		GuiLayoutEnd(gui)
	end
end

----------------------------------------------------------------------------------------------------
-- NOITA CALLBACKS
----------------------------------------------------------------------------------------------------

local slow_position_update_timer = 0
local old_x = 0
local old_y = 0
local function UpdatePlayerPoptrackerPosition()
	local player = get_player()
	if not player or player == 0 then return end

	slow_position_update_timer = slow_position_update_timer + 1
	if slow_position_update_timer < 60 * 10 then return end	-- 10 seconds

	-- Use x/y chunk to reduce traffic
	local x, y = EntityGetTransform(player)
	x = math.floor(x / 512)
	y = math.floor(y / 512)

	if x ~= old_x or y ~= old_y then
		slow_position_update_timer = 0	-- only reset the timer if we're sending a packet
		old_x = x
		old_y = y

		local key = "Noita_position_" .. current_player_slot
		local pos = { x = x, y = y }
		ap:Set(key, pos, false, { {operation = "replace", value = pos} })
	end
end

--- Prints extra information to help debug with other mods
local function PrintActiveModInfo()
	Log.Warn("Noita Mod API Ver " .. tostring(ModGetAPIVersion()))

	local modlist = Modlist.GetDetailList()
	local modlist_str = "Active mods:\n    - " .. table.concat(modlist, "\n    - ")
	Log.Warn(modlist_str)

	if StreamingGetIsConnected() then
		Log.Warn("Streaming enabled")
	end
end

local HIDDEN_FIELDS = {"password", "passwd", "pwd", "server", "account", "acct"}
local function IsHiddenEntry(name)
	for _, hidden in ipairs(HIDDEN_FIELDS) do
		if name:find(hidden, 1, true) then return true end
	end
	return false
end

local function GetPrintableSettingStr(name, value, value_next)
	local value_str = tostring(value)
	local value_next_str = tostring(value_next)

	if IsHiddenEntry(name) then
		value_str = "<HIDDEN>"
		value_next_str = "<HIDDEN>"
	end

	if value_str == value_next_str then
		return string.format("    %s = %s\n", name, value_str)
	end
	return string.format("    %s = %s -> %s\n", name, value_str, value_next_str)
end

local last_settings = ""
local function PrintActiveSettings()
	local settings_str = "[SETTINGS]\n"

	local modids = Modlist.GetIDs()
	local activemods = {}
	for _, modid in ipairs(modids) do
		activemods[modid:lower()] = true
	end

	local num_settings = ModSettingGetCount()
	for i = 0, num_settings - 1 do
		local name, value, value_next = ModSettingGetAtIndex(i)

		local strend = name:find(".", 1, true)
		if strend == nil then goto continue end

		local setting_modid = name:sub(1, strend - 1)
		if not activemods[setting_modid:lower()] then goto continue end

		settings_str = settings_str .. GetPrintableSettingStr(name, value, value_next)
		::continue::
	end

	if settings_str ~= last_settings then
		Log.Info(settings_str)
		last_settings = settings_str
	end
end

-- Called every update frame in Noita
-- https://noita.wiki.gg/wiki/Modding:_Lua_API#OnWorldPostUpdate
function OnWorldPostUpdate()
	UpdateUI()

	if is_player_spawned and not forced_disconnect then
		ap:poll()
		CheckGlobalsAndFlags()
		UpdatePlayerPoptrackerPosition()
	end
	--TrapMenu:update()
end


-- Called when the game is paused or unpaused
-- https://noita.wiki.gg/wiki/Modding:_Lua_API#OnPausedChanged
function OnPausedChanged(is_paused, is_inventory_pause)
	-- Workaround: When the player creates a new game, OnPlayerDied gets called (triggers DeathLink).
	-- However we know they have to pause the game (menu) to start a new game.
	game_is_paused = is_paused and not is_inventory_pause

	LinkManager:SyncSettings(connect_tags)

	-- Disable/enable text messages if settings change
	messages_setting = tostring(ModSettingGet("archipelago.messages") or "all")
	if messages_setting == "none" and not connect_tags["NoText"] then
		Log.Info("Disabling text")
		connect_tags["NoText"] = 1
	elseif messages_setting ~= "none" and connect_tags["NoText"] then
		Log.Info("Enabling text")
		connect_tags["NoText"] = nil
	end

	UpdateConnectionTags()
	LogWindow:close()

	local newhostname = ModSettingGetNextValue("archipelago.server_address") .. ":" .. ModSettingGetNextValue("archipelago.server_port")
	if hostname ~= newhostname then
		req_restart = true
	end

	PrintActiveSettings()
end

-- Called while the game is paused
function OnPausePreUpdate()
	PauseMenu:update(MOD_VERSION, slot_options, LinkManager:GetAllOptions())
	UpdateUI()

	-- Stay connected while the game is paused
	if is_player_spawned and not forced_disconnect then
		ap:poll()
	end
end

-- Called when the player dies
-- https://noita.wiki.gg/wiki/Modding:_Lua_API#OnPlayerDied
function OnPlayerDied(player)
	if game_is_paused then return end
	DeathLink:OnPlayerDied()
end

-- Called at the earliest possible time
-- https://noita.wiki.gg/wiki/Modding:_Lua_API#OnModInit
function OnModInit()
	if BadPath() ~= nil then
		Log.Error([[Unexpected mod location detected! Some things may break!
		  Expected: mods/archipelago/
		  Got: ]] .. BadPath())
	end

	GameRemoveFlagRun("AP_LocationInfo_received")
	create_dir("archipelago_cache")
	messages_setting = tostring(ModSettingGet("archipelago.messages") or "all")
	ConnIcon:create()
	connect()
end

local world_state_initialized = false
function OnWorldPreUpdate()
	if not world_state_initialized then
		LogWindow:create()
		InitStreamingTraps()
		PrintActiveModInfo()
		PrintActiveSettings()
		world_state_initialized = true
	end
end

function OnPlayerSpawned(player_entity)
	is_player_spawned = true
	GlobalsSetValue("ap_random_hax", "23")

	if not EntityGetFirstComponent(player_entity, "LuaComponent", "ap_damagelink") then
		EntityAddComponent2(player_entity, "LuaComponent", {
			_tags = "ap_damagelink",
			script_damage_received = "data/archipelago/scripts/damagelink_script.lua"
		})
	end
end
