-- Script run when shop item is picked up

dofile_once("data/scripts/lib/utilities.lua")

--get_variable_storage_component
function item_pickup(entity_item, entity_who_picked, name)
  local loc_component = get_variable_storage_component(entity_item, "ap_location_id")
  local loc_id = ComponentGetValue2(loc_component, "value_string")

  local purchase_queue = GlobalsGetValue("AP_COMPONENT_ITEM_UNLOCK_QUEUE")
  GlobalsSetValue("AP_COMPONENT_ITEM_UNLOCK_QUEUE", purchase_queue .. "," .. loc_id)
end
