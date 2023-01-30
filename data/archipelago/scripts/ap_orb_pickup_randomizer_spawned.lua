dofile( "data/scripts/game_helpers.lua" )
dofile_once("data/scripts/lib/utilities.lua")

function item_pickup( entity_item, entity_who_picked, item_name )
	local pos_x, pos_y = EntityGetTransform( entity_item )

	--local components = EntityGetComponent( entity_item, "VariableStorageComponent" )
	--local orbcomp = EntityGetComponent( entity_item, "OrbComponent" )
	--local orb_id = -1

	--for key,comp_id in pairs(orbcomp) do
	--	orb_id = ComponentGetValueInt( comp_id, "orb_id" )
	--end
	print("orb has been picked up")

	local biome_name = BiomeMapGetName(pos_x, pos_y)

	print(biome_name)

	local message_title = "$itempickup_orb_discovered"
	local message_desc = "$itempickupdesc_orb_discovered"

	EntityLoad( "data/entities/items/pickup/heart.xml", pos_x, pos_y )

	if( GameHasFlagRun( "boss_centipede_is_dead" ) == false ) then
		local x,y = EntityGetTransform( entity_who_picked )
		local child_id = EntityLoad( "data/entities/misc/orb_boss_scream.xml", x, y )
		EntityAddChild( entity_who_picked, child_id )
	end

	GamePrintImportant( message_title, message_desc )

	shoot_projectile( entity_who_picked, "data/entities/particles/image_emitters/orb_effect.xml", pos_x, pos_y, 0, 0 )
	EntityKill( entity_item )
end