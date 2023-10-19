local Globals = dofile("data/archipelago/scripts/globals.lua")
local IncomingGift = dofile("data/archipelago/scripts/ui/gift_translate_incoming.lua")

dofile_once("data/scripts/lib/utilities.lua")

local GiftWindow = {}

local ID_SCROLL_GIFTS = 54576
local ID_BTN_REFRESH = 54578

local ID_BTN_ACCEPT_GIFT = 55001
local ID_BTN_REJECT_GIFT = 65001
local ID_BTN_ICON = 75001

function GiftWindow:create(ap, gifting)
	self.gui = GuiCreate()
	self.ap = ap
	self.gifting = gifting
	self:close()
end

function GiftWindow:open()
	Globals.GiftMailboxOpen:set(1)
end

function GiftWindow:close()
	Globals.GiftMailboxOpen:reset()
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

function GiftWindow:update()
	if not self:is_open() then return end

	GuiStartFrame(self.gui)
	GuiOptionsClear(self.gui)

	local screen_width, screen_height = GuiGetScreenDimensions(self.gui)

	GuiBeginAutoBox(self.gui)
		GuiLayoutBeginVertical(self.gui, 25, 25)
			GuiOptionsAddForNextWidget(self.gui, GUI_OPTION.DrawSemiTransparent)
			GuiText(self.gui, 0, 0, "Archipelago Gifting Interface")

			GuiLayoutBeginHorizontal(self.gui, 0, 0, false, 8, 8)

				GuiLayoutBeginVertical(self.gui, 0, 0, false, 8)
					GuiText(self.gui, 0, 0, "Basin Inventory")
					GuiBeginScrollContainer(self.gui, ID_SCROLL_GIFTS, 0, 0, screen_width / 4, screen_height / 2)
						self:show_gifts(screen_width / 4)
					GuiEndScrollContainer(self.gui)
				GuiLayoutEnd(self.gui)

			GuiLayoutEnd(self.gui)

			GuiLayoutAddVerticalSpacing(self.gui, 16)

			GuiButton(self.gui, ID_BTN_REFRESH, screen_width / 4 - 20, 0, "Refresh Giftbox")

		GuiLayoutEnd(self.gui)
		GuiZSetForNextWidget(self.gui, 100)
	GuiEndAutoBoxNinePiece(self.gui)
end

return GiftWindow
