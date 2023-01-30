dofile_once("data/scripts/lib/utilities.lua")

local entity_id = GetUpdatedEntityID()
local timeleft = 0
local comps = EntityGetComponent( entity_id, "VariableStorageComponent" )

if ( comps ~= nil ) then
	for _,v in ipairs( comps ) do
		local n = ComponentGetValue2( v, "name" )
		if ( n == "lifetime" ) then
			timeleft = ComponentGetValue2( v, "value_int" )
			timeleft = math.max( timeleft - 1, 0 )
			ComponentSetValue2( v, "value_int", timeleft )
			break
		end
	end
end

