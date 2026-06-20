function collision_trigger(colliding_entity_id)
	if EntityGetFirstComponentIncludingDisabled(colliding_entity_id, "LuaComponent", "ap_bananapeel_script") ~= nil then
		return
	end

	EntityAddComponent2(colliding_entity_id, "LuaComponent", {
		_tags = "ap_bananapeel_script",
		script_source_file = "data/archipelago/entities/bananapeel/slip.lua",
		execute_every_n_frame = 1,
	})
	LoadGameEffectEntityTo(colliding_entity_id, "data/archipelago/entities/bananapeel/stun_effect.xml")

	local x, y = EntityGetTransform(colliding_entity_id)
	GamePlaySound("data/audio/Desktop/player.bank", "player/land_slime", x, y)
end
