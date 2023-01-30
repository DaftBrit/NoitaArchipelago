local AP = dofile("data/archipelago/scripts/constants.lua")
local Globals = dofile("data/archipelago/scripts/globals.lua")


local function choose_orb_from_flags(location)
    local flags = location.item_flags
    local orb_name = "porb"

    if bit.band(flags, AP.ITEM_FLAG_TRAP) ~= 0 then
        orb_name = "ap_orb_trap_" .. tostring(Random(1,3))
    end
    if bit.band(flags, AP.ITEM_FLAG_USEFUL) ~= 0 then
        orb_name = "ap_orb_useful"
    elseif bit.band(flags, AP.ITEM_FLAG_PROGRESSION) ~= 0 then
        orb_name = "ap_orb_progression"
    end

    local orb_file = "data/archipelago/entities/items/orbs/" .. orb_name .. ".xml"

    return orb_file
end

function OrbArtChanger(orb_id)
    local location = Globals.LocationScouts:get_key(111001)

    return choose_orb_from_flags(location)
end


spawn_orb = function(x, y)
	local orb_id = EntityLoad( "data/entities/items/orbs/orb_00.xml", x, y )
	EntityLoad( "data/entities/items/books/book_00.xml", x - 30, y + 40 )
	EntityLoad( "data/entities/misc/music_energy_000.xml", x, y - 10 )

    local location = Globals.LocationScouts:getKey(111001)
    local image_id = EntityGetFirstComponent(orb_id, "SpriteComponent")
    local item_filename = choose_orb_from_flags(location)
    ComponentSetValue2(image_id, "image_file", "data/archipelago/entities/items/orbs/" .. item_filename)
end
