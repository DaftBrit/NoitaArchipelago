local function ap_swap_sampo_script()
	local entity_id = GetUpdatedEntityID()
	local lua_comps = EntityGetComponent(entity_id, "LuaComponent", "enabled_in_world")
	for _, comp in pairs(lua_comps) do
		local script = ComponentGetValue2(comp, "script_source_file")
		if script == "data/entities/animals/boss_centipede/ending/sampo_start_ending_sequence.lua" then
			ComponentSetValue2(comp, "script_source_file", "data/archipelago/scripts/patches/ap_extend_ending.lua")
		end
	end
end

ap_swap_sampo_script()
