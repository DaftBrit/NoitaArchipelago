local NULL_ENTITY = 0 --[[@as entity_id]]

local entity_id = GetUpdatedEntityID()
local player_id = EntityGetRootEntity(entity_id)

if player_id == NULL_ENTITY then return end

local comp = EntityGetFirstComponentIncludingDisabled(player_id, "DamageModelComponent")
if comp == nil then return end

local resists = EntityGetComponentIncludingDisabled(entity_id, "VariableStorageComponent") or {}
for _,resist_comp in ipairs(resists) do
	local dmg_type = tostring(ComponentGetValue2(resist_comp, "name"))

	local multiplier = tonumber(ComponentObjectGetValue2(comp, "damage_multipliers", dmg_type)) or 1.0
	ComponentSetValue2(resist_comp, "value_float", multiplier)
	ComponentObjectSetValue2(comp, "damage_multipliers", dmg_type, multiplier * 2)
end

local resist_effects = EntityGetAllChildren(player_id, "effect_resistance") or {}
for _,effect in ipairs(resist_effects) do
	EntitySetComponentsWithTagEnabled(effect, "effect_resistance", false)
end
