dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/perks/perk.lua")

local AP = dofile("data/archipelago/scripts/constants.lua")
local Globals = dofile("data/archipelago/scripts/globals.lua") --- @type Globals
local JSON = dofile("data/archipelago/lib/json.lua")
local Log = dofile("data/archipelago/scripts/logger.lua") ---@type Logger
local item_table = dofile("data/archipelago/scripts/item_mappings.lua")


local ShopItems = {}


local function encodeXML(str)
	return str:gsub("\"", "&quot;")
end

local function decodeXML(str)
	return str:gsub("&quot;", "\"")
end

local function rangeTable(first, amt)
	local result = {}
	for i = first, first + amt - 1 do
		table.insert(result, i)
	end
	return result
end

-- Parallel world offsets
local function getPWLocationOffset(pw_num)
	if not pw_num then pw_num = 0 end
	if pw_num < 0 then
		return AP.WEST_OFFSET
	elseif pw_num > 0 then
		return AP.EAST_OFFSET
	end
	return 0
end

-- Uses vanilla wand price calculation, copied from the actual shop code.
-- cheap_item is true if it's an on-sale item
-- If the biomeid is 0, the item is free
function ShopItems.generate_item_price(biomeid, cheap_item)
	if biomeid == 0 then return 0 end

	-- second term is the default value, to be taken if no value is received, for compatibility
	local price_multiplier = tonumber(GlobalsGetValue("ap_shop_price", "100"))/100

	biomeid = (0.5 * biomeid) + ( 0.5 * biomeid * biomeid )
	local price = (50 + biomeid * 210) + (Random(-15, 15) * 10)

	if( cheap_item ) then
		price = 0.5 * price
	end
	price = price * price_multiplier

	return math.floor(price)
end -- generate_item_price


--- Spawn in an item or perk entity for the shop
---@param item table
---@param x integer
---@param y integer
---@return entity_id|nil
function ShopItems.create_our_item_entity(item, x, y)
	print("shop item create entity start")
	if item.perk ~= nil then
		local perk_id = perk_spawn(x, y, item.perk, true)
		if perk_id ~= nil then
			EntityRemoveTag(perk_id, "perk")
			EntityAddTag(perk_id, "ap_item")
		end
		return perk_id
	elseif item.items ~= nil and #item.items > 0 then
		-- our item is something else (random choice)
		local entity_id = EntityLoad(item.items[Random(1, #item.items)], x, y)
		EntityAddTag(entity_id, "ap_item")
		local life_comp = EntityGetFirstComponent(entity_id, "LifetimeComponent", "enabled_in_world")
		if life_comp ~= nil then
			EntityRemoveComponent(entity_id, life_comp)
		end
		if item.orb ~= 0 then
			local orb_count = GameGetOrbCountThisRun()
			print("orb count is " .. orb_count)
			if GameHasFlagRun("ap_pure_goal") then
				print("ap pure goal is true")
			end
			if GameHasFlagRun("ap_peaceful_goal") and orb_count >= 33 or GameHasFlagRun("ap_pure_goal") and orb_count >= 11 then
				local orbcomp = EntityGetFirstComponent(entity_id, "OrbComponent")
				if orbcomp ~= nil then
					EntityRemoveComponent(entity_id, orbcomp)
				end
			end
		end
		return entity_id
	elseif item.spells ~= nil then
		local item_to_spawn = item.spells[Random(1, #item.spells)]
		local entity_id = CreateItemActionEntity(item_to_spawn, x, y)
		EntityAddTag(entity_id, "ap_item")
		return entity_id
	else -- error?
		-- TODO
		EntityLoad("data/archipelago/entities/items/pickup/ap_error_book.xml", x, y)
		Log.Error("Failed to load our own shopitem!")
		return nil
	end
end


-- Spawns in an AP item (our own entity to represent items that don't exist in this game)
function ShopItems.create_foreign_item_entity(location, x, y)
	local entity_id, description = create_ap_entity_from_flags(location, x, y)
	local name = location.item_name

	-- Change item name
	change_entity_ingame_name(entity_id, name, description)
	return entity_id
end


-- Generates an item and creates the entity used to make the shop item
function ShopItems.generate_ap_shop_item_entity(location_id, x, y)
	local location = Globals.LocationScouts:get_key(location_id)
	if location == nil then
		Log.Error("Failed to retrieve shopitem info from cache")
	end

	local item_id = location.item_id
	local item = item_table[item_id]

	if location.is_our_item and item and item_id ~= AP.TRAP_ID then
		local shop_item_id = ShopItems.create_our_item_entity(item, x, y)
		addNewInternalVariable(shop_item_id, "ap_location_id", "value_int", location_id)
		return shop_item_id, false
	else
		local shop_item_id = ShopItems.create_foreign_item_entity(location, x, y)
		addNewInternalVariable(shop_item_id, "ap_location_id", "value_int", location_id)
		return shop_item_id, true
	end
end -- generate_ap_shop_item_entity


-- The majority of this function is taken from scripts/items/generate_shop_item.lua
-- Used to create the shop item and attach components to make it interactable, and have unique descriptions etc.
-- biomeid of 0 means the shop item is free
function ShopItems.generate_ap_shop_item(location_id, biomeid, x, y, cheap_item)
	cheap_item = cheap_item or false

	local price = ShopItems.generate_item_price(biomeid, cheap_item)
	local entity_id, is_foreign_item = ShopItems.generate_ap_shop_item_entity(location_id, x, y)

	if entity_id == nil or entity_id == 0 then
		error("Failed to create shop item at location: " .. tostring(location_id))
	end

	-- We add a custom component to store the id that we are unlocking when the item is purchased,
	-- as well as some other things
	EntityAddComponent2(entity_id, "VariableStorageComponent", {
		_tags="archipelago,enabled_in_world",
		name="ap_shop_data",
		value_string=encodeXML(JSON:encode({
			location_id = location_id,
			price = price,
			sale = cheap_item,
			is_ap_item = is_foreign_item,
		}))
	})

	EntityAddComponent2(entity_id, "LuaComponent", {
		_tags="archipelago,enabled_in_world",
		script_source_file="data/archipelago/scripts/shopitem_processed.lua",
		execute_on_added=true,
		execute_every_n_frame=-1,
		call_init_function=true,
		script_item_picked_up="data/archipelago/scripts/shopitem_processed.lua",
		script_collision_trigger_hit="data/archipelago/scripts/shopitem_scouted.lua",
	})

	EntityAddComponent2(entity_id, "CollisionTriggerComponent", {
		required_tag="player_unit",
		remove_component_when_triggered=true,
		destroy_this_entity_when_triggered=false,
	})
end -- generate_ap_shop_item

function ShopItems.get_related_shop_locations(location_id)
	location_id = tonumber(location_id)
	-- Holy Mountain shops
	for parallel_world = -1, 1 do
		for shop_id = 1, 7 do
			local base_id = AP.FIRST_SHOP_LOCATION_ID + (shop_id - 1) * 6 + getPWLocationOffset(parallel_world)
			if base_id <= location_id and location_id < base_id + 5 then
				return rangeTable(base_id, 5)
			end
		end
	end

	if AP.FIRST_SECRET_SHOP_LOCATION_ID <= location_id and location_id <= AP.LAST_SECRET_SHOP_LOCATION_ID then
		return rangeTable(AP.FIRST_SECRET_SHOP_LOCATION_ID, 4)
	end

	return {}
end

function ShopItems.get_ap_item_from_entity(entity_id)
	local component = get_variable_storage_component(entity_id, "ap_shop_data")
	assert(component and component ~= 0, "unable to retrieve ap_shop_data")
	local data_str = ComponentGetValue2(component, "value_string")
	return JSON:decode(decodeXML(data_str)), data_str
end

return ShopItems
