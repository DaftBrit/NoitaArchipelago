local Biomes = dofile("data/archipelago/scripts/ap_biome_mapping.lua")
local Globals = dofile("data/archipelago/scripts/globals.lua")
dofile_once("data/archipelago/scripts/item_utils.lua")
dofile_once("data/scripts/item_spawnlists.lua")
dofile_once("data/scripts/director_helpers.lua")


function on_open(entity_item)
	local biome_comp_id = EntityGetFirstComponent(entity_item, "VariableStorageComponent")
	local biome_name = ComponentGetValue2(biome_comp_id, "value_string")
	local missing_locations = {}
	if Biomes[biome_name] ~= nil then
		local biome_data = Biomes[biome_name]
		for i = biome_data.first_ped, biome_data.first_ped + 19 do
			if Globals.MissingLocationsSet:has_key(i) then
				table.insert(missing_locations, i)
			end
		end
	end
	local location = missing_locations[math.random(#missing_locations)]
	if location ~= nil then
		Globals.LocationUnlockQueue:append(location)
		Globals.MissingLocationsSet:remove_key(location)
		-- for some reason, if the below is included it double spawns items? idk why
		--local location = Globals.LocationScouts:get_key(i)
		--if location == nil then
		--	Log.Error("ap_chest_random failed to retrieve info from cache")
		--end
		--local item_id = location.item_id
		--if location.is_our_item then
		--	SpawnItem(item_id, true)
		--end
	else 			
		-- if you found all of your checks for that biome but find another ap pedestal that already spawned
		local ped_x, ped_y = EntityGetTransform(entity_item)
		local pedestal_type = getInternalVariableValue(entity_item, "pedestal_type", "value_string")
		if pedestal_type == "wand" then
			-- todo: find a way to make it spawn a wand from the g_items list for that biome, or random wand
			spawn_from_list("potion_spawnlist", ped_x, ped_y)
		elseif pedestal_type == "potion" then
			spawn_from_list("potion_spawnlist", ped_x, ped_y)
		else
			print("error spawning extra pedestal location items")
		end
	end
	EntityLoad("data/entities/particles/image_emitters/chest_effect.xml", x, y)
end


function item_pickup( entity_item, entity_who_picked, name )
	on_open( entity_item )
	EntityKill( entity_item )
end
