dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/gun/gun_actions.lua")
dofile_once("data/scripts/game_helpers.lua")
local Biomes = dofile("data/archipelago/scripts/ap_biome_mapping.lua")
local Globals = dofile("data/archipelago/scripts/globals.lua")
dofile_once("data/archipelago/scripts/item_utils.lua")


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
	if location ~= 0 then
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
		-- if you found all of your checks for that biome but find another ap pedestal from the biome
		-- todo: spawn random item
	end
	EntityLoad("data/entities/particles/image_emitters/chest_effect.xml", x, y)
end


function item_pickup( entity_item, entity_who_picked, name )
	on_open( entity_item )
	EntityKill( entity_item )
end
