dofile_once("data/archipelago/scripts/ap_utils.lua")

local entity = GetUpdatedEntityID()
local x, y = EntityGetTransform(entity)

local physics_comp = EntityGetFirstComponentIncludingDisabled(entity, "PhysicsBody2Component")
if physics_comp == nil then return end
local phys_x, phys_y, angle, phys_vx, phys_vy, angular_vel = PhysicsComponentGetTransform(physics_comp)


---@enum
local STATE = {
	WAIT = 0,
	UP = 1,
	DOWN = 2,
}

if Self == nil then
	Self = {
		prev = {
			x = 0,
			y = 0,
			phys_x = 0,
			phys_y = 0,
			phys_vx = 0,
			phys_vy = 0,
		},
		state = STATE.WAIT,
		last_update_frame = GameGetFrameNum(),
		last_moved_frame = GameGetFrameNum(),
	}
end

---@param state integer
local function set_state(state)
	Self.state = state
	Self.last_update_frame = GameGetFrameNum()
end

---@return integer frames since last state change
local function elapsed()
	return GameGetFrameNum() - Self.last_update_frame
end

---@return boolean
local function is_stopped_frame()
	if x ~= Self.prev.x or y ~= Self.prev.y then return false end
	if phys_x ~= Self.prev.phys_x or phys_y ~= Self.prev.phys_y then return false end
	if phys_vx ~= Self.prev.phys_vx or phys_vy ~= Self.prev.phys_vy then return false end
	return true
end

local function update_prev_values()
	Self.prev.x = x
	Self.prev.y = y
	Self.prev.phys_x = phys_x
	Self.prev.phys_y = phys_y
	Self.prev.phys_vx = phys_vx
	Self.prev.phys_vy = phys_vy
end

local function get_x_vel()
	local targ_x = get_spawn_position()
	if targ_x < x then
		return -6
	end
	return 6
end

if not is_stopped_frame() then
	Self.last_moved_frame = GameGetFrameNum()
end

---@return boolean
local function is_stopped()
	return GameGetFrameNum() - Self.last_moved_frame > 16
end


if Self.state == STATE.WAIT then
	-- Lock in place (but allow gravity)
	if phys_vy < 0 then phys_vy = 0 end
	phys_vx = 0
	PhysicsComponentSetTransform(physics_comp, phys_x, phys_y, angle, phys_vx, phys_vy, angular_vel)

	if elapsed() > 90 then
		set_state(STATE.UP)

		phys_vx = get_x_vel()
		phys_vy = -20
		PhysicsComponentSetTransform(physics_comp, phys_x, phys_y, angle, phys_vx, phys_vy, angular_vel)
	end
elseif Self.state == STATE.UP then
	-- Don't interrupt horizontal movement
	phys_vx = Self.prev.phys_vx
	PhysicsComponentSetTransform(physics_comp, phys_x, phys_y, angle, phys_vx, phys_vy, angular_vel)

	if phys_vy >= 0 then
		set_state(STATE.DOWN)
	elseif is_stopped() then
		set_state(STATE.WAIT)
	end
elseif Self.state == STATE.DOWN then
	-- Don't interrupt horizontal movement when going down
	if phys_vy > 2 then
		phys_vx = Self.prev.phys_vx
	end
	-- Don't go back up in down state until stopped
	if phys_vy < 0 then phys_vy = 0 end
	PhysicsComponentSetTransform(physics_comp, phys_x, phys_y, angle, phys_vx, phys_vy, angular_vel)

	if is_stopped() then
		set_state(STATE.WAIT)
	end
end

update_prev_values()
