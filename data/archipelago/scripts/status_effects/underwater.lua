

local player = EntityGetRootEntity(GetUpdatedEntityID())

local dmg_comp = EntityGetFirstComponentIncludingDisabled(player, "DamageModelComponent")
if dmg_comp == nil then return end

-- Forces drowning and underwater sfx
ComponentSetValue2(dmg_comp, "mAirDoWeHave", false)
ComponentSetValue2(dmg_comp, "mAirAreWeInWater", true)
ComponentSetValue2(dmg_comp, "air_needed", true)
