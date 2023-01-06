dofile( "data/scripts/game_helpers.lua" )
dofile_once("data/scripts/lib/utilities.lua")

local entity_id = GetUpdatedEntityID()
local pos_x, pos_y = EntityGetTransform( entity_id )

--GlobalsSetValue("ap_orb_id", 60)

local orbcomp = EntityGetComponent( entity_id, "OrbComponent" )
local orb_id = tonumber(GlobalsGetValue("ap_orb_id"))

print("ap orb init started")

print("orb_id is " .. orb_id)

for _, comp_id in pairs(orbcomp) do
	print(_)
	print(comp_id)
	ComponentGetValue2( comp_id, "orb_id")
	print(ComponentGetValue2(comp_id, "orb_id"))
end


for _, comp_id in pairs(orbcomp) do
	print(_)
	print(comp_id)
	ComponentSetValue( comp_id, "orb_id", orb_id )
end

orb_id = orb_id + 1

print("orb_id is now " .. orb_id)

GlobalsSetValue("ap_orb_id", tostring(orb_id))