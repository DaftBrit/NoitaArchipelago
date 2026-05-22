dofile_once("data/archipelago/scripts/ap_utils.lua")

InitRandomSeed()
-- 1/3 chance of swapping every 5 seconds
if Random(1,3) ~= 1 then return end

local player = EntityGetRootEntity(GetUpdatedEntityID())
local x, y = EntityGetTransform(player)

local targets = EntityGetInRadiusWithTag(x, y, 128, "mortal")
local valid_targets = {}
for _,targ in ipairs(targets) do
	if targ ~= player and not EntityHasTag(targ, "teleportable_NOT") then
		local targ_x, targ_y = EntityGetTransform(targ)
		if not RaytracePlatforms(x, y, targ_x, targ_y) then
			table.insert(valid_targets, targ)
		end
	end
end

if #valid_targets == 0 then return end

local swap_target = valid_targets[Random(1, #valid_targets)]
local targ_x, targ_y = EntityGetTransform(swap_target)

EntitySetTransform(swap_target, x, y)
EntitySetTransform(player, targ_x, targ_y)

EntityAddChild(player, EntityLoad("data/archipelago/entities/misc/effect_teleparticle_instant.xml"))
EntityAddChild(swap_target, EntityLoad("data/archipelago/entities/misc/effect_teleparticle_instant.xml"))

GamePlaySound("data/audio/Desktop/misc.bank", "game_effect/teleport/tick", x, y)
GamePlaySound("data/audio/Desktop/misc.bank", "game_effect/teleport/tick", targ_x, targ_y)
