dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/archipelago/scripts/item_utils.lua")

local function ap_extend_temple_altar()
	local AP = dofile("data/archipelago/scripts/constants.lua")
	local Globals = dofile("data/archipelago/scripts/globals.lua")
	local ShopItems = dofile("data/archipelago/scripts/shopitem_utils.lua")

	local remaining_ap_items = 0
	local total_remaining_items = 0
	local num_ap_items = 0


	-- Retrieves the shop index based on the y coordinate (depth) to determine which holy mountain it is
	-- The second value is how the game determines shop item pricing
	local function get_shop_num(y)
		if y < 1500 then return 1, 1 -- Mines
		elseif y < 3000 then return 2, 1 -- Coal Pits
		elseif y < 5500 then return 3, 2 -- Snowy Depths
		elseif y < 7000 then return 4, 2 -- Hiisi Base
		elseif y < 9500 then return 5, 3 -- Underground Jungle
		elseif y < 11500 then return 6, 4 -- The Vault
		else return 7, 6 -- Temple of the Art
		end
	end


	-- Gets the location id for the shop based on the y coordinate and number of AP items already placed (assuming max 5).
	-- The last (6th) location is the spell refresh.
	local function get_shop_location_id(x, y)
		return AP.FIRST_SHOP_LOCATION_ID + (get_shop_num(y)-1) * 6 + num_ap_items
	end


	-- Spawns either an AP item or spell shop item randomly. If an AP item was already obtained, replace it with a
	-- normal shop item.
	local function spawn_either(x, y, is_sale, is_wand_shop)
		local _, biomeid = get_shop_num(y)
		local location_id = get_shop_location_id(x, y)
		local is_not_obtained = Globals.MissingLocationsSet:has_key(location_id)
		local is_ap_shopitem = remaining_ap_items > 0 and Randomf() <= remaining_ap_items / total_remaining_items
		-- if pw path is on, generate pw shops differently. Otherwise, generate them like normal.
		if GameHasFlagRun("ap_parallel_worlds") then
			if x <= -20000 then
				location_id = location_id + AP.WEST_OFFSET
			elseif x >= 20000 then
				location_id = location_id + AP.EAST_OFFSET
			end
		end

		if is_not_obtained and is_ap_shopitem then
			ShopItems.generate_ap_shop_item(location_id, biomeid, x, y, is_sale)
		else
			if is_wand_shop then
				generate_shop_wand(x, y, is_sale)
			else
				generate_shop_item(x, y, is_sale, nil, true)
			end
		end

		if is_ap_shopitem then
			remaining_ap_items = remaining_ap_items - 1
			num_ap_items = num_ap_items + 1
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


	-- Override of spawn_hp in the original file
	spawn_hp = function(x, y)
		EntityLoad( "data/entities/items/pickup/heart_fullhp_temple.xml", x-16, y )
		EntityLoad( "data/entities/buildings/music_trigger_temple.xml", x-16, y )
		--
		-- This part would otherwise be a spell refresher

		local location_id = AP.FIRST_SPELL_REFRESH_LOCATION_ID + (get_shop_num(y) - 1) * 6
		-- if parallel worlds path is chosen, spawn pw item, otherwise spawn main world item
		if GameHasFlagRun("ap_parallel_worlds") then
			if x <= -20000 then
				location_id = location_id + AP.WEST_OFFSET
			elseif x >= 20000 then
				location_id = location_id + AP.EAST_OFFSET
			end
		end
		local is_not_obtained = Globals.MissingLocationsSet:has_key(location_id)
		if is_not_obtained then
			ShopItems.generate_ap_shop_item(location_id, 0, x+16, y+6)
		else
			EntityLoad( "data/entities/items/pickup/spell_refresh.xml", x+16, y )
		end

		---
		EntityLoad( "data/entities/buildings/coop_respawn.xml", x, y )
	end
end

ap_extend_temple_altar()
