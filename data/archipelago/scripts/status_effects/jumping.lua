
local player = EntityGetRootEntity(GetUpdatedEntityID())

local character = EntityGetFirstComponentIncludingDisabled(player, "CharacterDataComponent")
if character == nil then return end

local on_ground = ComponentGetValue2(character, "is_on_ground")
if on_ground then
	local vx, vy = ComponentGetValue2(character, "mVelocity")
	ComponentSetValue2(character, "mVelocity", vx, -180)
else
	local vx, vy = ComponentGetValue2(character, "mVelocity")
	if vy < 60 then
		ComponentSetValue2(character, "mVelocity", vx, vy + 0.1)
	end
end