
if DriftDir == nil then
	SetRandomSeed(GameGetFrameNum(), 0)
	DriftDir = Randomf(0.5, 2)
	if Random(1) == 0 then
		DriftDir = -DriftDir
	end
end

local player = EntityGetRootEntity(GetUpdatedEntityID())
if player == nil then return end

local controller = EntityGetFirstComponentIncludingDisabled(player, "CharacterDataComponent")
if controller == nil then return end

local vx, vy = ComponentGetValue2(controller, "mVelocity")
ComponentSetValue2(controller, "mVelocity", vx + DriftDir, vy)
