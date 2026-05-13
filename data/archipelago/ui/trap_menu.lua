dofile_once("data/archipelago/scripts/trap_utils.lua")
dofile_once("data/scripts/lib/utilities.lua")

--- Used for testing and debugging only.
---@class TrapMenu
---@field gui gui
---@field initialized bool
---@field trap_list {[string]:string[]} list of traps by author name
---@field author_menu_open string the trap author menu which has been opened
local TrapMenu = {
	gui = GuiCreate(),
	initialized = false,
	trap_list = {},
	awful_traps = {},
	author_menu_open = "",
}

function TrapMenu:create()
	if self.initialized then return end
	InitStreamingTraps()

	dofile_once("data/scripts/streaming_integration/event_list.lua")
	for _, event in ipairs(streaming_events) do
		if event.kind and event.kind <= STREAMING_EVENT_BAD then
			local author = tostring(event.ui_author)
			local author_list = self.trap_list[author] or {}
			table.insert(author_list, event.id)
			self.trap_list[author] = author_list

			if event.kind == STREAMING_EVENT_AWFUL then
				self.awful_traps[event.id] = true
			end
		end
	end

	self.initialized = true
end

function TrapMenu:update()
	self:create()

	GuiStartFrame(self.gui)
	GuiLayoutBeginVertical(self.gui, 12.5, 50, true)
	if GuiButton(self.gui, 0, 0, 0, "Random") then
		BadTimes(true)
	end

	local width, height = GuiGetScreenDimensions(self.gui)
	for author, author_traps in pairs(self.trap_list) do
		GuiIdPushString(self.gui, author)

		local is_open = self.author_menu_open == author
		local tag = is_open and "V " or "> "

		if GuiButton(self.gui, 0, 0, 0, tag .. author) then
			if is_open then
				self.author_menu_open = ""
			else
				self.author_menu_open = author
			end
		end

		local extra_w = 0
		local extra_h = 0
		local total_h = 0
		if is_open then
			GuiLayoutBeginVertical(self.gui, 10, 0, true)
			for id, trap_name in ipairs(author_traps) do
				if self.awful_traps[trap_name] then
					GuiColorSetForNextWidget(self.gui, 1, 0.5, 0.5, 1)
				end
				if GuiButton(self.gui, id + 1000, 0, 0, trap_name .. "  ") then
					RunStreamingEvent(trap_name)
				end

				local _, _, _, x, y, wid, hgt = GuiGetPreviousWidgetInfo(self.gui)
				extra_w = math.max(extra_w, wid)
				if extra_h ~= 0 then
					total_h = total_h + hgt
				end
				extra_h = math.max(extra_h, hgt)
				if y >= height - 40 then
					GuiLayoutEnd(self.gui)
					GuiLayoutBeginVertical(self.gui, 10 + extra_w, -extra_h, true)
					extra_w = 0
					extra_h = 0
				end
			end
			GuiLayoutEnd(self.gui)
			GuiLayoutAddVerticalSpacing(self.gui, total_h)
		end

		GuiIdPop(self.gui)
	end
	GuiLayoutEnd(self.gui)
end

return TrapMenu
