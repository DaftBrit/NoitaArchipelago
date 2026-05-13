-- Modified from Nolla Games
dofile_once("data/scripts/lib/utilities.lua")

local break_dist = 256
local sprite_width = 16 -- for accurate scaling (visible pixels only, no margins)

local entity_id = GetUpdatedEntityID()

-- get anchor entities' positions
local v = {} -- x1, y1, x2, y2
local children = EntityGetAllChildren(entity_id)
if children ~= nil and #children > 0 then
	for _,anchor in ipairs(children) do
		if EntityHasTag(anchor, "glue_anchor") then
			local x,y = EntityGetTransform(anchor)
			v[#v+1] = x
			v[#v+1] = y
		end
	end
end

if #v < 4 then
	-- anchor missing
	EntityKill(entity_id)
	return
end

-- angle between anchors for aligning sprite
local dir_x = v[1] - v[3]
local dir_y = v[2] - v[4]
local angle = math.atan(dir_y / dir_x)
local dist = get_magnitude(dir_x, dir_y)

-- break if anchors are too far apart
if dist > break_dist then
	EntityKill(entity_id)
	return
end

-- position & stretch sprite between anchors
local pos_x = (v[1] + v[3]) * 0.5
local pos_y = (v[2] + v[4]) * 0.5
local scale_x = dist / sprite_width
local scale_y = map(dist, 0, break_dist, 1, 0.5)
EntitySetTransform(entity_id, pos_x, pos_y, angle, scale_x, scale_y)

local alpha = map(dist, 0, break_dist, 1, 0.3)
component_write( EntityGetFirstComponent(entity_id, "SpriteComponent" ), { alpha = alpha } )
