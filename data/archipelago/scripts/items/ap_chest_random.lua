dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/gun/gun_actions.lua")
dofile_once("data/scripts/game_helpers.lua")
local Biomes = dofile("data/archipelago/scripts/ap_biome_mapping.lua")
local Globals = dofile("data/archipelago/scripts/globals.lua")
dofile_once("data/archipelago/scripts/item_utils.lua")


function on_open(entity_item)
	local biome_comp_id = EntityGetFirstComponent(entity_item, "VariableStorageComponent")
	local biome_comp_name = ComponentGetValue2(biome_comp_id, "value_string")
	for biome_name, biome_data in pairs(Biomes) do
		if biome_comp_name == biome_data.name then
			for i = biome_data.first_hc, biome_data.first_hc + 19 do
				if Globals.MissingLocationsSet:has_key(i) then
					print("missing locations set has that location")
					Globals.LocationUnlockQueue:append(i)
					print("appending location unlock queue")
					Globals.MissingLocationsSet:remove_key(i)
					print("removing location from missing locations set")
					local location = Globals.LocationScouts:get_key(i)
					if location == nil then
						Log.Error("ap_chest_random failed to retrieve info from cache")
					end
					local item_id = location.item_id
					if location.is_our_item then
						SpawnItem(item_id, true)
					end

					break
				end
			end
		end
	end
	EntityLoad("data/entities/particles/image_emitters/chest_effect.xml", x, y)
end


function item_pickup( entity_item, entity_who_picked, name )
	on_open( entity_item )
	
	EntityKill( entity_item )
end
