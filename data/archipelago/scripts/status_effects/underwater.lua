

local player = EntityGetRootEntity(GetUpdatedEntityID())

local dmg_comp = EntityGetFirstComponentIncludingDisabled(player, "DamageModelComponent")
if dmg_comp == nil then return end

-- Forces drowning
ComponentSetValue2(dmg_comp, "mAirDoWeHave", false)
