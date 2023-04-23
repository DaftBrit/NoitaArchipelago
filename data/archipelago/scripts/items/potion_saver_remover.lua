local entity_id = GetUpdatedEntityID()
local comp_id = GetUpdatedComponentID()
local explode_comp = EntityGetFirstComponentIncludingDisabled(entity_id, "ExplodeOnDamageComponent")
ComponentSetValue2(explode_comp, "physics_body_destruction_required", 0.51)
EntityRemoveComponent(entity_id, comp_id)

function item_pickup(potion_id, entity_pickupper, item_name)
    local potion_comp_id = GetUpdatedComponentID()
    local potion_explode_comp = EntityGetFirstComponentIncludingDisabled(potion_id, "ExplodeOnDamageComponent")
    ComponentSetValue2(potion_explode_comp, "physics_body_destruction_required", 0.51)
    EntityRemoveComponent(potion_id, potion_comp_id)
end