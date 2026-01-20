dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/gun/gun_actions.lua")
dofile_once("data/scripts/game_helpers.lua")
local Biomes = dofile("data/archipelago/scripts/ap_biome_mapping.lua")
local Globals = dofile("data/archipelago/scripts/globals.lua") --- @type Globals
local AP = dofile("data/archipelago/scripts/constants.lua")
local Log = dofile("data/archipelago/scripts/logger.lua") ---@type Logger
dofile_once("data/archipelago/scripts/item_utils.lua")
dofile_once("data/scripts/items/chest_random.lua")


local function on_open(entity_item)
	local biome_comp_id = EntityGetFirstComponent(entity_item, "VariableStorageComponent")
	if biome_comp_id == nil then
		Log.Error("ap_chest_random missing VariableStorageComponent")
		return
	end

	local biome_name = ComponentGetValue2(biome_comp_id, "value_string")
	local x, y = EntityGetTransform(entity_item)
	local item_spawned = false
	if Biomes[biome_name] ~= nil then
		local biome_data = Biomes[biome_name]
		local start_num = biome_data.first_hc
		-- if parallel worlds path is chosen, spawn pw chests, otherwise spawn main world chests
		if GameHasFlagRun("ap_parallel_worlds") then
			if x <= -20000 then
				start_num = biome_data.first_hc + AP.WEST_OFFSET
			elseif x >= 20000 then
				start_num = biome_data.first_hc + AP.EAST_OFFSET
			end
		end
		for i = start_num, start_num + 19 do
			if Globals.MissingLocationsSet:has_key(i) then
				Globals.LocationUnlockQueue:append(i)
				Globals.MissingLocationsSet:remove_key(i)
				local location = Globals.LocationScouts:get_key(i)
				if location == nil then
					Log.Error("ap_chest_random failed to retrieve info from cache")
				end
				local item_id = location.item_id
				if location.is_our_item then
					SpawnItem(item_id, true)
					GameAddFlagRun("ap" .. i)
				end
				item_spawned = true
				break
			end
		end
	end
	if item_spawned ~= true then
		drop_random_reward(x, y, entity_item)
	end
	EntityLoad("data/entities/particles/image_emitters/chest_effect.xml", x, y)
end


function item_pickup( entity_item, entity_who_picked, name )
	on_open( entity_item )
	EntityKill( entity_item )
end
