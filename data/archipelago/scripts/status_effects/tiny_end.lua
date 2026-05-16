local player = EntityGetRootEntity(GetUpdatedEntityID())

local x, y, rotation, scale_x, scale_y = EntityGetTransform(player)

local char_comp = EntityGetFirstComponentIncludingDisabled(player, "CharacterDataComponent")
local hit_comps = EntityGetComponentIncludingDisabled(player, "HitboxComponent") or {}
if char_comp == nil then return end

local left = ComponentGetValue2(char_comp, "collision_aabb_min_x")
local right = ComponentGetValue2(char_comp, "collision_aabb_max_x")
local top = ComponentGetValue2(char_comp, "collision_aabb_min_y")
local bottom = ComponentGetValue2(char_comp, "collision_aabb_max_y")

local FACTOR = 3

local function trace_shift_x(x_offset, y_offset)
	local hit, hit_x = RaytracePlatforms(x + x_offset, y + y_offset * FACTOR, x + x_offset * FACTOR, y + y_offset * FACTOR)
	if hit then
		x = x - (x + x_offset * FACTOR - hit_x)
	end
end

local function trace_shift_y(x_offset, y_offset)
	local hit, _, hit_y = RaytracePlatforms(x + x_offset * FACTOR, y + y_offset, x + x_offset * FACTOR, y + y_offset * FACTOR)
	if hit then
		y = y - (y + y_offset * FACTOR - hit_y)
	end
end

trace_shift_y(0, top)
trace_shift_y(left, top)
trace_shift_y(right, top)
trace_shift_y(0, bottom)
trace_shift_y(left, bottom)
trace_shift_y(right, bottom)
trace_shift_x(left, 0)
trace_shift_x(left, top)
trace_shift_x(left, bottom)
trace_shift_x(right, 0)
trace_shift_x(right, top)
trace_shift_x(right, bottom)

EntitySetTransform(player, x, y, rotation, scale_x * FACTOR, scale_y * FACTOR)
ComponentSetValue2(char_comp, "collision_aabb_min_x", left * FACTOR)
ComponentSetValue2(char_comp, "collision_aabb_max_x", right * FACTOR)
ComponentSetValue2(char_comp, "collision_aabb_min_y", top * FACTOR)
ComponentSetValue2(char_comp, "collision_aabb_max_y", bottom * FACTOR)

for _,hit_comp in ipairs(hit_comps) do
	local left = ComponentGetValue2(hit_comp, "aabb_min_x")
	local right = ComponentGetValue2(hit_comp, "aabb_max_x")
	local top = ComponentGetValue2(hit_comp, "aabb_min_y")
	local bottom = ComponentGetValue2(hit_comp, "aabb_max_y")
	ComponentSetValue2(hit_comp, "aabb_min_x", left * FACTOR)
	ComponentSetValue2(hit_comp, "aabb_max_x", right * FACTOR)
	ComponentSetValue2(hit_comp, "aabb_min_y", top * FACTOR)
	ComponentSetValue2(hit_comp, "aabb_max_y", bottom * FACTOR)
end

for _,child in ipairs(EntityGetAllChildren(player) or {}) do
	local name = EntityGetName(child)
	if name == "cape" then
		local cape_comp = EntityGetFirstComponentIncludingDisabled(child, "VerletPhysicsComponent")
		local var_comp = EntityGetFirstComponentIncludingDisabled(child, "VariableStorageComponent", "ap_tiny_applied")
		local tracker_comp = EntityGetFirstComponentIncludingDisabled(child, "VariableStorageComponent", "ap_tiny_value")
		if cape_comp ~= nil and var_comp ~= nil and tracker_comp ~= nil then
			local num_times = ComponentGetValue2(var_comp, "value_int")
			if num_times <= 0 then
				EntityRemoveComponent(child, var_comp)
				goto continue
			elseif num_times == 1 then
				EntityRemoveComponent(child, var_comp)
			else
				ComponentSetValue2(var_comp, "value_int", num_times - 1)
			end

			local points_raw = ComponentGetValue2(tracker_comp, "value_float") * FACTOR
			ComponentSetValue2(tracker_comp, "value_float", points_raw)

			ComponentSetValue2(cape_comp, "num_points", math.floor(points_raw))
			ComponentSetValue2(cape_comp, "num_links", math.floor(points_raw) * 2)
		end
	elseif name == "arm_r" then
		local x, y, rotation, scale_x, scale_y = EntityGetTransform(child)
		EntitySetTransform(child, x, y, rotation, scale_x * FACTOR, scale_y * FACTOR)
	end

	::continue::
end
