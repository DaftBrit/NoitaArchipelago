dofile( "data/scripts/game_helpers.lua" )
dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/archipelago/scripts/ap_utils.lua")

local entity_id = GetUpdatedEntityID()
local pos_x, pos_y = EntityGetTransform( entity_id )

local orbcomp = EntityGetComponent( entity_id, "OrbComponent" )
local orb_id = -1

for _, comp_id in pairs(orbcomp) do
	orb_id = ComponentGetValueInt( comp_id, "orb_id" )
	EntityRemoveComponent( entity_id, comp_id )
end

addNewInternalVariable(entity_id, "OriginalID", "value_int", orb_id)
