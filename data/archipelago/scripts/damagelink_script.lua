local Globals = dofile("data/archipelago/scripts/globals.lua") ---@type Globals

---@param s string?
---@return boolean
function not_empty(s)
	return s ~= nil and s ~= ''
end

---@return string
local function GetAnimalName(entity_id)
	local raw_name = EntityGetFilename(entity_id):match(".*[/\\](.*)%.xml")
	if raw_name ~= nil then
		raw_name = "$animal_" .. raw_name
		local name = GameTextGetTranslatedOrNot(raw_name)
		if name ~= raw_name then
			return name
		end
	end

	local comp = EntityGetFirstComponentIncludingDisabled(entity_id, "GameStatsComponent")
	if comp ~= nil then
		return tostring(ComponentGetValue2(comp, "name"))
	end
	return EntityGetName(entity_id) or ""
end

local function MaybeHasKnockback(entity, projectile_entity, message)
	if projectile_entity ~= nil and projectile_entity ~= 0 then
		local projectile = EntityGetFirstComponent(projectile_entity, "ProjectileComponent")
		if projectile ~= nil then
			if ComponentGetValue2(projectile, "knockback_force") ~= 0 then
				return true
			elseif ComponentObjectGetValue2(projectile, "config_explosion", "knockback_force") ~= 0 then
				return true
			end
			return false
		end
	else
		local animal_ai = EntityGetFirstComponent(entity, "AnimalAIComponent")
		if animal_ai ~= nil and ComponentGetValue2(animal_ai, "attack_knockback_multiplier") ~= 0 then
			return true
		elseif message == "$damage_melee" then
			return false
		end
	end
	if message == "$damage_explosion" then
		return true
	end
	return false
end

---@param damage number
---@param message string
---@param entity_thats_responsible entity_id
---@param is_fatal boolean
---@param projectile_thats_responsible entity_id
function damage_received(damage, message, entity_thats_responsible, is_fatal, projectile_thats_responsible)
	if damage > 0 and not message:match("DamageLink") then
		Globals.DamageLinkQueue:append(damage * MagicNumbersGetValue("GUI_HP_MULTIPLIER"))
	end

	local maybe_has_knockback = MaybeHasKnockback(entity_thats_responsible, projectile_thats_responsible, message)
	if maybe_has_knockback then
		local origin = GetAnimalName(entity_thats_responsible)
		local cause = GameTextGetTranslatedOrNot(message)
		local result = 'Noita'
		if not_empty(origin) and not_empty(cause) then
			if origin:sub(-1) == 's' then
				result = GameTextGet("$menugameover_causeofdeath_killer_cause_name_ends_in_s", origin, cause)
			else
				result = GameTextGet("$menugameover_causeofdeath_killer_cause", origin, cause)
			end
		elseif not_empty(origin) then
			result = origin
		elseif not_empty(cause) then
			result = cause
		end
		Globals.LastDamageCauses:append(result)
	end
end
