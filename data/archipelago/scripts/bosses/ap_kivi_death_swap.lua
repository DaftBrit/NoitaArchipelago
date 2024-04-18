local function APKiviDeathSwap()
    local entity_id = GetUpdatedEntityID()
	local lua_comps = EntityGetComponent(entity_id, "LuaComponent")

	for _, comp in pairs(lua_comps) do
		local script = ComponentGetValue2(comp, "script_death")
		if script == "data/entities/animals/boss_sky/boss_sky.lua" then
			ComponentSetValue2(comp, "script_death", "data/archipelago/scripts/bosses/ap_kivi_death.lua")
		end
	end
end

APKiviDeathSwap()
