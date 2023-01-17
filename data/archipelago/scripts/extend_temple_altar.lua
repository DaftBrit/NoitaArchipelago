dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/perks/perk.lua")
dofile_once("data/archipelago/scripts/item_utils.lua")

local function ap_extend_temple_altar()
	local JSON = dofile("data/archipelago/lib/json.lua")
	local item_table = dofile("data/archipelago/scripts/item_mappings.lua")
	local AP = dofile("data/archipelago/scripts/constants.lua")
	local Globals = dofile("data/archipelago/scripts/globals.lua")

	local remaining_ap_items = 0
	local total_remaining_items = 0
	local num_ap_items = 0

	-- Retrieves the shop index based on the y coordinate (depth) to determine which holy mountain it is
	local function get_shop_num(y)
		if y < 1500 then return 1 -- Mines
		elseif y < 3000 then return 2 -- Coal Pits
		elseif y < 5500 then return 3 -- Snowy Depths
		elseif y < 7000 then return 4 -- Hiisi Base
		elseif y < 9500 then return 5 -- Underground Jungle
		elseif y < 11500 then return 6 -- The Vault
		else return 7 -- Temple of the Art
		end
	end

	-- Gets the location id for the shop based on the y coordinate and number of AP items already placed (assuming max 5)
	-- TODO: Use x for parallel worlds in the future
	local function get_shop_location_id(x, y)
		return AP.FIRST_SHOPITEM_LOCATION_ID + (get_shop_num(y)-1) * 5 + num_ap_items
	end

	-- Uses vanilla wand price calculation, copied from the actual shop code.
	-- cheap_item is true if it's an on-sale item
	local function generate_item_price(biomeid, cheap_item)
		biomeid = (0.5 * biomeid) + ( 0.5 * biomeid * biomeid )
		local price = (50 + biomeid * 210) + (Random(-15, 15) * 10)

		if( cheap_item ) then
			price = 0.5 * price
		end
		return math.floor(price)
	end -- generate_item_price

	-- todo: shop orb spawning doesn't work right now, figure out how to fix this properly
	-- Spawn in an item or perk entity for the shop
	local function create_our_item_entity(item, x, y)
		if item.perk ~= nil then
			-- our item is a perk (dont_remove_other_perks = true)
			return perk_spawn(x, y, item.perk, true)
		--elseif item.shop.orb ~= nil then
		--	orb_id = orb_id + 1
		--	print("Orb " .. orb_id .. " spawned in the shop")
		--	GlobalsSetValue("ap_orb_id", orb_id)
		--	return EntityLoad("mods/archipelago/data/archipelago/entities/items/orbs/ap_orb_progression_" .. orb_id .. ".xml", x, y)
		elseif #item.items > 0 then
			-- our item is something else (random choice)
			return EntityLoad(item.items[Random(1, #item.items)], x, y)
		else -- error?
			-- TODO
			print_error("Failed to load our own shopitem!")
		end
	end

	-- Creates a trap item
	local function create_trap_item_entity(x, y)
		local entity_name = "data/archipelago/entities/items/ap_trap_item_0" .. tostring(Random(1, 4)) .. ".xml"
		local trap_description = "$ap_shopdescription_trap" .. tostring(Random(1, 8))
		return EntityLoad(entity_name, x, y), trap_description
	end

	-- Basically chooses the item graphic depending on the generated item's flags
	local function create_ap_entity_from_flags(location, x, y)
		local flags = location.item_flags

		if bit.band(flags, AP.ITEM_FLAG_TRAP) ~= 0 then
			return create_trap_item_entity(x, y)
		end
		
		local item_filename = "ap_junk_shopitem.xml"
		local item_description = "$ap_shopdescription_junk"
		if bit.band(flags, AP.ITEM_FLAG_USEFUL) ~= 0 then
			item_filename = "ap_useful_shopitem.xml"
			item_description = "$ap_shopdescription_useful"
		elseif bit.band(flags, AP.ITEM_FLAG_PROGRESSION) ~= 0 then
			item_filename = "ap_progression_shopitem.xml"
			item_description = "$ap_shopdescription_progression"
		end

		local item_entity = EntityLoad("data/archipelago/entities/items/" .. item_filename, x, y)
		return item_entity, item_description
	end

	-- Spawns in an AP item (our own entity to represent items that don't exist in this game)
	local function create_foreign_item_entity(location, x, y)
		local entity_id, description = create_ap_entity_from_flags(location, x, y)
		local name = location.item_name

		-- Change item name
		change_entity_ingame_name(entity_id, name, description)
		return entity_id
	end

	-- Generates an items and creates the entity used to make the shop item
	local function generate_ap_shop_item_entity(x, y)
		local location = Globals.ShopLocations:getKey(get_shop_location_id(x, y))
		local item_id = location.item_id
		local item = item_table[item_id]

		if location.is_our_item and item and item.items and item_id ~= AP.TRAP_ID then
			return create_our_item_entity(item, x, y), false
		else
			return create_foreign_item_entity(location, x, y), true
		end
	end -- generate_ap_shop_item_entity

	-- The majority of this function is taken from scripts/items/generate_shop_item.lua
	-- Used to create the shop item and attach components to make it interactable, and have unique descriptions etc.
	local function generate_ap_shop_item(x, y, cheap_item)
		local biomeid = get_shop_num(y)
		local price = generate_item_price(biomeid, cheap_item)

		local entity_id, is_foreign_item = generate_ap_shop_item_entity(x, y)

		-- We add a custom component to store the id that we are unlocking when the item is purchased,
		-- as well as some other things
		EntityAddComponent(entity_id, "VariableStorageComponent", {
			_tags="archipelago,enabled_in_world",
			name="ap_shop_data",
			value_string=JSON:encode({
				location_id = get_shop_location_id(x, y),
				price = price,
				sale = cheap_item,
				is_ap_item = is_foreign_item,
			})
		})

		EntityAddComponent(entity_id, "LuaComponent", {
			_tags="archipelago",
			script_source_file="data/archipelago/scripts/shopitem_processed.lua",
			execute_on_added="1",
			execute_every_n_frame="-1",
			call_init_function="1",
			script_item_picked_up="data/archipelago/scripts/shopitem_processed.lua",
		})
	end -- generate_shop_item

	-- Spawns either an AP item or spell shop item randomly, based on 
	local function spawn_either(x, y, is_sale, is_wand_shop)
		if remaining_ap_items > 0 and Randomf() <= remaining_ap_items / total_remaining_items then
			generate_ap_shop_item(x, y, is_sale)
			remaining_ap_items = remaining_ap_items - 1
			num_ap_items = num_ap_items + 1
		else
			if is_wand_shop then
				generate_shop_wand(x, y, is_sale)
			else
				generate_shop_item(x, y, is_sale, nil, true)
			end
		end
		total_remaining_items = total_remaining_items - 1
	end -- spawn_either

	-- Replacing this function with our own to inject AP items
	-- It mostly follows the original shopgen logic with the exception of distributing AP items
	spawn_all_shopitems = function(x, y)
		EntityLoad( "data/entities/buildings/shop_hitbox.xml", x, y )

		SetRandomSeed(x, y)
		-- this is the "Extra Item In Holy Mountain" perk, not an AP global
		local count = tonumber( GlobalsGetValue( "TEMPLE_SHOP_ITEM_COUNT", "5" ) )
		local width = 132
		local item_width = width / count
		local sale_item_i = Random( 1, count )

		-- Reset AP values
		remaining_ap_items = 5
		num_ap_items = 0

		if( Random(0, 100) <= 50 ) then
			-- Spell shop
			total_remaining_items = count * 2
			for i=1,count do
				spawn_either(x + (i-1)*item_width, y, i == sale_item_i)
				spawn_either(x + (i-1)*item_width, y - 30, false)
				LoadPixelScene( "data/biome_impl/temple/shop_second_row.png", "data/biome_impl/temple/shop_second_row_visual.png", x + (i-1)*item_width - 8, y-22, "", true )
			end
		else
			-- Wand shop
			total_remaining_items = count
			for i=1,count do
				spawn_either(x + (i-1)*item_width, y, i == sale_item_i, true)
			end
		end

	end -- spawn_all_shopitems

end

ap_extend_temple_altar()
