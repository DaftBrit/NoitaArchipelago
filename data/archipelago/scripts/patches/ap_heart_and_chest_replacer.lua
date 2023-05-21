dofile_once("data/archipelago/scripts/ap_utils.lua")

local function APHeartAndChestReplacer()
    local Biomes = dofile("data/archipelago/scripts/ap_biome_mapping.lua")
    local Globals = dofile("data/archipelago/scripts/globals.lua")

    -- sets a function for the old versions of spawn_heart and spawn_chest
	local ap_old_spawn_heart = spawn_heart
	local ap_old_spawn_chest = spawn_chest

	local function ap_replace_heart_or_chest(x, y, name)
		local biome_name = BiomeMapGetName(x, y)
		local has_spawned = false
		-- check if the biome has checks left, if not then just spawn a chest/heart as normal
		if Biomes[biome_name] ~= nil then
			local biome_data = Biomes[biome_name]
			-- hearts/chests have a 30% chance not to spawn in the base game
			-- the r given here should be exactly the same as the r given by ap_old_spawn_heart
			local r = ProceduralRandom(x, y)
			SetRandomSeed(x, y)
			-- spawn_heart has a 70% chance of spawning, while spawn_chest always spawns
			if r > 0.3 and name == "heart" or name == "chest" then
				for i = biome_data.first_hc, biome_data.first_hc + 19 do
					if Globals.MissingLocationsSet:has_key(i) then
						-- spawn the chest, set ap_chest_id equal to its entity ID
						local ap_chest_id = EntityLoad("data/archipelago/entities/items/pickup/ap_chest_random.xml",x,y)
						has_spawned = true
						addNewInternalVariable(ap_chest_id, "biome_name", "value_string", biome_name)
						break
					end
				end
			end
		end
		-- chest spawned in non-applicable biome or no more chests for that biome, spawn heart/chest normally
		if has_spawned ~= true then
			if name == "heart" then
				ap_old_spawn_heart(x, y)
			elseif name == "chest" then
				ap_old_spawn_chest(x, y)
			end
		end
	end

	-- this is for the spawn_heart function the generic biome_scripts.lua uses
	spawn_heart = function(x, y)
		ap_replace_heart_or_chest(x, y, "heart")
	end

	-- this is for the spawn_chest script within individual biomes
	spawn_chest = function(x, y)
		ap_replace_heart_or_chest(x, y, "chest")
	end

end

APHeartAndChestReplacer()
