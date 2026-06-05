local INDICATOR_DISTANCE = 32 -- radius of the ring the blips sit on around the player
local HIDE_WITHIN = 64        -- skip targets you're basically standing on, to avoid clutter
local SPRITE = "data/archipelago/entities/items/icons/ap_logo_radar.png"

local function vec_normalize(x, y)
	local m = math.sqrt(x * x + y * y)
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
	if math.abs(dx) + math.abs(dy) <= HIDE_WITHIN then
		return
	end
	local nx, ny = vec_normalize(dx, dy)
	local ix = pos_x + nx * INDICATOR_DISTANCE
	local iy = pos_y + ny * INDICATOR_DISTANCE
	GameCreateSpriteForXFrames(SPRITE, ix, iy, true, 0, 0, 1, true)
end

for _, target in ipairs(EntityGetWithTag("ap_chest")) do
	point_at(target)
end
for _, target in ipairs(EntityGetWithTag("ap_item")) do
	point_at(target)
end
