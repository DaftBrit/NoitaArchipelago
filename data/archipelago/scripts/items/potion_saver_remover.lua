local entity_id = GetUpdatedEntityID()
local physics_damage_comp = EntityGetFirstComponentIncludingDisabled(entity_id, "PhysicsBodyCollisionDamageComponent")
ComponentSetValue2(physics_damage_comp, "damage_multiplier", 0.017)

function enabled_changed(potion_id, is_enabled)
    local potion_physics_damage_comp = EntityGetFirstComponentIncludingDisabled(potion_id, "PhysicsBodyCollisionDamageComponent")
    ComponentSetValue2(potion_physics_damage_comp, "damage_multiplier", 0.017)
end