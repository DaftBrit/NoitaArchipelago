local INDICATOR_DISTANCE = 32 -- radius of the ring the blips sit on around the player
local HIDE_WITHIN = INDICATOR_DISTANCE ^ 2        -- skip targets you're basically standing on, to avoid clutter
local RANGE = 400 ^ 2

local function dist_sq(x, y)
	return x * x + y * y
end

local function vec_normalize(x, y)
	local m = math.sqrt(dist_sq(x, y))
	if m == 0 then
		return 0, 0
	end
	return x / m, y / m
end

local entity_id = GetUpdatedEntityID()
local pos_x, pos_y = EntityGetTransform(entity_id)
pos_y = pos_y - 4 -- offset to the player's middle

local function point_at(target)
	local tx, ty = EntityGetTransform(target)
	local dx, dy = tx - pos_x, ty - pos_y
	local distance = dist_sq(dx, dy)
	if distance <= HIDE_WITHIN then
		return
	end

	local nx, ny = vec_normalize(dx, dy)
	local ix = pos_x + nx * INDICATOR_DISTANCE
	local iy = pos_y + ny * INDICATOR_DISTANCE

	if distance > RANGE * 0.5 then
		GameCreateSpriteForXFrames("data/archipelago/entities/items/icons/ap_logo_radar_faint.png", ix, iy, true, 0, 0, 1, true)
	elseif distance > RANGE * 0.2 then
		GameCreateSpriteForXFrames("data/archipelago/entities/items/icons/ap_logo_radar_medium.png", ix, iy, true, 0, 0, 1, true)
	else
		GameCreateSpriteForXFrames("data/archipelago/entities/items/icons/ap_logo_radar_strong.png", ix, iy, true, 0, 0, 1, true)
	end
end

for _, target in ipairs(EntityGetWithTag("ap_chest")) do
	point_at(target)
end
for _, target in ipairs(EntityGetWithTag("ap_item")) do
	point_at(target)
end
