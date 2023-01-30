dofile( "data/scripts/game_helpers.lua" )
dofile_once("data/scripts/lib/utilities.lua")

local entity_id = GetUpdatedEntityID()
local pos_x, pos_y = EntityGetTransform( entity_id )

local orbcomp = EntityGetComponent( entity_id, "OrbComponent" )
local orb_id = tonumber(GlobalsGetValue("ap_orb_id"))

--for _, comp_id in pairs(orbcomp) do
--	ComponentGetValue2( comp_id, "orb_id")
--end

for _, comp_id in pairs(orbcomp) do
	ComponentSetValue( comp_id, "orb_id", orb_id )
end

orb_id = orb_id + 1

GlobalsSetValue("ap_orb_id", tostring(orb_id))