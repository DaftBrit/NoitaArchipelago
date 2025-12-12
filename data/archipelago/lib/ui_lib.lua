--- @enum ui_options
local options = {
	None = 0,

	IsDraggable = 1,
	NonInteractive = 2,
	AlwaysClickable = 3,
	ClickCancelsDoubleClick = 4,
	IgnoreContainer = 5,
	NoPositionTween = 6,
	ForceFocusable = 7,
	HandleDoubleClickAsClick = 8,
	GamepadDefaultWidget = 9,

	Layout_InsertOutsideLeft = 10,
	Layout_InsertOutsideRight = 11,
	Layout_InsertOutsideAbove = 12,
	Layout_ForceCalculate = 13,
	Layout_NextSameLine = 14,
	Layout_NoLayouting = 15,

	Align_HorizontalCenter = 16,
	Align_Left = 17,

	FocusSnapToRightEdge = 18,

	NoPixelSnapY = 19,

	DrawAlwaysVisible = 20,
	DrawNoHoverAnimation = 21,
	DrawWobble = 22,
	DrawFadeIn = 23,
	DrawScaleIn = 24,
	DrawWaveAnimateOpacity = 25,
	DrawSemiTransparent = 26,
	DrawActiveWidgetCursorOnBothSides = 27,
	DrawActiveWidgetCursorOff = 28,

	TextRichRendering = 29,

	NoSound = 47,
	Hack_ForceClick = 48,
	Hack_AllowDuplicateIds = 49,

	ScrollContainer_Smooth = 50,
	IsExtraDraggable = 51,

	_SnapToCenter = 62,
	Disabled = 63,
}
---@enum mouse_keys
local mouse = {
	lc = 1,
	rc = 2,
	mc = 3,
	wheel_up = 4,
	wheel_down = 5,
}

---@enum keyboard_keys
local keyboard = {
	enter = 40,
	escape = 41,
	space = 44,
	home = 74,
	pageup = 75,
	_end = 77,
	pagedown = 78,
	right = 79,
	left = 80,
	down = 81,
	up = 82,
	lshift = 225,
}

---@class keycodes
local keycodes = {
	mouse = mouse,
	keyboard = keyboard,
}

--- @class UI_const
--- @field empty string empty png, 20x20
--- @field default_9piece string default 9piece
--- @field px string white pixel, 1x1
--- @field codes keycodes
local const = {
	empty = "data/ui_gfx/empty.png",
	default_9piece = "data/ui_gfx/decorations/9piece0_gray.png",
	px = "data/ui_gfx/1px_white.png", -- white pixel
	codes = keycodes,
	options = options,
}

--- @class (exact) UI_dimensions
--- @field x number
--- @field y number

--- @class (exact) gui_tooltip_size_cache
--- @field width number
--- @field height number
--- @field x_offset number
--- @field y_offset number

---@class scrollbox_vars
---@field scroll_img string
---@field scroll_img_hl string
---@field y number

--- @class UI_class
--- @field protected gui gui
--- @field private gui_tooltip gui
--- @field protected gui_id number
--- @field private gui_longest_string_cache table
--- @field private __index UI_class
--- @field private gui_tooltip_size_cache gui_tooltip_size_cache
--- @field private tooltip_z number
--- @field private tooltip_gui_id number
--- @field private animation_id number
--- @field private tooltip_animation_id number
--- @field public tooltip_margin number
--- @field public tooltip_img string
--- @field protected tooltip_reset boolean
--- @field private tooltip_previous? table
--- @field protected c UI_const constants
--- @field protected dim UI_dimensions
--- @field protected scroll scrollbox_vars
--- @field protected buttons {img:string, img_hl:string}
--- @field private scrollboxes {[string]:ui_fake_scroll}
--- @field private last_scrollbox ui_fake_scroll|nil
local ui_class = {
	c = const,
	dim = {
		x = 640,
		y = 360,
	},
	gui_id = 100000,
	tooltip_gui_id = 1000,
	gui_longest_string_cache = setmetatable({}, { __mode = "k" }),
	gui_tooltip_size_cache = setmetatable({}, { __mode = "k" }),
	tooltip_z = -10000,
	tooltip_reset = true,
	tooltip_previous = nil,
	tooltip_margin = 5,
	tooltip_animation_id = 100,
	tooltip_img = "data/ui_gfx/decorations/9piece0_gray.png",
	scroll = {
		y = 0,
		scroll_img = "data/ui_gfx/decorations/9piece0_gray.png",
		scroll_img_hl = "data/ui_gfx/decorations/9piece0.png",
	},
	scrollboxes = {},
	last_scrollbox = nil,
	buttons = {
		img = "data/ui_gfx/decorations/9piece0_gray.png",
		img_hl = "data/ui_gfx/decorations/9piece0.png",
	},
}
ui_class.__index = ui_class

--- Creates a new UI instance
--- @return UI_class
function ui_class:New()
	local o = {
		gui = GuiCreate(),
		gui_tooltip = GuiCreate(),
	}
	setmetatable(o, self)
	return o
end

-- ############################################
-- #########		FUNCTIONALS		###########
-- ############################################

--- Creates an invisible scrollbox to block clicks and scrolls
--- @protected
function ui_class:BlockInput()
	GuiIdPushString(self.gui, "STOP_FLICKERING_SCROLLBAR")
	local m_x, m_y = self:get_mouse_pos()
	GuiAnimateBegin(self.gui)
	GuiAnimateAlphaFadeIn(self.gui, 2, 0, 0, true)
	GuiOptionsAddForNextWidget(self.gui, self.c.options.AlwaysClickable)
	GuiBeginScrollContainer(self.gui, 2, m_x - 25, m_y - 25, 50, 50, false, 0, 0)
	GuiAnimateEnd(self.gui)
	GuiEndScrollContainer(self.gui)
	GuiIdPop(self.gui)
end

--- Returns true if left mouse was clicked
--- @protected
--- @return boolean
--- @nodiscard
function ui_class:IsLeftClicked()
	return InputIsMouseButtonJustDown(self.c.codes.mouse.lc)
end

--- Returns true if right mouse was clicked
--- @protected
--- @return boolean
--- @nodiscard
function ui_class:IsRightClicked()
	return InputIsMouseButtonJustDown(self.c.codes.mouse.rc)
end

--- Returns true if right or left mouse was clicked
--- @protected
--- @return boolean
--- @nodiscard
function ui_class:IsMouseClicked()
	return self:IsLeftClicked() or self:IsRightClicked()
end

--- Returns true if enter, escape or space was pressed
--- @protected
--- @return boolean
--- @nodiscard
function ui_class:IsControlCharsPressed()
	return InputIsKeyJustDown(self.c.codes.keyboard.enter)
		or InputIsKeyDown(self.c.codes.keyboard.escape)
		or InputIsKeyDown(self.c.codes.keyboard.space)
end

--- Draws a button with text
--- @param x number
--- @param y number
--- @param z number
--- @param text string
--- @param tooltip_text string
--- @return boolean
--- @nodiscard
function ui_class:IsButtonClicked(x, y, z, text, tooltip_text)
	self:DrawButton(x, y, z, text, true)
	if self:IsHovered() then
		self:ShowTooltipTextCenteredX(0, 22, tooltip_text)
		return self:IsMouseClicked()
	end
	return false
end

--- Draws a disablable button with text
--- @param x number
--- @param y number
--- @param z number
--- @param text string
--- @param tooltip_text string
--- @param active boolean
--- @param inactive_tooltip_text? string
--- @return boolean
--- @nodiscard
function ui_class:IsDisablableButtonClicked(x, y, z, text, tooltip_text, active, inactive_tooltip_text)
	if active then return self:IsButtonClicked(x, y, z, text, tooltip_text) end
	self:DrawButton(x, y, z, text, false)
	if inactive_tooltip_text and self:IsHovered() then self:ShowTooltipTextCenteredX(1, 20, inactive_tooltip_text) end
	return false
end

--- Returns true if previous widget is hovered
--- @protected
--- @return boolean
--- @nodiscard
function ui_class:IsHovered()
	local _, _, hovered = GuiGetPreviousWidgetInfo(self.gui)
	return hovered
end

--- Draws a invisible nine piece as a hoverbox, returns true if hovered
--- @protected
--- @param x number
--- @param y number
--- @param width number
--- @param height number
--- @param dont_focus? boolean
--- @return boolean
--- @nodiscard
function ui_class:IsHoverBoxHovered(x, y, width, height, dont_focus)
	if not dont_focus then self:AddOptionForNext(self.c.options.ForceFocusable) end
	self:Draw9Piece(x, y, -10000, width, height, self.c.empty, self.c.empty)
	return self:IsHovered()
end

-- ############################################
-- #########		TOOLTIPS		###########
-- ############################################

--- Calculate y offset needed to not go over the screen
--- @private
--- @param y number
--- @param h number
--- @return number
function ui_class:GetOffsetY(y, h)
	local y_offset = 0
	-- Move the tooltip up if it overflows the bottom edge
	if y + h > self.dim.y then
		y_offset = self.dim.y - y - h - 10
		-- Move the tooltip down if it overflows the top edge
	elseif y < 0 then
		y_offset = -y + 10
	end
	return y_offset
end

--- Calculate x offset needed to not go over the screen
--- @private
--- @param x number The x-coordinate of the tooltip
--- @param w number The width of the tooltip
--- @return number x_offset The offset to apply to keep the tooltip within screen bounds
function ui_class:GetOffsetX(x, w)
	local min_offset = 38 -- Minimum padding from the screen edge
	local x_offset = 0

	-- Move the tooltip left if it overflows the right edge
	if x + w > self.dim.x - min_offset then x_offset = self.dim.x - x - w - min_offset end
	-- Move the tooltip right if it overflows the left edge
	if x + x_offset < min_offset then x_offset = min_offset - x end

	return x_offset
end

--- Set tooltip cache if not already set
--- @private
--- @param key string
--- @param x number
--- @param y number
function ui_class:SetTooltipCache(x, y, key)
	local prev = self:GetPrevious()
	self.gui_tooltip_size_cache[key] = {
		width = prev.w,
		height = prev.h,
		x_offset = self:GetOffsetX(x, prev.w),
		y_offset = self:GetOffsetY(y, prev.h),
	}
end

--- Draw tooltip off-screen to measure its size
--- @private
--- @param x number
--- @param y number
--- @param ui_fn function
--- @param key string
--- @param ... any
function ui_class:DrawTooltipOffScreen(x, y, ui_fn, key, ...)
	local orig_gui, orig_id, anim_id = self.gui, self.gui_id, self.animation_id
	self.gui, self.gui_id, self.animation_id = self.gui_tooltip, self.tooltip_gui_id, self.tooltip_animation_id
	local offscreen_offset = 1000
	GuiBeginAutoBox(self.gui)
	GuiLayoutBeginVertical(self.gui, x + offscreen_offset, y + offscreen_offset, true)
	ui_fn(self, ...)
	GuiLayoutEnd(self.gui)
	GuiEndAutoBoxNinePiece(self.gui, self.tooltip_margin, 0, 0, false, 0, self.tooltip_img)
	self:SetTooltipCache(x, y, key)
	self.gui, self.gui_id, self.animation_id = orig_gui, orig_id, anim_id
end

--- Retrieves a tooltip data, drawing it off-screen if necessary
--- @param x number
--- @param y number
--- @param ui_fn function
--- @param ... any
--- @return gui_tooltip_size_cache
function ui_class:GetTooltipData(x, y, ui_fn, ...)
	local key = self:GetKey(x, y, ui_fn, ...)
	if not self.gui_tooltip_size_cache[key] then self:DrawTooltipOffScreen(x, y, ui_fn, key, ...) end
	return self.gui_tooltip_size_cache[key]
end

--- Generate a unique key for the tooltip cache
--- @protected
--- @param x number
--- @param y number
--- @param ui_fn function
--- @param ... any
--- @return string
function ui_class:GetKey(x, y, ui_fn, ...)
	local key = self:Locale("$current_language") .. tostring(x) .. tostring(y) .. tostring(ui_fn)
	for _, var in ipairs({ ... }) do
		key = key .. tostring(var)
	end
	return key
end

--- Actual function to draw tooltip
--- @private
--- @param x number
--- @param y number
--- @param ui_fn function
--- @param ... any
function ui_class:DrawToolTip(x, y, ui_fn, ...)
	local orig_gui, orig_id, anim_id = self.gui, self.gui_id, self.animation_id
	self.gui, self.gui_id, self.animation_id = self.gui_tooltip, self.tooltip_gui_id, self.tooltip_animation_id
	local cache = self:GetTooltipData(x, y, ui_fn, ...)
	if self.tooltip_previous ~= cache then
		self.tooltip_previous = cache
	else
		self.tooltip_reset = false
	end
	GuiZSet(self.gui, self.tooltip_z)
	self:AnimateB()
	self:AnimateAlpha(0.08, 0.1, self.tooltip_reset)
	self:AnimateScale(0.08, self.tooltip_reset)
	GuiBeginAutoBox(self.gui)
	GuiLayoutBeginVertical(self.gui, x + cache.x_offset, y + cache.y_offset, true)
	ui_fn(self, ...)
	GuiLayoutEnd(self.gui)
	GuiZSet(self.gui, self.tooltip_z + 1)
	GuiEndAutoBoxNinePiece(self.gui, self.tooltip_margin, 0, 0, false, 0, self.tooltip_img)
	self:AnimateE()
	GuiZSet(self.gui, 0)
	self.gui, self.gui_id, self.animation_id = orig_gui, orig_id, anim_id
end

--- Custom tooltip.
--- @protected
--- @param x number position of x.
--- @param y number position of y.
--- @param draw function|string function to render in tooltip.
--- @param ... any optional parameter to pass to ui function.
function ui_class:ShowTooltip(x, y, draw, ...)
	local fn_type = type(draw)
	if fn_type == "string" then
		self:DrawToolTip(x, y, self.TooltipText, draw)
	elseif fn_type == "function" then
		self:DrawToolTip(x, y, draw, ...)
	end
end

--- Adds a tooltip that centered around previous widget
--- @protected
--- @param x number offset
--- @param y number offset
--- @param draw function function to render in tooltip.
--- @param ... any optional parameter to pass to ui function.
function ui_class:ShowTooltipCenteredX(x, y, draw, ...)
	local prev = self:GetPrevious()
	local cache = self:GetTooltipData(0, 0, draw, ...)
	local center = prev.x + (prev.w - cache.width) / 2 + self.tooltip_margin -- 5 is margin from autobox
	self:DrawToolTip(center + x, prev.y + y, draw, ...)
end

--- Adds a text tooltip that centered around previous widget
--- @protected
--- @param x number offset
--- @param y number offset
--- @param text string text to show
function ui_class:ShowTooltipTextCenteredX(x, y, text)
	self:ShowTooltipCenteredX(x, y, self.TooltipText, text)
end

--- Custom tooltip with hovered check.
--- @protected
--- @param x number offset x.
--- @param y number offset y.
--- @param draw function|string function to render in tooltip.
--- @param ... any optional parameter to pass to ui function.
function ui_class:AddTooltip(x, y, draw, ...)
	local prev = self:GetPrevious()
	if prev.hovered then self:ShowTooltip(prev.x + x, prev.y + y, draw, ...) end
end

--- draw text at 0
--- @private
--- @param text string
function ui_class:TooltipText(text)
	self:Text(0, 0, text)
end

-- ############################################
-- #########		SCROLLBOX		###########
-- ############################################

---@class (exact) ui_fake_scroll
---@field public y number current offset for elements
---@field package target_y number target offset for elements (for smooth scrolling)
---@field package max_y number size of contents within scrollbox
---@field package max_y_target number maximum possible value for target_y
---@field package move_triggered boolean for mouse drag
---@field package scrollbar_pos number position of scrollbar thumb
---@field package scrollbar_height number height of scrollbar thumb
---@field package content_height number height of content within scrollbox
---@field package visible_height number visible part of content within scrollbox
---@field package click_offset number for mouse drag
---@field package sprite_dim number dimension of 9box that is used for scrollbox
---@field package height number current height of scrollbo

---returns scrollbox data
---@private
---@param id string
---@return ui_fake_scroll
function ui_class:get_scrollbox(id)
	if not self.scrollboxes[id] then
		self.scrollboxes[id] = {
			y = 0,
			target_y = 0,
			max_y = 0,
			click_offset = 0,
			content_height = 0,
			height = 0,
			height_max = 0,
			max_y_target = 0,
			move_triggered = false,
			scrollbar_height = 0,
			scrollbar_pos = 0,
			sprite_dim = 0,
			visible_height = 0,
		}
	end
	return self.scrollboxes[id]
end

---function to calculate target scroll pos for mouse drag
---@private
---@param mouse_y number position of mouse
---@param y number start position of scrollbar
---@param height number height of scrollbar
---@param target number relative target position of bar thumb
---@param scroll ui_fake_scroll
---@return number
function ui_class:ScrollBoxCalculateTargetScroll(mouse_y, y, height, target, scroll)
	local target_pos = mouse_y - y - target
	return (target_pos / (height - scroll.scrollbar_height)) * (scroll.content_height - scroll.visible_height)
end

---function to check if click was on scroll thumb or bar
---@private
---@param mouse_y number position of mouse
---@param y number start position of scrollbar
---@param scroll ui_fake_scroll
---@return boolean
function ui_class:ScrollBoxClickedOnScrollBarThumb(mouse_y, y, scroll)
	return mouse_y < y + scroll.scrollbar_pos or mouse_y > y + scroll.scrollbar_pos + scroll.scrollbar_height
end

---function to calculate scrollbar thumb position
---@private
---@param target number y position from which to calculate
---@param height number height of scrollbox
---@param scroll ui_fake_scroll
---@return number position
function ui_class:ScrollBoxCalculateScrollbarPos(target, height, scroll)
	return (target / (scroll.content_height - scroll.visible_height)) * (height - scroll.scrollbar_height)
end

---function to handle clicks on scrollbar
---@private
---@param y number start position of scrollbar
---@param height number height of scrollbox
---@param scroll ui_fake_scroll
function ui_class:ScrollBoxHandleClick(y, height, scroll)
	local _, mouse_y = self:get_mouse_pos()
	if self:ScrollBoxClickedOnScrollBarThumb(mouse_y, y, scroll) then
		local scroll_target = self:ScrollBoxCalculateTargetScroll(mouse_y, y, height, scroll.scrollbar_height / 2, scroll)
		scroll.scrollbar_pos = self:ScrollBoxCalculateScrollbarPos(scroll_target, height, scroll)
	end
	scroll.move_triggered = true
	scroll.click_offset = mouse_y - (y + scroll.scrollbar_pos)
end

---function to draw scrollbar
---@private
---@param x number x pos for scrollbox
---@param y number y pos or scrollbox
---@param z number z of scrollbox
---@param width number
---@param scroll ui_fake_scroll
function ui_class:ScrollBoxDrawScrollbarTrack(x, y, z, width, scroll)
	local scroll_img = self.scroll.scroll_img
	if
		self:IsHoverBoxHovered(x + width + scroll.sprite_dim / 3 - 7, y + scroll.scrollbar_pos, 5, scroll.scrollbar_height + 2, true)
		or scroll.move_triggered
	then
		scroll_img = self.scroll.scroll_img_hl
	end
	-- Draw the scrollbar thumb
	self:Draw9Piece(x + width + scroll.sprite_dim / 3 - 5, y + scroll.scrollbar_pos, z - 10, 0, scroll.scrollbar_height, scroll_img)

	-- Draw the scrollbar track
	self:Draw9Piece(x + width + scroll.sprite_dim / 3 - 8, y, z - 10, 6, scroll.height, self.c.empty, self.c.empty)
end

---function that make scrollbar draggable
---@private
---@param y number start position of scrollbar
---@param scroll ui_fake_scroll
function ui_class:ScrollBoxMouseDrag(y, scroll)
	if self:IsHovered() and self:IsLeftClicked() then self:ScrollBoxHandleClick(y, scroll.height, scroll) end
	if not InputIsMouseButtonDown(self.c.codes.mouse.lc) then scroll.move_triggered = false end
	if scroll.move_triggered then
		local _, mouse_y = self:get_mouse_pos()
		scroll.target_y = self:ScrollBoxCalculateTargetScroll(mouse_y, y, scroll.height, scroll.click_offset, scroll)
	end
end

---function to calculate internal dimensions of scrollbox
---@private
---@param y number
---@param scroll ui_fake_scroll
function ui_class:ScrollBoxCalculateDims(y, scroll)
	scroll.content_height = scroll.max_y
	scroll.visible_height = scroll.height
	scroll.scrollbar_height = (scroll.visible_height / scroll.content_height) * scroll.height
	scroll.scrollbar_pos = self:ScrollBoxCalculateScrollbarPos(scroll.y, scroll.height, scroll)
end

---function to accept scroll wheels
---@private
---@param scroll ui_fake_scroll
function ui_class:ScrollBoxAnswerToWheel(scroll)
	if InputIsMouseButtonJustDown(self.c.codes.mouse.wheel_up) then scroll.target_y = scroll.target_y - 10 end
	if InputIsMouseButtonJustDown(self.c.codes.mouse.wheel_down) then scroll.target_y = scroll.target_y + 10 end
end

---function to accept other scroll inputs
---@private
---@param scroll ui_fake_scroll
function ui_class:ScrollBoxAnswerToShortcuts(scroll)
	if InputIsKeyJustDown(self.c.codes.keyboard.home) then scroll.target_y = 0 end
	if InputIsKeyJustDown(self.c.codes.keyboard._end) then scroll.target_y = scroll.max_y_target end
	if InputIsKeyDown(self.c.codes.keyboard.up) then scroll.target_y = scroll.target_y - 10 end
	if InputIsKeyDown(self.c.codes.keyboard.down) then scroll.target_y = scroll.target_y + 10 end
	if InputIsKeyJustDown(self.c.codes.keyboard.pageup) then scroll.target_y = scroll.target_y - math.floor(scroll.visible_height * 0.9) end
	if InputIsKeyJustDown(self.c.codes.keyboard.pagedown) then scroll.target_y = scroll.target_y + math.floor(scroll.visible_height * 0.9) end
end

---function to clump target and move content
---@private
---@param scroll ui_fake_scroll
function ui_class:ScrollBoxClumpAndMove(scroll)
	scroll.target_y = math.max(math.min(scroll.target_y, scroll.max_y_target), 0)
	if math.abs(scroll.target_y - scroll.y) < 1 then
		scroll.y = scroll.target_y
	else
		scroll.y = (scroll.y + scroll.target_y) / 2
	end
end

---fake scroll box
---@protected
---@param x number position x
---@param y number position y
---@param z number z of scrollbox
---@param width number
---@param height_max number
---@param sprite string 9piece for scrollbox
---@param margin_x number margin to add to width
---@param margin_y number margin to add to height
---@param draw_fn function function to draw inside scrollbox, position is relative
function ui_class:ScrollBox(x, y, z, width, height_max, sprite, margin_x, margin_y, draw_fn)
	local id = self:id()
	local scroll = self:get_scrollbox(tostring(draw_fn))
	self.last_scrollbox = scroll

	scroll.sprite_dim = GuiGetImageDimensions(self.gui, sprite, 1)
	scroll.max_y_target = scroll.max_y - scroll.height
	local box_x = x - margin_x
	local box_y = y - margin_y
	local box_width = width + margin_x * 2
	local box_height = scroll.height + margin_y * 2
	self:Draw9Piece(box_x, box_y, z, box_width, box_height, sprite)

	--- phantom 9piece with corrent hitbox
	local hovered = self:IsHoverBoxHovered(
		box_x - scroll.sprite_dim / 3,
		box_y - scroll.sprite_dim / 3,
		box_width + scroll.sprite_dim / 1.5,
		box_height + scroll.sprite_dim / 1.5,
		true
	)

	if hovered then self:BlockInput() end

	if scroll.max_y > scroll.height then
		self:ScrollBoxCalculateDims(y, scroll)
		self:ScrollBoxDrawScrollbarTrack(x + margin_x, y, z, width, scroll)
		self:ScrollBoxMouseDrag(y, scroll)
		if hovered then self:ScrollBoxAnswerToWheel(scroll) end
	end
	self.scroll.y = scroll.y

	GuiAnimateBegin(self.gui)
	GuiAnimateAlphaFadeIn(self.gui, id, 0, 0, true)
	GuiBeginAutoBox(self.gui)
	GuiBeginScrollContainer(self.gui, id, x, y, width, scroll.height, false, 0, 0)
	GuiEndAutoBoxNinePiece(self.gui)
	GuiAnimateEnd(self.gui)
	draw_fn(self)
	local prev = self:GetPrevious()
	scroll.max_y = prev.y + prev.h - y
	scroll.height = math.min(scroll.max_y, height_max)
	self:ScrollBoxClumpAndMove(scroll)
	GuiEndScrollContainer(self.gui)
end

---fake scroll box
---@protected
---@param x number position x
---@param y number position y
---@param z number z of scrollbox
---@param width number
---@param height_max number
---@param height_inside number
---@param sprite string 9piece for scrollbox
---@param margin_x number margin to add to width
---@param margin_y number margin to add to height
---@param draw_fn function function to draw inside scrollbox, position is relative
function ui_class:ScrollBoxFixed(x, y, z, width, height_max, height_inside, sprite, margin_x, margin_y, draw_fn)
	local id = self:id()
	local scroll = self:get_scrollbox(tostring(draw_fn))
	self.last_scrollbox = scroll
	scroll.max_y = height_inside - y
	scroll.height = math.min(scroll.max_y, height_max)

	scroll.sprite_dim = GuiGetImageDimensions(self.gui, sprite, 1)
	scroll.max_y_target = scroll.max_y - scroll.height
	local box_x = x - margin_x
	local box_y = y - margin_y
	local box_width = width + margin_x * 2
	local box_height = scroll.height + margin_y * 2
	self:Draw9Piece(box_x, box_y, z, box_width, box_height, sprite)

	--- phantom 9piece with corrent hitbox
	local hovered = self:IsHoverBoxHovered(
		box_x - scroll.sprite_dim / 3,
		box_y - scroll.sprite_dim / 3,
		box_width + scroll.sprite_dim / 1.5,
		box_height + scroll.sprite_dim / 1.5,
		true
	)

	if hovered then self:BlockInput() end

	if scroll.max_y > scroll.height then
		self:ScrollBoxCalculateDims(y, scroll)
		self:ScrollBoxDrawScrollbarTrack(x + margin_x, y, z, width, scroll)
		self:ScrollBoxMouseDrag(y, scroll)
		if hovered then
			self:ScrollBoxAnswerToWheel(scroll)
			self:ScrollBoxAnswerToShortcuts(scroll)
		end
	end
	self.scroll.y = scroll.y

	GuiAnimateBegin(self.gui)
	GuiAnimateAlphaFadeIn(self.gui, id, 0, 0, true)
	GuiBeginAutoBox(self.gui)
	GuiBeginScrollContainer(self.gui, id, x, y, width, scroll.height, false, 0, 0)
	GuiEndAutoBoxNinePiece(self.gui)
	GuiAnimateEnd(self.gui)
	draw_fn(self)
	self:ScrollBoxClumpAndMove(scroll)
	GuiEndScrollContainer(self.gui)
end

function ui_class:ScrollToEnd()
	local scroll = self.last_scrollbox
	if scroll == nil then return end

	scroll.target_y = math.max(scroll.max_y_target, 0)
	scroll.y = scroll.target_y
	self.scroll.y = scroll.y
end

-- ############################################
-- #############		TEXT		###########
-- ############################################

--- Returns translated text from $string
--- @protected
--- @param string string should be in $string format
--- @return string
function ui_class:Locale(string)
	local pattern = "%$%w[%w_]+"
	string = string:gsub(pattern, GameTextGetTranslatedOrNot, 1)
	if string:find(pattern) then
		return self:Locale(string)
	else
		return string
	end
end

--- get text dimensions
--- @protected
--- @param text string
--- @param font? string
--- @return number, number
function ui_class:GetTextDimension(text, font)
	return GuiGetTextDimensions(self.gui, text, 1, 2, font or "")
end

--- Function to calculate the longest string in array
--- @private
--- @param array table strings
--- @param key string cache key
--- @return number
function ui_class:CalculateLongestText(array, key)
	local longest = 0
	for _, text in ipairs(array) do
		local length = self:GetTextDimension(text, "")
		longest = math.max(longest, length)
	end
	self.gui_longest_string_cache[key] = longest
	return self.gui_longest_string_cache[key]
end

--- Get the longest string length from array
--- @protected
--- @param array table table to look through
--- @param key string cache key, should be static enough
--- @return number
function ui_class:GetLongestText(array, key)
	key = self:Locale("$current_language") .. key
	return self.gui_longest_string_cache[key] or self:CalculateLongestText(array, key)
end

--- GuiText but centered
--- @protected
--- @param x number
--- @param y number
--- @param text string
--- @param longest number longest string length
--- @param font? string
function ui_class:TextCentered(x, y, text, longest, font)
	font = font or ""
	local x_offset = (longest - self:GetTextDimension(text, font)) / 2
	GuiText(self.gui, x + x_offset, y, text, 1, font)
end

--- GuiText
--- @protected
--- @param text string
--- @param font? string
--- @param x number
--- @param y number
function ui_class:Text(x, y, text, font)
	GuiText(self.gui, x, y, text, 1, font or "")
end

--- GuiText with borders
--- @param x number
--- @param y number
--- @param z number
--- @param text string
--- @param active boolean
--- @param sprite? string
--- @param sprite_hl? string
function ui_class:DrawButton(x, y, z, text, active, sprite, sprite_hl)
	sprite = sprite or self.buttons.img
	sprite_hl = sprite_hl or active and self.buttons.img_hl or self.buttons.img
	self:SetZ(z - 1)
	if not active then self:ColorGray() end
	self:Text(x, y, text)
	self:AddOptionForNext(self.c.options.ForceFocusable)
	self:Draw9Piece(x - 1, y, z, self:GetTextDimension(text) + 1.5, 11, sprite, sprite_hl)
end

-- ############################################
-- #########		VARIABLES		###########
-- ############################################

--- update dimensions
--- @protected
function ui_class:UpdateDimensions()
	GuiStartFrame(self.gui)
	self.dim.x, self.dim.y = GuiGetScreenDimensions(self.gui)
end

--- return x and y of mouse pos
--- @protected
--- @return number mouse_x, number mouse_y
function ui_class:get_mouse_pos()
	local mouse_screen_x, mouse_screen_y = InputGetMousePosOnScreen()
	local mx_p, my_p = mouse_screen_x / 1280, mouse_screen_y / 720
	return mx_p * self.dim.x, my_p * self.dim.y
end

--- get center of screen
--- @protected
--- @param width number
--- @param height number
--- @return number x, number y
function ui_class:CalculateCenterInScreen(width, height)
	local x = (self.dim.x - width) / 2
	local y = (self.dim.y - height) / 2
	return x, y
end

--- @class PreviousInfo
--- @field lc boolean left click
--- @field rc boolean right click
--- @field hovered boolean hovered
--- @field x number
--- @field y number
--- @field w number
--- @field h number

--- Returns a previous widget info
--- @return PreviousInfo return hover, x, y, w, h
--- @protected
--- @nodiscard
function ui_class:GetPrevious()
	local lc, rc, prev_hovered, x, y, width, height = GuiGetPreviousWidgetInfo(self.gui)
	return {
		lc = lc,
		rc = rc,
		hovered = prev_hovered,
		x = x,
		y = y,
		w = width,
		h = height,
	}
end

-- ############################################
-- #########		GUI OPTIONS		###########
-- ############################################

--- Set Z for next widget
--- @protected
--- @param number number
function ui_class:SetZ(number)
	GuiZSetForNextWidget(self.gui, number)
end

--- set color for next widget
--- @protected
--- @param r integer
--- @param g integer
--- @param b integer
--- @param a? integer
function ui_class:Color(r, g, b, a)
	a = a or 1
	GuiColorSetForNextWidget(self.gui, r, g, b, a)
end

--- @protected
function ui_class:ColorGray()
	self:Color(0.6, 0.6, 0.6)
end

--- set option for all next widgets
--- @protected
--- @param option ui_options
function ui_class:AddOption(option)
	GuiOptionsAdd(self.gui, option)
end

--- set option for next widget
--- @protected
--- @param option ui_options
function ui_class:AddOptionForNext(option)
	GuiOptionsAddForNextWidget(self.gui, option)
end

--- remove option for all next widgets
--- @protected
--- @param option ui_options
function ui_class:RemoveOption(option)
	GuiOptionsRemove(self.gui, option)
end

-- ############################################
-- ############		IMAGES		###############
-- ############################################

--- for debugging
--- @protected
--- @debug
function ui_class:DebugDrawGrid()
	for i = 0, 640, 10 do
		if i % 16 == 0 then GuiColorSetForNextWidget(self.gui, 1, 0, 0, 1) end
		self:SetZ(-5000)
		GuiImage(self.gui, self:id(), i, 0, self.c.px, 0.2, 1, 360)
	end
	for i = 0, 360, 10 do
		if i % 9 == 0 then GuiColorSetForNextWidget(self.gui, 1, 0, 0, 1) end
		self:SetZ(-5000)
		GuiImage(self.gui, self:id(), 0, i, self.c.px, 0.2, 640, 1)
	end
end

--- add image
--- @protected
--- @param x number
--- @param y number
--- @param sprite string
--- @param alpha? number
--- @param scale_x? number
--- @param scale_y? number
function ui_class:Image(x, y, sprite, alpha, scale_x, scale_y)
	GuiImage(self.gui, self:id(), x, y, sprite, alpha or 1, scale_x or 1, scale_y or scale_x or 1, 0, 2)
end

--- draw 9piece
--- @protected
--- @param x number
--- @param y number
--- @param z number
--- @param width number
--- @param height number
--- @param sprite? string
--- @param highlight? string
function ui_class:Draw9Piece(x, y, z, width, height, sprite, highlight)
	sprite = sprite or self.c.default_9piece
	highlight = highlight or sprite
	GuiZSetForNextWidget(self.gui, z)
	GuiImageNinePiece(self.gui, self:id(), x, y, width, height, 1, sprite, highlight)
end

-- ############################################
-- #########		ANIMATIONS		###########
-- ############################################

--- Adds alpha to animation
--- @protected
--- @param speed integer
--- @param step integer
--- @param reset boolean
function ui_class:AnimateAlpha(speed, step, reset)
	GuiAnimateAlphaFadeIn(self.gui, self.animation_id, speed, step, reset)
	self.animation_id = self.animation_id + 1
end

--- Adds scale to animation
--- @protected
--- @param acceleration number
--- @param reset boolean
function ui_class:AnimateScale(acceleration, reset)
	GuiAnimateScaleIn(self.gui, self.animation_id, acceleration, reset)
	self.animation_id = self.animation_id + 1
end

--- Ends an animation
--- @protected
function ui_class:AnimateE()
	GuiAnimateEnd(self.gui)
end

--- Begins an animation
--- @protected
function ui_class:AnimateB()
	GuiAnimateBegin(self.gui)
end

-- ############################################
-- #############		MISC		###########
-- ############################################

--- Resets a gui id
--- @protected
function ui_class:id_reset()
	self.gui_id = 100000
	self.tooltip_gui_id = 1000
	self.animation_id = 100
	self.tooltip_animation_id = 100
end

--- Returns an id with increment
--- @private
--- @return number gui_id
function ui_class:id()
	self.gui_id = self.gui_id + 1
	return self.gui_id
end

--- start frame
--- @protected
function ui_class:StartFrame()
	self:id_reset()
	self.tooltip_reset = true
	if self.gui then GuiStartFrame(self.gui) end
	if self.gui_tooltip then GuiStartFrame(self.gui_tooltip) end
end

return ui_class:New()
