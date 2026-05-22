
local entity = GetUpdatedEntityID()
local var = EntityGetFirstComponentIncludingDisabled(entity, "VariableStorageComponent", "frac_size")
assert(var ~= nil, "VariableStorageComponent on fracture_fade_in was null")

local value = ComponentGetValue2(var, "value_float")
if value < 12 then
	value = value + 0.1
	ComponentSetValue2(var, "value_float", value)
	GameSetPostFxParameter("AP_FRACTURE_PROGRESS", value, 0, 0, 0)
end
