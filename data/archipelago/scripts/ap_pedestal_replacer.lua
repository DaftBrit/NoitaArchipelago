local Biomes = dofile("data/archipelago/scripts/ap_biome_mapping.lua")
local Globals = dofile("data/archipelago/scripts/globals.lua")
dofile_once("data/archipelago/scripts/ap_utils.lua")
local item_table = dofile("data/archipelago/scripts/item_mappings.lua")
local AP = dofile("data/archipelago/scripts/constants.lua")

local function PedestalReplacer()
    local ap_old_spawn_wands = spawn_wands
    local ap_old_spawn_potions = spawn_potions
    local replaced_pedestal = ""

    local function ap_replace_pedestals(x, y)
        local biome_name = BiomeMapGetName(x, y)
        local has_spawned = false
        -- check if the biome has checks left, if not then just spawn a chest/heart as normal
        if Biomes[biome_name] ~= nil then
            local biome_data = Biomes[biome_name]
            if biome_name == "$biome_fungicave" and replaced_pedestal == "potion" then
                -- fungal caverns has a ridiculous number of pedestals, this will cool it down a little
            else
                for i = biome_data.first_ped, biome_data.first_ped + 19 do
                    if Globals.MissingLocationsSet:has_key(i) and Globals.PedestalLocationsSet:has_key(i) then
                        -- spawn the pedestal item, tell it its ID
                        Globals.PedestalLocationsSet:remove_key(i)
                        local location = Globals.LocationScouts:get_key(i)
                        local item_id = location.item_id
                        local item = item_table[item_id]
                        local ap_pedestal_id
                        if item_id >= 110008 and item_id <= 110013 then
                            y = y + 0.5
                        end
                        if contains_element({110003, 110023, 110024, 110031}, item_id) and replaced_pedestal == "wand" then
                            x = x + 1.5
                        end
                        if item_id == 110027 and replaced_pedestal == "potion" then
                            x = x + 0.5
                        end
                        if location.is_our_item and item and item_id ~= AP.TRAP_ID then
                            ap_pedestal_id = create_our_item_entity(item, x, y), false
                        else
                            ap_pedestal_id = create_foreign_item_entity(location, x, y), true
                        end
                        has_spawned = true
                        addNewInternalVariable(ap_pedestal_id, "location", "value_int", i)
                        addNewInternalVariable(ap_pedestal_id, "pedestal_type", "value_string", replaced_pedestal)
                        EntityAddComponent(ap_pedestal_id, "LuaComponent", {
                            _tags="archipelago",
                            script_item_picked_up="data/archipelago/scripts/items/ap_pedestal_processed.lua",
                        })
                        break
                    end
                end
            end
        end
        -- pedestal item somehow managed to spawn outside of an applicable biome, or it's a pedestal in a modded biome
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

PedestalReplacer()
