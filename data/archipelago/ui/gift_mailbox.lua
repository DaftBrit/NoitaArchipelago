local Globals = dofile("data/archipelago/scripts/globals.lua")
local IncomingGift = dofile("data/archipelago/scripts/ui/gift_translate_incoming.lua")

dofile_once("data/scripts/lib/utilities.lua")

local GiftWindow = {}

local ID_SCROLL_GIFTS = 54576
local ID_ANIM_CTRL = 54577
local ID_BTN_REFRESH = 54578

local ID_BTN_ACCEPT_GIFT = 55001
local ID_BTN_REJECT_GIFT = 65001
local ID_BTN_ICON = 75001

local ACCESS_RADIUS2 = 20*20
local ANIM_SCALE = 0.075


function GiftWindow:create(ap, gifting)
	self.gui = GuiCreate()
	self.ap = ap
	self.gifting = gifting
	self:close()
end


function GiftWindow:open()
	Globals.GiftMailboxOpen:set(1)
	self.was_open = true
end


function GiftWindow:close()
	Globals.GiftMailboxOpen:reset()
	GuiAnimateScaleIn(self.gui, ID_ANIM_CTRL, ANIM_SCALE, true)
	self.was_open = false
end


function GiftWindow:is_open()
	return self.gui ~= nil and Globals.GiftMailboxOpen:is_set()
end


-- ?????? Maybe take an arg and call this with all tracked gifts, gifts go in a cache maybe?
function GiftWindow:refresh_gifts()
end


function GiftWindow:show_gift_entry(name, value, width)
	GuiBeginAutoBox(self.gui)

  GuiLayoutBeginHorizontal(self.gui, 0, 0, false, 8, 8)
    -- TODO
    --GuiImage(self.gui, ID_BTN_ICON + value, 0, 0, self:get_gift_icon())
	  GuiText(self.gui, 0, 0, name)
	GuiLayoutEnd(self.gui)

	GuiZSetForNextWidget(self.gui, 50)
	GuiEndAutoBoxNinePiece(self.gui, -1, width)
end


function GiftWindow:show_gifts(width)
	GuiLayoutBeginVertical(self.gui, 0, 0)

  -- read/iterate gifts
  -- self:show_gift_entry...

	GuiLayoutEnd(self.gui)
end


function GiftWindow:should_be_open()
	if not self:is_open() then
		return false
	end

	local player_x, player_y = get_player_position()
	local sendbox_entity = EntityGetClosestWithTag(player_x, player_y, "ap_mailbox")
	if sendbox_entity == nil then return false end

	local box_x, box_y = EntityGetTransform(sendbox_entity)
	return get_distance2(player_x, player_y, box_x, box_y) < ACCESS_RADIUS2
end


function GiftWindow:draw_ui()
	GuiStartFrame(self.gui)
	GuiOptionsClear(self.gui)

	local screen_width, screen_height = GuiGetScreenDimensions(self.gui)

	GuiAnimateBegin(self.gui)
	GuiAnimateScaleIn(self.gui, ID_ANIM_CTRL, ANIM_SCALE, false)
		GuiBeginAutoBox(self.gui)
			GuiLayoutBeginVertical(self.gui, 35, 20)
				GuiOptionsAddForNextWidget(self.gui, GUI_OPTION.DrawSemiTransparent)
				GuiText(self.gui, 0, 0, "Mailbox")
				GuiBeginScrollContainer(self.gui, ID_SCROLL_GIFTS, 0, 0, screen_width / 4, screen_height / 2)
					self:show_gifts(screen_width / 4)
				GuiEndScrollContainer(self.gui)
				GuiLayoutAddVerticalSpacing(self.gui, 16)

				GuiButton(self.gui, ID_BTN_REFRESH, screen_width / 4 - 20, 0, "Refresh")

			GuiLayoutEnd(self.gui)
			GuiZSetForNextWidget(self.gui, 100)
		GuiEndAutoBoxNinePiece(self.gui)
	GuiAnimateEnd(self.gui)
end


function GiftWindow:update()
	if self:should_be_open() then
		self:draw_ui()
		self.was_open = true
	elseif self:is_open() or self.was_open then
		self:close()
	end
end

return GiftWindow
