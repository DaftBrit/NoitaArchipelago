dofile_once("data/archipelago/scripts/item_utils.lua")

function item_pickup(entity_item, entity_who_picked, name)
	BadTimes()
	EntityKill(entity_item)
end
