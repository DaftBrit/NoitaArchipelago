local entity_id = GetUpdatedEntityID()
local comp_id = GetUpdatedComponentID()
EntityConvertToMaterial(entity_id, "potion_glass_box2d")
EntityRemoveComponent(entity_id, comp_id)

function item_pickup(potion_id, entity_pickupper, item_name)
    local potion_comp_id = GetUpdatedComponentID()
    EntityConvertToMaterial(potion_id, "potion_glass_box2d")
    EntityRemoveComponent(potion_id, potion_comp_id)
end