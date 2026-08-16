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
dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/lib/mod_settings.lua")
dofile_once("data/archipelago/scripts/item_utils.lua")

local item_table = dofile("data/archipelago/scripts/item_mappings.lua")
local AP = dofile("data/archipelago/scripts/constants.lua")
local Biomes = dofile("data/archipelago/scripts/ap_biome_mapping.lua")
local ShopItems = dofile("data/archipelago/scripts/shopitem_utils.lua")

-- Modules
local Globals = dofile("data/archipelago/scripts/globals.lua") --- @type Globals
local Cache = dofile("data/archipelago/scripts/caches.lua")
local ConnIcon = dofile("data/archipelago/ui/connection_icon.lua") --- @type ConnIcon
local LogWindow = dofile("data/archipelago/ui/log_window.lua") --- @type LogWindow
local PauseMenu = dofile("data/archipelago/ui/pause_menu.lua") --- @type PauseMenu
--local TrapMenu = dofile("data/archipelago/ui/trap_menu.lua") --- @type TrapMenu
local Modlist = dofile("data/archipelago/lib/modlist.lua") --- @type Modlist

-- See Options.py on the AP-side
-- Can also use to indicate whether AP sent the connected packet

---@class SlotOpts
---@field victory_condition integer?
---@field death_link integer?
---@field trap_link integer?
---@field damage_link integer?
---@field path_option integer?
---@field orbs_as_checks integer?
---@field shop_price number?
---@field lock_portals integer?

---@type SlotOpts?
local slot_options = nil

local prev_connect_tags_str = ""
local connect_tags = {
	["Lua-APClientPP"] = 1
}

local last_death_time = 0
local current_player_slot = -1
local game_is_paused = false
local is_player_spawned = false
local messages_setting = "all"
local forced_disconnect = false
local req_restart = false
local hostname = ""

local function generateFakeUUID()
	local year, month, day, hour, minute, second = GameGetDateAndTimeUTC()
	local rng = year * 100000 + month * 10000 + day * 1000 + hour * 100 + minute * 10 + second
	math.randomseed(rng)
    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    return template:gsub("[xy]", function(c)
        local r = math.random(0, 15)
        if c == "y" then r = (r % 4) + 8 end
        return string.format("%x", r)
    end)
end
local uuid = generateFakeUUID()

local ap = nil --- @type APClient
local gui = GuiCreate()

----------------------------------------------------------------------------------------------------
-- DEATHLINK
----------------------------------------------------------------------------------------------------

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

-- Updates a death timer to prevent immediate re-sends of deaths that have been received.
local function UpdateDeathTime()
	local curr_death_time = ap:get_server_time()
	local result = curr_death_time - last_death_time > 1
	last_death_time = curr_death_time
	return result
end

local function GetDeathLink()
	local opt = Cache.Options:get("death_link", "yaml")
	if opt == "yaml" then
		if slot_options.death_link == 1 then
			opt = "on"
		elseif slot_options.death_link == 2 then
			opt = "traps"
		else
			opt = "off"
		end
	end
	return opt
end

local function GetTrapLink()
	local opt = Cache.Options:get("trap_link", "yaml")
	if opt == "yaml" then
		if slot_options.trap_link == 1 then
			opt = "on"
		else
			opt = "off"
		end
	end
	return opt
end

local function GetDamageLink()
	local opt = Cache.Options:get("damage_link", "yaml")
	if opt == "yaml" then
		if slot_options.damage_link == 1 then
			opt = "on"
		else
			opt = "off"
		end
	end
	return opt
end

---Updates the connect tags based on whether a link is enabled.
---@param setting_name string
---@param tag_name string
local function SyncLinkSetting(setting_name, tag_name)
	local opt = Cache.Options:get(setting_name, "yaml")

	local enabled = false
	if opt == "yaml" then
		enabled = (slot_options[setting_name] or 0) ~= 0
	elseif opt ~= "off" then
		enabled = true
	end

	if enabled then
		connect_tags[tag_name] = 1
	else
		connect_tags[tag_name] = nil
	end
end

--- Updates DeathLink, requires calling UpdateConnectionTags() separately afterwards
local function SyncDeathLink()
	SyncLinkSetting("death_link", "DeathLink")
end

--- Updates TrapLink, requires calling UpdateConnectionTags() separately afterwards
local function SyncTrapLink()
	SyncLinkSetting("trap_link", "TrapLink")
end

--- Updates DamageLink, requires calling UpdateConnectionTags() separately afterwards
local function SyncDamageLink()
	SyncLinkSetting("damage_link", "SharedDamage")
end

local function UpdateLocalSettings()
	Cache.Options:set("death_link", Globals.DeathLinkSetting:get())
	if Globals.DeathLinkSetting:hasChanged() then
		Globals.DeathLinkSetting:clearChanged()
		SyncDeathLink()
	end

	Cache.Options:set("trap_link", Globals.TrapLinkSetting:get())
	if Globals.TrapLinkSetting:hasChanged() then
		Globals.TrapLinkSetting:clearChanged()
		SyncTrapLink()
	end

	Cache.Options:set("damage_link", Globals.DamageLinkSetting:get())
	if Globals.DamageLinkSetting:hasChanged() then
		Globals.DamageLinkSetting:clearChanged()
		SyncDamageLink()
	end
end

local function InitLocalSettings()
	Globals.DeathLinkSetting:set(Cache.Options:get("death_link", "yaml"))
	Globals.TrapLinkSetting:set(Cache.Options:get("trap_link", "yaml"))
	Globals.DamageLinkSetting:set(Cache.Options:get("damage_link", "yaml"))
	UpdateLocalSettings()
end

local function CheckTrapLinkQueue()
	local traps = Globals.TrapLinkQueue:get_table()
	for _,trap in ipairs(traps) do
		local pkt = {
			time = ap:get_server_time(),
			trap_name = trap.trap_name,
			source = ap:get_slot(),
			noita_id = trap.noita_id,
		}
		Log.Info("Sending TrapLink: " .. JSON:encode(pkt))
		ap:Bounce(pkt, nil, nil, {"TrapLink"})
	end
	Globals.TrapLinkQueue:reset()
end

local damage_saved = 0
local function CheckDamageLinkQueue()
	if GetDamageLink() ~= "off" then
		local damagequeue = Globals.DamageLinkQueue:get_table()
		for _,amount in ipairs(damagequeue) do
			damage_saved = damage_saved + amount
		end

		if damage_saved > 1 then
			local pkt = {
				time = ap:get_server_time(),
				uuid = uuid,
				source = ap:get_slot(),
				damage_points = math.floor(damage_saved),
			}
			Log.Info("Sending DamageLink: " .. JSON:encode(pkt))
			ap:Bounce(pkt, nil, nil, {"SharedDamage"})

			damage_saved = damage_saved - math.floor(damage_saved)
		end
	end
	Globals.DamageLinkQueue:reset()
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

local function AlreadyHinted(location_id)
	return Globals.ShopScouted:has_key(location_id)
end

-- TODO handle case where you send but lose connection and can't hint again
-- Maybe just remove the cache and always send on a per-game basis
local function CheckShopScouted()
	local hint_queue = Globals.ShopScoutedQueue:get_table()
	if #hint_queue > 0 then
		for _, hint in ipairs(hint_queue) do
			if AlreadyHinted(hint) then goto continue end

			local shop_locations = ShopItems.get_related_shop_locations(hint)

			local hints_sent = Globals.ShopScouted:get_table()
			for _, location in ipairs(shop_locations) do
				hints_sent[tostring(location)] = true
			end

			Log.Info("Sending request to reveal hints: \n" .. JSON:encode(shop_locations))

			-- create_as_hint = 2  reveals the hint and prevents re-notifications
			ap:LocationScouts(shop_locations, 2)
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
	slot_options = nil
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
	-- Enable deathlink if the setting on the server and the mod setting said to
	InitLocalSettings()
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


---@param source string?
---@param cause string?
local function RecvDeathLink(source, cause)
	local death_link_option = GetDeathLink()
	if death_link_option == "off" then
		Log.Info("Rejecting DeathLink: death_link_option = " .. tostring(death_link_option))
		return
	end

	local last_time = last_death_time
	if not UpdateDeathTime() then
		Log.Info("Rejecting DeathLink: too soon, last = " .. tostring(last_time) .. ", curr = " .. tostring(last_death_time))
		return
	end

	if cause == nil or cause == "" then
		local message = GameTextGet(death_link_option == "on" and "$ap_died" or "$ap_died_traps", tostring(source))
		GamePrintImportant(message, "$ap_deathlink_triggered")
	else
		GamePrintImportant(cause, "$ap_deathlink_triggered")
	end

	local player = get_player()
	-- Don't try anything if the player doesn't exist (gj you dodged it)
	if player == nil then return end

	if death_link_option == "on" then
		if not DecreaseExtraLife(player) then
			local gsc_id = EntityGetFirstComponentIncludingDisabled(player, "GameStatsComponent")
			if gsc_id ~= nil then
				ComponentSetValue2(gsc_id, "extra_death_msg", cause)
			end
			EntityKill(player)
			Log.Info("DeathLink: get fked")
		else
			Log.Info("DeathLink: extra life saved you")
		end
	else
		Log.Info("DeathLink: picking a trap...")
		BadTimes(true)
	end
end

---@param source string
---@param amount integer
local function RecvDamageLink(source, amount)
	local msg = GameTextGet("$ap_damagelink_received", tostring(amount), source)
	GamePrint(msg)

	local player = get_player()
	if player == nil then return end

	EntityInflictDamage(player, amount / MagicNumbersGetValue("GUI_HP_MULTIPLIER"), "DAMAGE_CURSE", "DamageLink - " .. msg, "NONE", 0, 0)
end

-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#bounced
---@param msg {[string]: any}
function RECV_MSG.Bounced(msg)
	local has_tag = {}
	for _,tag in ipairs(msg["tags"]) do
		has_tag[tag] = true
	end
	local data = msg["data"]

	if has_tag["DeathLink"] then
		RecvDeathLink(data["source"], data["cause"])
	elseif has_tag["TrapLink"] then
		-- Don't receive traps from the same slot since they get shared through receiving items
		if data["source"] ~= ap:get_slot() then
			RecvTrapLink(data["source"], data["trap_name"], data["noita_id"])
		end
	elseif has_tag["SharedDamage"] then	-- DamageLink
		-- Don't receive damage from the same slot
		if data["uuid"] ~= nil then
			if data["uuid"] == uuid then
				return
			end
		elseif data["source"] == ap:get_slot() then
			return
		end
		RecvDamageLink(data["source"], data["damage_points"])
	else
		Log.Warn("Unsupported Bounced type received. " .. JSON:encode(msg))
	end
end


-- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#LocationInfo
-- This is the reply to the LocationScouts request
---@param items NetworkItem[]
function RECV_MSG.LocationInfo(items)
	if not Cache.LocationInfo:is_empty() and #items <= 10 then
		-- Don't replace our big item cache with shop hints (which breaks everything).
		-- Just assume the second call with small item count was a hint and mark it as such.
		return
	end

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


---@param data {[string]: any}
function RECV_MSG.SetReply(data)
	local hints_key = "_read_hints_" .. ap:get_team_number() .. "_" .. ap:get_player_number()
	for k, v in pairs(data) do
		if k == hints_key then
			LogWindow:setHints(v)
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
			CheckTrapLinkQueue()
		end

		check_timer_20f = check_timer_20f + 1
		if check_timer_20f > 20 then
			check_timer_20f = 0
			CheckDamageLinkQueue()
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
		slot_options = slot_data
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

	UpdateLocalSettings()

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
	if slot_options ~= nil then
		PauseMenu:update(MOD_VERSION, slot_options, GetDeathLink(), GetTrapLink(), GetDamageLink())
	else
		PauseMenu:update(MOD_VERSION, slot_options, "", "", "")
	end
	UpdateUI()

	-- Stay connected while the game is paused
	if is_player_spawned and not forced_disconnect then
		ap:poll()
	end
end

-- Called when the player dies
-- https://noita.wiki.gg/wiki/Modding:_Lua_API#OnPlayerDied
function OnPlayerDied(player)
	if slot_options == nil or GetDeathLink() == "off" or game_is_paused then return end
	if not UpdateDeathTime() then return end

	local death_msg = GetCauseOfDeath() or "skill issue"
	local slotname = ap:get_slot()
	Log.Info("Deathlink triggered - player died (" .. death_msg .. ")")
	ap:Bounce({
		time = last_death_time,
		cause = slotname .. " died to " .. death_msg,
		source = slotname
	}, nil, nil, {"DeathLink"})
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

	EntityAddComponent2(player_entity, "LuaComponent", {
		script_damage_received = "data/archipelago/scripts/damagelink_script.lua"
	})
end
