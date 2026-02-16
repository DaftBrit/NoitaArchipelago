local Log = dofile_once("data/archipelago/scripts/logger.lua") --- @type Logger
local Dmg = dofile_once("data/archipelago/lib/damage_types.lua") --- @type DamageTypes
local Animals = dofile_once("data/archipelago/entities/animals/animal_list_vanilla.lua") --- @type AnimalList
local Globals = dofile("data/archipelago/scripts/globals.lua") --- @type Globals

---@param entity_id entity_id
---@return boolean
local function IsValidEntity(entity_id)
	return entity_id ~= nil and entity_id ~= 0
end

---Returns true if an entity or any one child of the entity belongs to the player faction or is charmed.
---@param entity_id entity_id
---@return boolean
local function IsEntityOwned(entity_id)
	local genome = EntityGetFirstComponentIncludingDisabled(entity_id, "GenomeDataComponent")
	if genome ~= nil then
		local herd_id = ComponentGetValue2(genome, "herd_id") or -1
		local herd_name = HerdIdToString(herd_id)
		-- Necromancy uses the helpless faction
		if herd_name == "player" or herd_name == "helpless" then return true end
	end

	for _, comp in ipairs(EntityGetComponent(entity_id, "GameEffectComponent") or {}) do
		if ComponentGetValue2(comp, "effect") == "CHARM" then return true end
	end

	for _, child in ipairs(EntityGetAllChildren(entity_id) or {}) do
		return IsEntityOwned(child)
	end
	return false
end

local function IsFogRevealedForCredit()
	-- Not visible
	local kill_credit = tostring(ModSettingGet("archipelago.kills_in_fog") or "no")
	if kill_credit == "no" then
		local entity_id = GetUpdatedEntityID()
		local x, y = EntityGetTransform(entity_id)
		if GameGetFogOfWar(x, y) > 250 then return false end
	end
	return true
end

---@param entity_thats_responsible entity_id
---@return bool
local function IsPlayerKill(damage_type_bit_field, entity_thats_responsible)
	local kill_credit = tostring(ModSettingGet("archipelago.kill_credit") or "rules")

	if kill_credit ~= "everything" then
		if IsValidEntity(entity_thats_responsible) then
			-- Obvious credit, killed by us
			if EntityHasTag(entity_thats_responsible, "player_unit") then return true end
			if kill_credit == "restricted" then return false end

			if EntityHasTag(entity_thats_responsible, "polymorphed_player") then return true end
			if EntityHasTag(entity_thats_responsible, "polymorphed_cessation") then return true end

			-- Killed by a charmed enemy or perk
			if IsEntityOwned(entity_thats_responsible) then return true end

			-- Killed by sadekivi
			if EntityGetFilename(entity_thats_responsible) == "data/entities/misc/beam_from_sky.xml" then return true end

			-- Killed by something else
			return false
		elseif kill_credit == "restricted" then
			return false
		end

		-- Most likely died naturally instead of by an attack
		if bit.band(damage_type_bit_field, Dmg.DAMAGE_FIRE) then return false end
		if bit.band(damage_type_bit_field, Dmg.DAMAGE_MATERIAL) then return false end
		if bit.band(damage_type_bit_field, Dmg.DAMAGE_DROWNING) then return false end
	end

	-- Visible enemy died maybe from physics damage or something
	return IsFogRevealedForCredit()
end

---@return string
local function GetAnimalName()
	local entity_id = GetUpdatedEntityID()

	local comp = EntityGetFirstComponentIncludingDisabled(entity_id, "GameStatsComponent") or {}
	if comp then
		return tostring(ComponentGetValue2(comp, "name"))
	end
	return ""
end

---@param name string
local function CountKill(name)
	local location_id = Animals.KillToLocationId[name]
	if not GameHasFlagRun("ap_killsanity_" .. name) then
		GameAddFlagRun("ap_killsanity_" .. name)
		if location_id == nil then
			Log.Warn("Killsanity not supported for: " .. name)
			return
		else
			Log.Info("Counting killsanity kill for: " .. name)
		end
	end

	if Globals.MissingLocationsSet:has_key(location_id) then
		GameAddFlagRun("ap" .. location_id)
		Globals.LocationUnlockQueue:append(location_id)
		Globals.MissingLocationsSet:remove_key(location_id)
	end
end

---@param damage_type_bit_field integer
---@param damage_message string
---@param entity_thats_responsible entity_id
---@param drop_items bool
function death(damage_type_bit_field, damage_message, entity_thats_responsible, drop_items )
	local name = GetAnimalName()
	if name == "" then return end

	if IsPlayerKill(damage_type_bit_field, entity_thats_responsible) then
		CountKill(name)
	elseif not GameHasFlagRun("ap_killsanity_" .. name) then
		if IsValidEntity(entity_thats_responsible) then
			local log_str = string.format("%s died: %s [%08X] killed by %s", name, damage_message, damage_type_bit_field, EntityGetName(entity_thats_responsible))
			Log.Info(log_str)
		else
			local log_str = string.format("%s died: %s [%08X]", name, damage_message, damage_type_bit_field)
			Log.Info(log_str)
		end
	end
end
