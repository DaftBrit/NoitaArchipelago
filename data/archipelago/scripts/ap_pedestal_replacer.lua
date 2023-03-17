local Biomes = dofile("data/archipelago/scripts/ap_biome_mapping.lua")
local Globals = dofile("data/archipelago/scripts/globals.lua")
dofile_once("data/archipelago/scripts/ap_utils.lua")

local function PedestalWandReplacer()
    local ap_old_spawn_wands = spawn_wands
    local ap_old_spawn_potions = spawn_potions
    local replaced_pedestal = ""

    local function ap_replace_pedestals(x, y)
        local biome_name = BiomeMapGetName(x, y)
        local has_spawned = false
        -- check if the biome has checks left, if not then just spawn a chest/heart as normal
        if Biomes[biome_name] ~= nil then
            local biome_data = Biomes[biome_name]
            for i = biome_data.first_ped, biome_data.first_ped + 19 do
                if Globals.MissingLocationsSet:has_key(i) then
                    -- spawn the pedestal item, tell it its ID
                    local ap_pedestal_id = EntityLoad("data/archipelago/entities/items/pickup/ap_pedestal_random.xml", x, y)
                    has_spawned = true
                    addNewInternalVariable(ap_pedestal_id, "biome_name", "value_string", biome_name)
                    addNewInternalVariable(ap_pedestal_id, "pedestal_type", "value_string", replaced_pedestal)
                    break
                end
            end
        end
        -- chest spawned in non-applicable biome or no more chests for that biome, spawn heart/chest normally
        if has_spawned ~= true then
            if replaced_pedestal == "wand" then
                ap_old_spawn_wands(x, y)
            elseif replaced_pedestal == "potion" then
                ap_old_spawn_potions(x, y)
            else
                print("error in ap_pedestal_replacer.lua in going back to the old spawn function")
            end
        end
    end

    spawn_wands = function(x, y)
        replaced_pedestal = "wand"
        ap_replace_pedestals(x, y)
    end

    spawn_potions = function(x, y)
        replaced_pedestal = "potion"
        ap_replace_pedestals(x, y)
    end
end

PedestalWandReplacer()
