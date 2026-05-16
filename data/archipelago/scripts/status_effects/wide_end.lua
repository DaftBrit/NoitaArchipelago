local player = EntityGetRootEntity(GetUpdatedEntityID())

local var_comp = EntityGetFirstComponentIncludingDisabled(GetUpdatedEntityID(), "VariableStorageComponent", "factor")
if not var_comp then return end
local FACTOR = ComponentGetValue2(var_comp, "value_float")

local x, y, rotation, scale_x, scale_y = EntityGetTransform(player)

local char_comp = EntityGetFirstComponentIncludingDisabled(player, "CharacterDataComponent")
local hit_comps = EntityGetComponentIncludingDisabled(player, "HitboxComponent") or {}
if char_comp == nil then return end

local left = ComponentGetValue2(char_comp, "collision_aabb_min_x")
local right = ComponentGetValue2(char_comp, "collision_aabb_max_x")

EntitySetTransform(player, x, y, rotation, scale_x / FACTOR, scale_y)
ComponentSetValue2(char_comp, "collision_aabb_min_x", left / FACTOR)
ComponentSetValue2(char_comp, "collision_aabb_max_x", right / FACTOR)

for _,hit_comp in ipairs(hit_comps) do
	local left = ComponentGetValue2(hit_comp, "collision_aabb_min_x")
	local right = ComponentGetValue2(hit_comp, "collision_aabb_max_x")
	ComponentSetValue2(hit_comp, "collision_aabb_min_x", left / FACTOR)
	ComponentSetValue2(hit_comp, "collision_aabb_max_x", right / FACTOR)
end
