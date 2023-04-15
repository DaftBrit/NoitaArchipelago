local function ap_extend_forge_item_convert()
	local entity_id = GetUpdatedEntityID()
	local pos_x, pos_y = EntityGetTransform(entity_id)
	local converted = false
	for _, id in pairs(EntityGetInRadiusWithTag(pos_x, pos_y, 70, "tablet")) do
		if EntityGetRootEntity(id) == id then
			local x, y = EntityGetTransform(id)
			local item_comps = EntityGetComponent( id, "ItemComponent" )
			local new_desc = ""
			local item_name

			if ( item_comps ~= nil ) then
				for _, itemc in ipairs(item_comps) do
					item_name = ComponentGetValue( itemc, "item_name" )

					if( item_name == "$ap_error_book_title" ) then new_desc = "$ap_error_book_desc_forged" end
				end
			end
			if( new_desc ~= "" ) then
				local forged_book = EntityLoad("data/entities/items/books/base_forged.xml", x, y - 5)
				item_comps = EntityGetComponent( forged_book, "ItemComponent" )
				if ( item_comps ~= nil ) then
					for _, itemc in ipairs(item_comps) do
						ComponentSetValue( itemc, "item_name", item_name )
						ComponentSetValue( itemc, "ui_description", new_desc )
					end
				end

				local uiinfo_comp = EntityGetComponent( forged_book, "UIInfoComponent" )
				if( uiinfo_comp ~= nil ) then
					for _, uiinfoc in ipairs(uiinfo_comp) do
						ComponentSetValue( uiinfoc, "name", item_name )
					end
				end

				local ability_comp = EntityGetComponent( forged_book, "AbilityComponent" )
				if( ability_comp ~= nil ) then
					for _, abic in ipairs(ability_comp) do
						ComponentSetValue( abic, "ui_name", item_name )
					end
				end

				EntityLoad("data/entities/projectiles/explosion.xml", x, y - 10)
				EntityKill(id)
			end
		converted = true
		end
	end
	if converted then
		GameTriggerMusicFadeOutAndDequeueAll( 3.0 )
		GameTriggerMusicEvent( "music/oneshot/dark_01", true, pos_x, pos_y )
	end
end

ap_extend_forge_item_convert()
