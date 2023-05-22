dofile_once("data/archipelago/scripts/ap_utils.lua")

local function APPedestalReplacer()
	local Biomes = dofile("data/archipelago/scripts/ap_biome_mapping.lua")
	local Globals = dofile("data/archipelago/scripts/globals.lua")
	local item_table = dofile("data/archipelago/scripts/item_mappings.lua")
	local AP = dofile("data/archipelago/scripts/constants.lua")

	local ap_old_spawn_wands = spawn_wands
	local ap_old_spawn_potions = spawn_potions
	local ap_old_spawn_trapwand = spawn_trapwand

	local function ap_replace_pedestals(x, y, replaced_pedestal)
		local biome_name = BiomeMapGetName(x, y)
		-- check if the biome has checks left, if not then just spawn a chest/heart as normal
		if Biomes[biome_name] == nil then return false end

		local biome_data = Biomes[biome_name]
		for i = biome_data.first_ped, biome_data.first_ped + 19 do
			if Globals.MissingLocationsSet:has_key(i) and Globals.PedestalLocationsSet:has_key(i) then
				-- spawn the pedestal item, tell it its ID
				Globals.PedestalLocationsSet:remove_key(i)
				local location = Globals.LocationScouts:get_key(i)
				local item_id = location.item_id

				if not location.is_our_item then
					if replaced_pedestal == ("wand" or "trapwand") then
						y = y - 6
						x = x + 0.5
					elseif replaced_pedestal == "potion" then
						y = y - 8
						x = x + 0.5
					end
				-- wands
				elseif item_id >= AP.FIRST_WAND_ITEM_ID and item_id <= AP.LAST_WAND_ITEM_ID then
					y = y + 0.5
				-- potions or powder stash
				elseif contains_element({AP.POTION_ITEM_ID, AP.RANDOM_POTION_ITEM_ID, AP.SECRET_POTION_ITEM_ID, AP.POWDER_STASH_ITEM_ID}, item_id)
						and replaced_pedestal == "wand" then
					x = x + 1.5
				-- kammi
				elseif item_id == AP.KAMMI_ITEM_ID and replaced_pedestal == "potion" then
					x = x + 0.5
				end

				local item = item_table[item_id]
				local ap_pedestal_id
				if location.is_our_item and item and item_id ~= AP.TRAP_ID then
					ap_pedestal_id = create_our_item_entity(item, x, y)
					EntityAddTag(ap_pedestal_id, "my_ap_item")
					-- this gives the pedestal items that ap logo particle effect so you can tell it's your item
					local particle_comp = EntityAddComponent(ap_pedestal_id, "SpriteParticleEmitterComponent", {
						sprite_file="data/archipelago/entities/items/icon-useful.png",
						lifetime=6,
						velocity_slowdown=5,
						velocity_always_away_from_center=1,
						count_min=1,
						count_max=1,
						emission_interval_min_frames=60,
						emission_interval_max_frames=90,
					})
					-- EntityAddComponent can't set multi-value types
					ComponentSetValue2(particle_comp, "color", 1, 1, 1, .4)
					ComponentSetValue2(particle_comp, "color_change", 0, 0, 0, -.2)
					ComponentSetValue2(particle_comp, "scale", 0.15, 0.15)
					ComponentSetValue2(particle_comp, "scale_velocity", 0.2, 0.2)
					ComponentSetValue2(particle_comp, "randomize_rotation", 0, 50)
				else
					ap_pedestal_id = create_foreign_item_entity(location, x, y)
					if location.is_our_item and item_id == AP.TRAP_ID then
						EntityAddTag(ap_pedestal_id, "my_ap_item")
					end
				end
				addNewInternalVariable(ap_pedestal_id, "ap_location_id", "value_int", i)
				EntityAddComponent(ap_pedestal_id, "LuaComponent", {
					_tags="archipelago",
					script_item_picked_up="data/archipelago/scripts/items/ap_pedestal_processed.lua",
				})
				if replaced_pedestal == "trapwand" then
					EntityAddTag(ap_pedestal_id, "trap_wand")
					EntityAddComponent(ap_pedestal_id, "LuaComponent", {
						script_item_picked_up="data/archipelago/scripts/items/pedestal_trap_pickup.lua"
					})
				end
				return true
			end
		end

		return false
	end

	spawn_wands = function(x, y)
		-- check that we actually have the location info before spawning an ap pedestal
		if GameHasFlagRun("AP_LocationInfo_received") then
			if not ap_replace_pedestals(x, y, "wand") then
				ap_old_spawn_wands(x, y)
			end
		else
			ap_old_spawn_wands(x, y)
		end
	end

	spawn_potions = function(x, y)
		-- fungal caverns has a ridiculous number of pedestals, this will cool it down a little
		if BiomeMapGetName(x, y) ~= "$biome_fungicave" and GameHasFlagRun("AP_LocationInfo_received") then
			if not ap_replace_pedestals(x, y, "potion") then
				ap_old_spawn_potions(x, y)
			end
		else
			ap_old_spawn_potions(x, y)
		end
	end

	spawn_trapwand = function(x, y)
		if GameHasFlagRun("AP_LocationInfo_received") then
			if not ap_replace_pedestals(x, y, "trapwand") then
				ap_old_spawn_trapwand(x, y)
			end
		else
			ap_old_spawn_trapwand(x, y)
		end
	end
end

APPedestalReplacer()
