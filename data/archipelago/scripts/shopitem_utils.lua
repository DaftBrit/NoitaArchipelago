dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/perks/perk.lua")

local AP = dofile("data/archipelago/scripts/constants.lua")
local Globals = dofile("data/archipelago/scripts/globals.lua")
local JSON = dofile("data/archipelago/lib/json.lua")
local Log = dofile("data/archipelago/scripts/logger.lua")
local item_table = dofile("data/archipelago/scripts/item_mappings.lua")


local ShopItems = {}


local function encodeXML(str)
	return str:gsub("\"", "&quot;")
end


-- Uses vanilla wand price calculation, copied from the actual shop code.
-- cheap_item is true if it's an on-sale item
-- If the biomeid is 0, the item is free
function ShopItems.generate_item_price(biomeid, cheap_item)
	if biomeid == 0 then return 0 end

	biomeid = (0.5 * biomeid) + ( 0.5 * biomeid * biomeid )
	local price = (50 + biomeid * 210) + (Random(-15, 15) * 10)

	if( cheap_item ) then
		price = 0.5 * price
	end
	return math.floor(price)
end -- generate_item_price


-- Spawn in an item or perk entity for the shop
function ShopItems.create_our_item_entity(item, x, y)
	if item.perk ~= nil then
		return perk_spawn(x, y, item.perk, true)
	elseif item.items ~= nil and #item.items > 0 then
		-- our item is something else (random choice)
		local entity_id = EntityLoad(item.items[Random(1, #item.items)], x, y)
		if item.gold_amount ~= 0 then
				local life_comp = EntityGetFirstComponent(entity_id, "LifetimeComponent", "enabled_in_world")
				EntityRemoveComponent(entity_id, life_comp)
		end
		return entity_id
	else -- error?
		-- TODO
		EntityLoad("data/archipelago/entities/items/ap_error_book.xml", x, y)
		Log.Error("Failed to load our own shopitem!")
	end
end


-- Basically chooses the item graphic depending on the generated item's flags
function ShopItems.create_ap_entity_from_flags(location, x, y)
	local flags = location.item_flags

	local item_filename = "ap_junk_shopitem.xml"
	local item_description = "$ap_shopdescription_junk"
	if bit.band(flags, AP.ITEM_FLAG_USEFUL) ~= 0 then
		item_filename = "ap_useful_shopitem.xml"
		item_description = "$ap_shopdescription_useful"
	elseif bit.band(flags, AP.ITEM_FLAG_PROGRESSION) ~= 0 then
		item_filename = "ap_progression_shopitem.xml"
		item_description = "$ap_shopdescription_progression"
	elseif bit.band(flags, AP.ITEM_FLAG_TRAP) ~= 0 then
		item_filename = "ap_trap_item.xml"
		item_description = "$ap_shopdescription_trap" .. tostring(Random(1, 8))
	end

	local item_entity = EntityLoad("data/archipelago/entities/items/" .. item_filename, x, y)
	if bit.band(flags, AP.ITEM_FLAG_TRAP) ~= 0 and location.is_our_item then
			 EntityAddComponent(item_entity, "LuaComponent", {
					 _tags="archipelago",
					 script_item_picked_up="data/archipelago/scripts/items/ap_trap.lua",
					 })
	end
	return item_entity, item_description
end


-- Spawns in an AP item (our own entity to represent items that don't exist in this game)
function ShopItems.create_foreign_item_entity(location, x, y)
	local entity_id, description = ShopItems.create_ap_entity_from_flags(location, x, y)
	local name = location.item_name

	-- Change item name
	change_entity_ingame_name(entity_id, name, description)
	return entity_id
end


-- Generates an items and creates the entity used to make the shop item
function ShopItems.generate_ap_shop_item_entity(location_id, x, y)
	local location = Globals.LocationScouts:get_key(location_id)
	if location == nil then
		Log.Error("Failed to retrieve shopitem info from cache")
	end

	local item_id = location.item_id
	local item = item_table[item_id]

	if location.is_our_item and item and item_id ~= AP.TRAP_ID then
		return ShopItems.create_our_item_entity(item, x, y), false
	else
		return ShopItems.create_foreign_item_entity(location, x, y), true
	end
end -- generate_ap_shop_item_entity


-- The majority of this function is taken from scripts/items/generate_shop_item.lua
-- Used to create the shop item and attach components to make it interactable, and have unique descriptions etc.
-- biomeid of 0 means the shop item is free
function ShopItems.generate_ap_shop_item(location_id, biomeid, x, y, cheap_item)
	cheap_item = cheap_item or false

	local price = ShopItems.generate_item_price(biomeid, cheap_item)
	local entity_id, is_foreign_item = ShopItems.generate_ap_shop_item_entity(location_id, x, y)

	-- We add a custom component to store the id that we are unlocking when the item is purchased,
	-- as well as some other things
	EntityAddComponent(entity_id, "VariableStorageComponent", {
		_tags="archipelago,enabled_in_world",
		name="ap_shop_data",
		value_string=encodeXML(JSON:encode({
			location_id = location_id,
			price = price,
			sale = cheap_item,
			is_ap_item = is_foreign_item,
		}))
	})

	EntityAddComponent(entity_id, "LuaComponent", {
		_tags="archipelago",
		script_source_file="data/archipelago/scripts/shopitem_processed.lua",
		execute_on_added="1",
		execute_every_n_frame="-1",
		call_init_function="1",
		script_item_picked_up="data/archipelago/scripts/shopitem_processed.lua",
	})
end -- generate_ap_shop_item

return ShopItems
