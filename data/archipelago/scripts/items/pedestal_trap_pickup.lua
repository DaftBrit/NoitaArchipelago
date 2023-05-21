dofile_once("data/scripts/lib/utilities.lua")
dofile_once( "data/scripts/buildings/wand_trap.lua" )

function item_pickup( entity_item, entity_who_picked, name )
    local entity_id    = GetUpdatedEntityID()
	local pos_x, pos_y = EntityGetTransform( entity_id )

	if( entity_who_picked == entity_id ) then  return  end

    local entity_tags = EntityGetTags( entity_id )

    if ( string.find( entity_tags, "trap_wand" ) ~= nil ) then
		trigger_wand_pickup_trap( pos_x, pos_y )
	end

end