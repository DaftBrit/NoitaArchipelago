dofile_once( "data/scripts/game_helpers.lua" )
dofile_once("data/scripts/lib/utilities.lua")

function item_pickup( entity_item, entity_who_picked, item_name )
	local pos_x, pos_y = EntityGetTransform( entity_item )
	local message_title = "$itempickup_orb_discovered"
	local message_desc = "$itempickupdesc_orb_discovered"

	local orb_count = GameGetOrbCountThisRun()

	-- if you reach your goal amount and there are orbs on the ground still, remove their orb components so you don't go over your goal amount
	if (GameHasFlagRun("ap_peaceful_goal") and orb_count >= 33) or (GameHasFlagRun("ap_pure_goal") and orb_count >= 11) then
		local orb_comp = EntityGetFirstComponent(entity_item, "OrbComponent")
		if orb_comp then
			EntityRemoveComponent(entity_item, orb_comp)
		end
	end

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
