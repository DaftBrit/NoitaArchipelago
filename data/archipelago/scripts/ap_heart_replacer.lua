
local function APHeartReplacer()
    -- sets a function for the old version of spawn_heart
    local ap_old_spawn_heart = spawn_heart

    local remaining_checks_in_biome = 5  -- rename, make the value dependent on an options slider probably

    local function ap_replace_heart(x, y)
        EntityLoad("data/archipelago/entities/items/pickup/ap_chest_random.xml", x, y)
        -- todo: change this item, make it spawn a chest or heart if remaining_checks_in_biome == 0
        -- todo: make something actually increment remaining_checks_in_biome
        -- should we make the chests have the corresponding item type icon?
        -- that would mean each chest would need to specifically correspond to the check in it
        -- and currently it just spawns the next flag in the list
    end

    spawn_heart = function(x, y)
        if remaining_checks_in_biome == 0 then
            ap_old_spawn_heart(x, y)
        else
            ap_replace_heart(x, y)
        end
    end
end

APHeartReplacer()
