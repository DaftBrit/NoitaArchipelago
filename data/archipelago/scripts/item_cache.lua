dofile_once("data/archipelago/lib/json.lua")


function ResetCache(ap_seed)
    local f = io.open("mods/archipelago/cache/delivered_" .. ap_seed, "w+")
    f:close()
end

function ContinueCache(ap_seed)
    local f = io.open("mods/archipelago/cache/delivered_" .. ap_seed, "r")
    delivered_items = JSON:decode(f:read("*a"))
    f:close()
end