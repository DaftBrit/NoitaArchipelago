-- this is to kill ap checks that try to weasel their way into your inventory
dofile_once("data/archipelago/scripts/item_utils.lua")

function item_pickup(entity_item, entity_who_picked, name)
	EntityKill(entity_item)
end
