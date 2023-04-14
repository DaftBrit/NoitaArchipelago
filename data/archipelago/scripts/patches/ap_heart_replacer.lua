dofile_once("data/archipelago/scripts/ap_utils.lua")

local function APHeartReplacer()
    local Biomes = dofile("data/archipelago/scripts/ap_biome_mapping.lua")
    local Globals = dofile("data/archipelago/scripts/globals.lua")

    -- sets a function for the old version of spawn_heart
	local ap_old_spawn_heart = spawn_heart

	local function ap_replace_heart(x, y)
		local biome_name = BiomeMapGetName(x, y)
		local has_spawned = false
		-- check if the biome has checks left, if not then just spawn a chest/heart as normal
		if Biomes[biome_name] ~= nil then
			local biome_data = Biomes[biome_name]
			-- hearts/chests have a 30% chance not to spawn in the base game
			-- the r given here should be exactly the same as the r given by ap_old_spawn_heart
			local r = ProceduralRandom(x, y)
			SetRandomSeed(x, y)
			if r > 0.3 then
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
			ap_old_spawn_heart(x, y)
		end
	end

	-- this makes the spawn_heart the game calls for redirect to ap_replace_heart
	spawn_heart = function(x, y)
		ap_replace_heart(x, y)
	end
end

APHeartReplacer()
