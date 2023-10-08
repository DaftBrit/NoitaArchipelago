local Globals = dofile("data/archipelago/scripts/globals.lua")

local GiftWindow = {}

local ID_WINDOW_BKG = 44570

local ID_BTN_CLOSE = 44571
local ID_BTN_ACCEPT_GIFT = 44572
local ID_BTN_RETURN_GIFT = 44573
local ID_BTN_SEND_GIFT = 44574

local ID_SCROLL_PLAYERS = 44575
local ID_SCROLL_GIFTS = 44576

function GiftWindow:create()
	self.gui = GuiCreate()
  self:close()
end

function GiftWindow:open()
  Globals.GiftWindowOpen:set(1)
end

function GiftWindow:close()
  Globals.GiftWindowOpen:reset()
end

function GiftWindow:is_open()
  return self.gui ~= nil and Globals.GiftWindowOpen:is_set()
end

-- NOTE TO SELF: Register the function to make that pink pixel spawn the entity responsible for the gift interface

function GiftWindow:update()
  if not self:is_open() then return end

	GuiStartFrame(self.gui)

	local screen_width, screen_height = GuiGetScreenDimensions(self.gui)

  --GuiImageNinePiece(self.gui, ID_WINDOW_BKG, screen_width / 4, screen_height / 4, screen_width / 2, screen_height / 2)
  GuiBeginAutoBox(self.gui)
    GuiLayoutBeginVertical(self.gui, 25, 25)
      GuiText(self.gui, 0, 0, "Gifting Interface")
      GuiLayoutBeginHorizontal(self.gui, 0, 0)
        GuiBeginScrollContainer(self.gui, ID_SCROLL_PLAYERS, 0, 0, 10, 10)
          GuiText(self.gui, 0, 0, "Players go here")
        GuiEndScrollContainer(self.gui)
        GuiBeginScrollContainer(self.gui, ID_SCROLL_GIFTS, 0, 0, 10, 10)
          GuiText(self.gui, 0, 0, "Gifts go here")
        GuiEndScrollContainer(self.gui)
      GuiLayoutEnd(self.gui)
      GuiLayoutBeginHorizontal(self.gui, 0, 0)
        GuiButton(self.gui, ID_BTN_RETURN_GIFT, 0, 0, "Return Gift")
        GuiButton(self.gui, ID_BTN_SEND_GIFT, 0, 0, "Send Gift")
        GuiButton(self.gui, ID_BTN_ACCEPT_GIFT, 0, 0, "Accept Gift")
      GuiLayoutEnd(self.gui)
    GuiLayoutEnd(self.gui)
  GuiEndAutoBoxNinePiece(self.gui)

  -- TODO finish this
end

return GiftWindow
