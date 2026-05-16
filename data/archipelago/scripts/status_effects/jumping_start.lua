local entity = GetUpdatedEntityID()
local player = EntityGetRootEntity(entity)

local var_comp = EntityGetFirstComponentIncludingDisabled(entity, "VariableStorageComponent", "fly_time_max")
local character = EntityGetFirstComponentIncludingDisabled(player, "CharacterDataComponent")
if var_comp == nil or character == nil then return end

ComponentSetValue2(var_comp, "value_float", ComponentGetValue2(character, "fly_time_max"))
ComponentSetValue2(character, "fly_time_max", 0)
