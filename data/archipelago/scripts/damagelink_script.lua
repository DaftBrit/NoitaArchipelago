local Globals = dofile("data/archipelago/scripts/globals.lua") ---@type Globals

---@param damage number
---@param message string
---@param entity_thats_responsible entity_id
---@param is_fatal boolean
---@param projectile_thats_responsible entity_id
function damage_received(damage, message, entity_thats_responsible, is_fatal, projectile_thats_responsible)
	if damage > 0 and not message:match("DamageLink") then
		Globals.DamageLinkQueue:append(damage * MagicNumbersGetValue("GUI_HP_MULTIPLIER"))
	end
end
