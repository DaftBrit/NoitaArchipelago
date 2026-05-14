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

EntitySetTransform(player, x, y, rotation, scale_x / FACTOR, scale_y / FACTOR)
ComponentSetValue2(char_comp, "collision_aabb_min_x", left / FACTOR)
ComponentSetValue2(char_comp, "collision_aabb_max_x", right / FACTOR)
ComponentSetValue2(char_comp, "collision_aabb_min_y", top / FACTOR)
ComponentSetValue2(char_comp, "collision_aabb_max_y", bottom / FACTOR)

for _,hit_comp in ipairs(hit_comps) do
	local left = ComponentGetValue2(hit_comp, "aabb_min_x")
	local right = ComponentGetValue2(hit_comp, "aabb_max_x")
	local top = ComponentGetValue2(hit_comp, "aabb_min_y")
	local bottom = ComponentGetValue2(hit_comp, "aabb_max_y")
	ComponentSetValue2(hit_comp, "aabb_min_x", left / FACTOR)
	ComponentSetValue2(hit_comp, "aabb_max_x", right / FACTOR)
	ComponentSetValue2(hit_comp, "aabb_min_y", top / FACTOR)
	ComponentSetValue2(hit_comp, "aabb_max_y", bottom / FACTOR)
end

for _,child in ipairs(EntityGetAllChildren(player) or {}) do
	local name = EntityGetName(child)
	if name == "cape" then
		local cape_comp = EntityGetFirstComponentIncludingDisabled(child, "VerletPhysicsComponent")
		if cape_comp ~= nil then
			-- Tracking needed because cape can be deleted by invisible which won't have correct scale then
			local var_comp = EntityGetFirstComponentIncludingDisabled(child, "VariableStorageComponent", "ap_tiny_applied")
			if var_comp == nil then
				var_comp = EntityAddComponent2(child, "VariableStorageComponent", {
					_tags="ap_tiny_applied",
					name="ap_tiny_applied",
					value_int=0
				})
			end
			ComponentSetValue2(var_comp, "value_int", ComponentGetValue2(var_comp, "value_int") + 1)

			local tracker_comp = EntityGetFirstComponentIncludingDisabled(child, "VariableStorageComponent", "ap_tiny_value")
			if tracker_comp == nil then
				local points = ComponentGetValue2(cape_comp, "num_points")
				tracker_comp = EntityAddComponent2(child, "VariableStorageComponent", {
					_tags="ap_tiny_value",
					name="ap_tiny_value",
					value_float=points
				})
			end
			local points_raw = ComponentGetValue2(tracker_comp, "value_float") / FACTOR
			ComponentSetValue2(tracker_comp, "value_float", points_raw)

			ComponentSetValue2(cape_comp, "num_points", math.floor(points_raw))
			ComponentSetValue2(cape_comp, "num_links", math.floor(points_raw) * 2)
		end
	elseif name == "arm_r" then
		local x, y, rotation, scale_x, scale_y = EntityGetTransform(child)
		EntitySetTransform(child, x, y, rotation, scale_x / FACTOR, scale_y / FACTOR)
	end
end
