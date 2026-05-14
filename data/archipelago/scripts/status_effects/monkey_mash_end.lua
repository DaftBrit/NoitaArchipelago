
local player = EntityGetRootEntity(GetUpdatedEntityID())

local shooter = EntityGetFirstComponentIncludingDisabled(player, "PlatformShooterPlayerComponent")
if shooter == nil then return end

ComponentSetValue2(shooter, "mForceFireOnNextUpdate", false)
