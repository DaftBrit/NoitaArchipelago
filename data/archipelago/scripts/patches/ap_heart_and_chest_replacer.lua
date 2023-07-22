dofile_once("data/archipelago/scripts/ap_utils.lua")
local AP = dofile("data/archipelago/scripts/constants.lua")

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
			-- the r given here should be exactly the same as the r given by ap_old_spawn_heart
			local r = ProceduralRandom(x, y)
			SetRandomSeed(x, y)
			-- spawn_heart has a 70% chance of spawning, while spawn_chest always spawns
			if r > 0.3 and name == "heart" or name == "chest" then
				local start_num = biome_data.first_hc
				-- if parallel worlds path is chosen, spawn pw items, otherwise spawn main world items
				if GameHasFlagRun("ap_parallel_worlds") then
					if x <= -20000 then
						start_num = start_num + AP.WEST_OFFSET
					elseif x >= 20000 then
						start_num = start_num + AP.EAST_OFFSET
					end
				end
				for i = start_num, start_num + 19 do
					if Globals.MissingLocationsSet:has_key(i) then
						-- do stuff that the vanilla spawn_heart does
						SetRandomSeed(x + 45, y - 2123)
						local rnd = Random(1, 100)
						-- if it's replacing spawn_chest, it cannot be a mimic
						if (rnd <= 90) or (y < 512 * 3) or name == "chest" then
							if Random(1,300) == 1 and name ~= "chest" then
								spawn_mimic_sign(x, y)
							end
							-- spawn the chest, set ap_chest_id equal to its entity ID
							local ap_chest_id = EntityLoad("data/archipelago/entities/items/pickup/ap_chest_random.xml",x,y)
							has_spawned = true
							addNewInternalVariable(ap_chest_id, "biome_name", "value_string", biome_name)
							break
						elseif name ~= "chest" then
							if Random(1, 30) == 1 then
								spawn_mimic_sign(x, y)
							end
							if rnd <= 95 then
								EntityLoad("data/entities/animals/ap_chest_mimic.xml", x, y)
							else
								EntityLoad("data/archipelago/entities/animals/ap_mimic/ap_chest_leggy.xml", x, y)
							end
							has_spawned = true
							break
						end
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
