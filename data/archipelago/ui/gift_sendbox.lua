local Globals = dofile("data/archipelago/scripts/globals.lua")
dofile_once("data/scripts/lib/utilities.lua")

local GiftWindow = {}

local ID_BTN_SEND_GIFT = 44574

local ID_SCROLL_PLAYERS = 44575
local ID_SCROLL_GIFTS = 44576

local ID_BTN_PLYRLIST = 45001

function GiftWindow:create(ap, gifting)
	self.gui = GuiCreate()
	self.ap = ap
	self.gifting = gifting
	self.selected_player = -1
	self:close()
end

function GiftWindow:open()
	Globals.GiftSendboxOpen:set(1)
end

function GiftWindow:close()
	Globals.GiftSendboxOpen:reset()
end

function GiftWindow:is_open()
	return self.gui ~= nil and Globals.GiftSendboxOpen:is_set()
end

function GiftWindow:show_player_radio(name, value, width)
	local highlighted = value == self.selected_player

	GuiBeginAutoBox(self.gui)

	if highlighted then
		GuiColorSetForNextWidget(self.gui, 1, 1, 0.6, 1)
	end

	if GuiButton(self.gui, ID_BTN_PLYRLIST + value, 0, 0, name) then
		self.selected_player = value
	end
	--GuiLayoutEnd(self.gui)

	GuiZSetForNextWidget(self.gui, 50)
	GuiEndAutoBoxNinePiece(self.gui, -1, width)
end

function GiftWindow:show_players(width)
	GuiLayoutBeginVertical(self.gui, 0, 0)

	self:show_player_radio("Any Player (Random)", -1, width)
	for idx, player in ipairs(self.ap:get_players()) do
		self:show_player_radio(player.alias, player.slot, width)
	end

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
					GuiText(self.gui, 0, 0, "Players")
					GuiBeginScrollContainer(self.gui, ID_SCROLL_PLAYERS, 0, 0, screen_width / 4, screen_height / 2)
						self:show_players(screen_width / 4)
					GuiEndScrollContainer(self.gui)
				GuiLayoutEnd(self.gui)

				GuiLayoutBeginVertical(self.gui, 0, 0, false, 8)
					GuiText(self.gui, 0, 0, "Basin Inventory")
					GuiBeginScrollContainer(self.gui, ID_SCROLL_GIFTS, 0, 0, screen_width / 4, screen_height / 2)
						-- TODO gift list
						GuiText(self.gui, 0, 0, "Items to send go here")
					GuiEndScrollContainer(self.gui)
				GuiLayoutEnd(self.gui)

			GuiLayoutEnd(self.gui)

			GuiLayoutAddVerticalSpacing(self.gui, 16)

			GuiButton(self.gui, ID_BTN_SEND_GIFT, screen_width / 2 - 20, 0, "Send Gift")

		GuiLayoutEnd(self.gui)
		GuiZSetForNextWidget(self.gui, 100)
	GuiEndAutoBoxNinePiece(self.gui)
end

return GiftWindow
