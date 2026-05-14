local player = EntityGetRootEntity(GetUpdatedEntityID())

local x, y, rotation, scale_x, scale_y = EntityGetTransform(player)

local char_comp = EntityGetFirstComponentIncludingDisabled(player, "CharacterDataComponent")
local hit_comps = EntityGetComponentIncludingDisabled(player, "HitboxComponent") or {}
if char_comp == nil then return end

local left = ComponentGetValue2(char_comp, "collision_aabb_min_x")
local right = ComponentGetValue2(char_comp, "collision_aabb_max_x")
local top = ComponentGetValue2(char_comp, "collision_aabb_min_y")
local bottom = ComponentGetValue2(char_comp, "collision_aabb_max_y")

local FACTOR = (right - left + 12) / (right - left)
local var_comp = EntityGetFirstComponentIncludingDisabled(GetUpdatedEntityID(), "VariableStorageComponent", "factor")
if not var_comp then return end
ComponentSetValue2(var_comp, "value_float", FACTOR)

local function trace_shift(x_offset, y_offset)
	local hit, hit_x = RaytracePlatforms(x + x_offset, y + y_offset, x + x_offset * FACTOR, y + y_offset)
	if hit then
		x = x - (x + x_offset * FACTOR - hit_x)
	end
end

trace_shift(left, 0)
trace_shift(left, top)
trace_shift(left, bottom)
trace_shift(right, 0)
trace_shift(right, top)
trace_shift(right, bottom)

EntitySetTransform(player, x, y, rotation, scale_x * FACTOR, scale_y)
ComponentSetValue2(char_comp, "collision_aabb_min_x", left * FACTOR)
ComponentSetValue2(char_comp, "collision_aabb_max_x", right * FACTOR)

for _,hit_comp in ipairs(hit_comps) do
	local left = ComponentGetValue2(hit_comp, "collision_aabb_min_x")
	local right = ComponentGetValue2(hit_comp, "collision_aabb_max_x")
	ComponentSetValue2(hit_comp, "collision_aabb_min_x", left * FACTOR)
	ComponentSetValue2(hit_comp, "collision_aabb_max_x", right * FACTOR)
end
