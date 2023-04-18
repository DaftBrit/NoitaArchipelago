dofile( "data/scripts/game_helpers.lua" )
dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/archipelago/scripts/ap_utils.lua")

-- NOTE: This will replace the existing `item_pickup` function in orb_pickup.lua
function item_pickup( entity_item, entity_who_picked, item_name )
	local pos_x, pos_y = EntityGetTransform( entity_item )

	local entity_id = GetUpdatedEntityID()

	local orb_id = getInternalVariableValue(entity_id, "OriginalID", "value_int")
	if orb_id ~= nil then
		GameAddFlagRun("ap_orb_" .. orb_id)
	end

	EntityLoad( "data/entities/items/pickup/heart.xml", pos_x, pos_y )

	shoot_projectile( entity_who_picked, "data/entities/particles/image_emitters/orb_effect.xml", pos_x, pos_y, 0, 0 )
	EntityKill( entity_item )
end
