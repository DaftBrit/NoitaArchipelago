local FADE_DISTANCE = 80 * 80
local entity_id = GetUpdatedEntityID()


local function dist2(x1, y1, x2, y2)
	local dx = x2 - x1
	local dy = y2 - y1
	return dx * dx + dy * dy
end

function init(entity_id)
	local text_desc = GameTextGetTranslatedOrNot("$ap_closed_portal_desc")

	local gui = GuiCreate()
	local width = GuiGetTextDimensions(gui, text_desc, 0.5)
	GuiDestroy(gui)

	local text_component = EntityGetFirstComponentIncludingDisabled(entity_id, "SpriteComponent", "locked_by_archipelago")
	assert(text_component)

	ComponentSetValue2(text_component, "text", text_desc)
	ComponentSetValue2(text_component, "offset_x", math.floor(width))
end

local function update()
	local text_component = EntityGetFirstComponent(entity_id, "SpriteComponent", "locked_by_archipelago")
	if not text_component then return end

	local cam_x, cam_y = GameGetCameraPos()
	local entity_x, entity_y = EntityGetTransform(entity_id)

	local sq_dist = dist2(entity_x, entity_y, cam_x, cam_y)
	local fade = math.min(sq_dist, FADE_DISTANCE) / FADE_DISTANCE

	local alpha = ((1 - fade) * 0.75) ^ 3
	ComponentSetValue2(text_component, "alpha", alpha)
end

update()
