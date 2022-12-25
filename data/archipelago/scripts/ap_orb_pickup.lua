dofile( "data/scripts/game_helpers.lua" )
dofile_once("data/scripts/lib/utilities.lua")

function item_pickup( entity_item, entity_who_picked, item_name )
	local pos_x, pos_y = EntityGetTransform( entity_item )
	
	local components = EntityGetComponent( entity_item, "VariableStorageComponent" )
	local orbcomp = EntityGetComponent( entity_item, "OrbComponent" )
	local orb_id = -1

	-- todo: change this to be an incrementing list somehow

	local orbs = GetGameOrbCountThisRun()


	local message_title = ""
	local message_desc = ""

	if( GameHasFlagRun( "boss_centipede_is_dead" ) == false ) then
		local x,y = EntityGetTransform( entity_who_picked )
		local child_id = EntityLoad( "data/entities/misc/orb_boss_scream.xml", x, y )
		EntityAddChild( entity_who_picked, child_id )
	end
	
	GamePrintImportant( message_title, message_desc )
	
	shoot_projectile( entity_who_picked, "data/entities/particles/image_emitters/orb_effect.xml", pos_x, pos_y, 0, 0 )
	EntityKill( entity_item )
end