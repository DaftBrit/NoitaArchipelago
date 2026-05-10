local entity_id = GetUpdatedEntityID()
local comp = EntityGetFirstComponent(entity_id, "GameEffectComponent")

if comp == nil then return end

local shader_varname = tostring(ComponentGetValue2(comp, "custom_effect_id"))
GameSetPostFxParameter(shader_varname, 0, 0, 0, 0)
