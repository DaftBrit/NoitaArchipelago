-- todo: finish this script
local function PedestalWandReplacer()

    local old_spawn_wands = spawn_wands

    local function ap_replace_pedestals(x, y)
        old_spawn_wands(x, y)
    end

    spawn_wands = function(x, y)
        ap_replace_pedestals(x, y)
    end
end

PedestalWandReplacer()
