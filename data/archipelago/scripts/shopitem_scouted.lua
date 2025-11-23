local Globals = dofile("data/archipelago/scripts/globals.lua")
local ShopItems = dofile("data/archipelago/scripts/shopitem_utils.lua")

function collision_trigger(colliding_entity_id)
	if not colliding_entity_id or not EntityHasTag(colliding_entity_id, "player_unit") then
		return
	end

	local item_data = ShopItems.get_ap_item_from_entity(GetUpdatedEntityID())
	Globals.ShopScoutedQueue:append(item_data.location_id)
end
