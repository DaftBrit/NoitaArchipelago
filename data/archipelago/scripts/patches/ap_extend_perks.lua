

-- Re-add these if we are not v2
local ARCHIPELAGO_V2_PERKS = {
	EXTRA_PERK = 1,
	SAVING_GRACE = 1,
	TRICK_BLOOD_MONEY = 1,
	NO_MORE_KNOCKBACK = 1,
	MANA_FROM_KILLS = 1,
	RADAR_ENEMY = 1,
	IRON_STOMACH = 1,
	WAND_RADAR = 1,
	ITEM_RADAR = 1,
	ADVENTURER = 1,
	ABILITY_ACTIONS_MATERIALIZED = 1,
	UNLIMITED_SPELLS = 1,
}

local perk_get_spawn_order_old = perk_get_spawn_order
function perk_get_spawn_order(ignore_these_)
	if not GameHasFlagRun("ap_version_2") then
		for _, perk in ipairs(perk_list) do
			if ARCHIPELAGO_V2_PERKS[perk.id] ~= nil then
				perk.not_in_default_perk_pool = nil
			end
		end
	end
	return perk_get_spawn_order_old(ignore_these_)
end
