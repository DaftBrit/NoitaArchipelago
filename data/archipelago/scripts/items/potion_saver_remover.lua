local entity_id = GetUpdatedEntityID()
local comp_id = GetUpdatedComponentID()
local physics_damage_comp = EntityGetFirstComponentIncludingDisabled(entity_id, "PhysicsBodyCollisionDamageComponent")
ComponentSetValue2(physics_damage_comp, "damage_multiplier", 0.017)
EntityRemoveComponent(entity_id, comp_id)

function item_pickup(potion_id, entity_pickupper, item_name)
    local potion_physics_damage_comp = EntityGetFirstComponentIncludingDisabled(potion_id, "PhysicsBodyCollisionDamageComponent")
    ComponentSetValue2(potion_physics_damage_comp, "damage_multiplier", 0.017)
end