local APLIB = require(ModPath():gsub("/", ".") .. "bin.lua-apclientpp") ---@type APClient
local LogWindow = dofile("data/archipelago/lib/ui_lib.lua") ---@class LogWindow : UI_class
local Globals = dofile("data/archipelago/scripts/globals.lua") ---@type Globals

local color_map = {
	-- Archipelago supported ANSI colours
	["black"] = { 0.5, 0.5, 0.5, 1 },
	["red"] = { 0.9, 0, 0, 1 },
	["green"] = { 0, 0.9, 0, 1 },
	["yellow"] = { 0.9, 0.9, 0, 1 },
	["blue"] = { 0, 0, 0.9, 1 },
	["magenta"] = { 0.9, 0, 0.9, 1 },
	["cyan"] = { 0, 0.9, 0.9, 1 },
	["white"] = { 0.9, 0.9, 0.9, 1 },

	-- Extra colours specified by apclientpp
	["plum"] = { 1.0, 0.6, 1.0, 1 },
	["slateblue"] = { 0.2, 0.2, 0.8, 1 },
	["salmon"] = { 1.0, 0.4, 0.4, 1 },
	["gray"] = { 0.75, 0.75, 0.75, 1 },
	["grey"] = { 0.75, 0.75, 0.75, 1 },
}

-- Hacks to override some stuff in ui_lib
local OldGuiImageNinePiece = GuiImageNinePiece
local ninePieceAlphaOverride = nil
function GuiImageNinePiece(gui, id, x, y, width, height, alpha, sprite_filename, sprite_highlight_filename)
	if ninePieceAlphaOverride then
		alpha = ninePieceAlphaOverride
		ninePieceAlphaOverride = nil
	end
	OldGuiImageNinePiece(gui, id, x, y, width, height, alpha, sprite_filename, sprite_highlight_filename)
end

function GuiSetNextNinePieceAlpha(alpha)
	ninePieceAlphaOverride = alpha
end

---@param value any
---@return integer?
local function tointeger(value)
	local num = tonumber(value)
	if num == nil then return nil end
	return math.floor(num)
end

---Initializes the log window.
function LogWindow:create()
	self:New()
	self:updateDimensionsAndCalc()

	self.visible = false
	self.just_closed = false
	self.jump_to_end = false
	self.shift_up_amt = 0 -- for when oldest items get deleted and we don't want to lose what we're looking at

	self.message_log = Globals.LogHistory:get_table() or {}
	self.hints = {}
	self.hint_sorted_col = 0
	self.hint_sorted_descending = false
	self.total_log_height = 0
	for _, msg in ipairs(self.message_log) do
		self.total_log_height = self.total_log_height + msg.height
	end
	self.tailing_log = true
	self.tailing_y = 0

	self:resetPrinter()
	self:setColor("white")
	self.button_hovered = {}
	self.draw_mode = true

	self.log_limit = ModSettingGet("archipelago.log_limit") or 1000
	self.tab_idx = 1
end

---@param ap APClient
function LogWindow:SetAP(ap)
	self.ap = ap
end

function LogWindow:updateDimensionsAndCalc()
	self:UpdateDimensions()

	self.box_x = self.dim.x / 12
	-- guess to not overlap the quickbar, to prevent accidental clicks
	self.box_y = MagicNumbersGetValue("UI_BARS_POS_Y") + MagicNumbersGetValue("UI_QUICKBAR_OFFSET_Y") + 22
	self.box_width = self.dim.x - self.box_x * 2
	self.box_height = self.dim.y - self.box_y * 1.5

	self.scrollbox_width = self.box_width - 8 * 2
	self.textarea_end_x = self.scrollbox_width
	self.textarea_start_x = 0
	self.scrollbox_height = self.box_height - 16 - 8 - 4

	local _, text_height = self:GetTextDimension("Test")
	self.text_line_height = text_height
	self.hint_scrollbox_height = self.scrollbox_height - text_height

	self.hint_cell_width = self.scrollbox_width / 6
end

---Toggles the visibility of the log window.
function LogWindow:toggle()
	if self.just_closed then return end
	self.visible = not self.visible
	if self.visible then
		self.jump_to_end = true
	end
end

---Closes the log window.
function LogWindow:close()
	self.visible = false
	self.just_closed = true
end

---Resets the printing cursor to 0,0
function LogWindow:resetPrinter()
	self.last_checked_height = 0
	self.printer = { x = 0, y = 0 }
end

---Place the printing cursor on the next line.
function LogWindow:nextLine()
	self.printer.x = self.textarea_start_x
	self.printer.y = self.printer.y + self.last_checked_height - 1
end

function LogWindow:newLogLine()
	self:nextLine()
	self.printer.y = self.printer.y + 1
end

---Check if the width of whatever is being drawn will overdraw the scrollbox.
---@param width integer
---@return boolean
function LogWindow:isOverdraw(width)
	return self.printer.x + width > self.textarea_end_x
end

---Checks if the next word will be overdrawn and move the printing cursor to the next line.
---@param word string
function LogWindow:checkOverdraw(word)
	local word_width, word_height = self:GetTextDimension(word)
	if self:isOverdraw(word_width) then
		self:nextLine()
	end
	self.last_checked_height = word_height
	return word_width, word_height
end

---Prints a word to the log scrollbox.
---@param word string
---@param tooltip string|nil optional tooltip
function LogWindow:printWord(word, tooltip)
	local width = self:checkOverdraw(word)
	if self.draw_mode then
		self:Color(unpack(self.next_color))
		self:Text(self.printer.x, self.printer.y, word)

		if tooltip ~= nil and tooltip ~= "" then
			self:AddTooltip(0, 0, tooltip)
		end
	end

	self.printer.x = self.printer.x + width
end

---Prints a sentence to the log scrollbox, with word wrapping.
---@param text string
function LogWindow:printText(text, tooltip)
	for word in text:gmatch("[ \t]*[^ \t]+[ \t]*") do
		self:printWord(word, tooltip)
	end
end

---Sets the colour for the next word(s), using a colour string lookup.
---@param colour_name string
function LogWindow:setColor(colour_name)
	if color_map[colour_name] then
		self.next_color = color_map[colour_name]
	else
		self.next_color = color_map["white"]
	end
end

---Prints a player token by looking up their player name and tooltipping the game they are playing.
---@param token table
function LogWindow:printPlayerId(token)
	local player_id = tointeger(token.text)
	if player_id == nil then return end

	if self.draw_mode then
		if player_id == self.ap:get_player_number() then
			self:setColor("magenta")
		else
			self:setColor("yellow")
		end
	end

	local name = self.ap:get_player_alias(player_id)
	local game = self.ap:get_player_game(player_id)
	self:printWord(name, game)
end

---Prints an item token by looking up the item name and tooltipping the game it comes from.
---@param token table
function LogWindow:printItemId(token)
	local item_id = tointeger(token.text)
	local player_id = tointeger(token.player)
	if item_id == nil or player_id == nil then return end

	if self.draw_mode then
		local item_flags = tointeger(token.flags)
		if item_flags == nil then item_flags = 0 end

		if bit.band(item_flags, APLIB.ItemFlags.FLAG_ADVANCEMENT) then
			self:setColor("plum")
		elseif bit.band(item_flags, APLIB.ItemFlags.FLAG_NEVER_EXCLUDE) then
			self:setColor("slateblue")
		elseif bit.band(item_flags, APLIB.ItemFlags.FLAG_TRAP) then
			self:setColor("salmon")
		else
			self:setColor("cyan")
		end
	end

	local game = self.ap:get_player_game(player_id)
	local name = self.ap:get_item_name(item_id, game)
	self:printText(name, game)
end

---Prints a location token by looking up the location name and tooltipping the game it comes from.
---@param token table
function LogWindow:printLocationId(token)
	local location_id = tointeger(token.text)
	local player_id = tointeger(token.player)
	if location_id == nil or player_id == nil then return end

	if self.draw_mode then
		self:setColor("blue")
	end

	local game = self.ap:get_player_game(player_id)
	local name = self.ap:get_location_name(location_id, game)
	self:printText(name, game)
end

---@param hint_status integer
---@return string
function LogWindow:getHintStatusStr(hint_status)
	if hint_status == 0 then -- HINT_UNSPECIFIED
		return GameTextGetTranslatedOrNot("$ap_hint_status_unspecified")
	elseif hint_status == 10 then -- HINT_NO_PRIORITY
		return GameTextGetTranslatedOrNot("$ap_hint_status_no_priority")
	elseif hint_status == 20 then -- HINT_AVOID
		return GameTextGetTranslatedOrNot("$ap_hint_status_avoid")
	elseif hint_status == 30 then -- HINT_PRIORITY
		return GameTextGetTranslatedOrNot("$ap_hint_status_priority")
	elseif hint_status == 40 then -- HINT_FOUND
		return GameTextGetTranslatedOrNot("$ap_hint_status_found")
	end
	return ""
end

---Prints a hint status token.
---@param token table
function LogWindow:printHintStatus(token)
	if self.draw_mode then
		local hint_status = token.hint_status or token.hintStatus
		if hint_status == 0 then -- HINT_UNSPECIFIED
			self:setColor("gray")
		elseif hint_status == 10 then -- HINT_NO_PRIORITY
			self:setColor("slateblue")
		elseif hint_status == 20 then -- HINT_AVOID
			self:setColor("salmon")
		elseif hint_status == 30 then -- HINT_PRIORITY
			self:setColor("plum")
		elseif hint_status == 40 then -- HINT_FOUND
			self:setColor("green")
		end
	end
	self:printText(token.text)
end

-- ref: https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#JSONMessagePart
function LogWindow:drawMessage(msg)
	if self.ap == nil then return end

	for _, token in ipairs(msg) do
		if self.draw_mode then
			if token.color then
				self:setColor(token.color)
			else
				self:setColor("white")
			end
		end

		if token.type ~= nil then
			if token.type == "player_id" then
				self:printPlayerId(token)
			elseif token.type == "item_id" then
				self:printItemId(token)
			elseif token.type == "location_id" then
				self:printLocationId(token)
			elseif token.type == "hint_status" then
				self:printHintStatus(token)
			elseif token.text ~= nil then
				self:printText(token.text)
			end
		elseif token.text ~= nil then
			self:printText(token.text)
		else
			self:setColor("red")
			self:printText("[UNKNOWN PRINTJSON TOKEN]")
		end
	end
end

---Computes the message height for processing its scroll size off screen
---@param msg any
---@return integer
function LogWindow:calcMessageHeight(msg)
	self.draw_mode = false
	self:resetPrinter()
	self:drawMessage(msg)
	self:newLogLine()
	self.draw_mode = true
	return self.printer.y
end

function LogWindow:drawMessageList()
	GuiZSet(self.gui, -5002)
	self:resetPrinter()
	self.printer.y = 0 - self.scroll.y

	for _, log in ipairs(self.message_log) do
		if self.printer.y >= 0 - log.height and self.printer.y <= self.scrollbox_height then
			self:drawMessage(log.msg)
			self:newLogLine()
		else
			-- Optimization: don't draw stuff that isn't being rendered
			self.printer.y = self.printer.y + log.height
		end
	end
end

function LogWindow:sortHints()
	local SortKeys = {
		function(hint) return self.ap:get_player_alias(hint.receiving_player) end,
		function(hint) return self.ap:get_item_name(hint.item, self.ap:get_player_game(hint.receiving_player)) end,
		function(hint) return self.ap:get_player_alias(hint.finding_player) end,
		function(hint) return self.ap:get_location_name(hint.location, self.ap:get_player_game(hint.finding_player)) end,
		function(hint) return hint.entrance end,
		function(hint) return self:getHintStatusStr(hint.status) end,
	}

	if self.hint_sorted_col > 0 then
		if self.hint_sorted_descending then
			table.sort(self.hints, function(a, b)
				return SortKeys[self.hint_sorted_col](a) > SortKeys[self.hint_sorted_col](b)
			end)
		else
			table.sort(self.hints, function(a, b)
				return SortKeys[self.hint_sorted_col](a) < SortKeys[self.hint_sorted_col](b)
			end)
		end
	end
end

function LogWindow:hintsHeaderClicked(col_num)
	if self.hint_sorted_col == col_num then
		self.hint_sorted_descending = not self.hint_sorted_descending
	else
		self.hint_sorted_col = col_num
		self.hint_sorted_descending = false
	end
	self:sortHints()
end

function LogWindow:drawHintList()
	local DrawKeys = {
		function(hint) self:printPlayerId({ text = hint.receiving_player }) end,
		function(hint) self:printItemId({ text = hint.item, player = hint.receiving_player }) end,
		function(hint) self:printPlayerId({ text = hint.finding_player }) end,
		function(hint) self:printLocationId({ text = hint.location, player = hint.finding_player }) end,
		function(hint) self:printText(hint.entrance) end,
		function(hint) self:printHintStatus({ text = self:getHintStatusStr(hint.status), hint_status = hint.status }) end,
	}

	GuiZSet(self.gui, -5002)
	self:resetPrinter()
	self.printer.y = 0 - self.scroll.y

	for _, hint in ipairs(self.hints) do
		local last_printer_y = self.printer.y

		-- Optimization: don't draw stuff that isn't being rendered
		if self.printer.y >= 0 - hint.height and self.printer.y <= self.hint_scrollbox_height then
			for i=1,6 do
				self.textarea_start_x = (i - 1) * self.hint_cell_width + 1
				self.textarea_end_x = i * self.hint_cell_width - 1
				self:resetPrinter()
				self.printer.x = self.textarea_start_x
				self.printer.y = last_printer_y

				DrawKeys[i](hint)
			end
		end
		self.printer.y = last_printer_y + hint.height
	end
end

---@param x number
---@param y number
---@param z number
---@param width number
---@param height number
---@param text string
---@return boolean
function LogWindow:tabButton(x, y, z, width, height, text, selected)
	if self.button_hovered[text] or selected then
		self:Color(unpack(color_map["white"]))
	else
		self:ColorGray()
	end

	self:SetZ(z - 1)
	local txt_wid, txt_hgt = self:GetTextDimension(text)
	GuiText(self.gui, x + (width - txt_wid) / 2, y + (height - txt_hgt) / 2, text)
	--self:AddOptionForNext(self.c.options.ForceFocusable) -- annoying brrrr sound
	local sprite = self.buttons.img
	if self.button_hovered[text] or selected then
		sprite = self.buttons.img_hl
	end
	self:Draw9Piece(x, y, z, width, height, sprite, sprite)

	local hovered = self:IsHovered()
	self.button_hovered[text] = hovered

	return hovered and self:IsMouseClicked()
end

function LogWindow:drawTabBar(x, y, tabs)
	local z = -5005
	for i, name in ipairs(tabs) do
		if self:tabButton(x, y, z, 50, 16, name, i == self.tab_idx) then
			self.tab_idx = i
		end
		x = x + 50 + 3
		z = z - 5
	end
end

function LogWindow:drawHintsHeader()
	local header = {
		GameTextGetTranslatedOrNot("$ap_hint_col_receiver"),
		GameTextGetTranslatedOrNot("$ap_hint_col_item"),
		GameTextGetTranslatedOrNot("$ap_hint_col_finder"),
		GameTextGetTranslatedOrNot("$ap_hint_col_location"),
		GameTextGetTranslatedOrNot("$ap_hint_col_entrance"),
		GameTextGetTranslatedOrNot("$ap_hint_col_status"),
	}

	local x = self.box_x + 8
	local y = self.box_y + 16 + 7
	for i,name in ipairs(header) do
		if self.button_hovered[name] then
			self:Color(unpack(color_map["white"]))
		else
			self:ColorGray()
		end

		self:TextCentered(x, y, name, self.hint_cell_width)
		local hovered = self:IsHovered()
		self.button_hovered[name] = hovered
		if hovered and self:IsMouseClicked() then
			print_error("Clicked " .. name)
			self:hintsHeaderClicked(i)
		end
		x = x + self.hint_cell_width
	end
end

function LogWindow:drawWindow()
	GuiSetNextNinePieceAlpha(0.5)
	self:Draw9Piece(self.box_x, self.box_y, -4000, self.box_width, self.box_height)
	if self:IsHovered() then
		-- Prevent shooting wand and whatever when interacting
		self:BlockInput()
	elseif self:IsLeftClicked() then
		-- Close the window by clicking outside of it
		self:close()
	end

	self:drawTabBar(self.box_x + 8, self.box_y + 4, { "Archipelago", "Hints" })

	if self.tab_idx == 1 then
		self.textarea_start_x = 0
		self.textarea_end_x = self.scrollbox_width

		GuiSetNextNinePieceAlpha(0.8)
		self:ScrollBoxFixed(self.box_x + 8, self.box_y + 16 + 7, -5000, self.scrollbox_width, self.scrollbox_height, math.max(self.scrollbox_height, self.total_log_height), "data/ui_gfx/decorations/9piece0_gray.png", 0, 0, self.drawMessageList)
		self.tailing_log = self.scroll.y >= self.tailing_y - 1
		self.tailing_y = math.max(self.tailing_y, self.scroll.y)

		-- TODO do something with self.shift_up_amt here so that deleted messages don't scroll everything up out of place

		if self.jump_to_end then
			self.jump_to_end = false
			self:ScrollToEnd()
			self.tailing_log = true
		end
	elseif self.tab_idx == 2 then
		self.textarea_start_x = 0
		self:drawHintsHeader()

		local y = self.box_y + 16 + 7
		GuiSetNextNinePieceAlpha(0.8)
		self:ScrollBoxFixed(self.box_x + 8, y + self.text_line_height, -5000, self.scrollbox_width, self.hint_scrollbox_height, math.max(self.hint_scrollbox_height, self.total_log_height), "data/ui_gfx/decorations/9piece0_gray.png", 0, 0, self.drawHintList)
	end
end

function LogWindow:addLogMessage(msg)
	if msg ~= nil and #msg > 0 then
		self.textarea_start_x = 0
		self.textarea_end_x = self.scrollbox_width

		local log_msg = {
			height = self:calcMessageHeight(msg),
			msg = msg
		}

		table.insert(self.message_log, log_msg)
		self.total_log_height = self.total_log_height + log_msg.height

		-- Delete oldest log item if we're at the limit
		if #self.message_log > self.log_limit then
			local removed_msg = table.remove(self.message_log, 1)
			self.total_log_height = self.total_log_height - removed_msg.height
			self.shift_up_amt = self.shift_up_amt + removed_msg.height
		end

		-- Attach the log history to the save file
		Globals.LogHistory:set_table(self.message_log)

		-- Follow log if it's currently open
		if self.visible and self.tailing_log then
			self.jump_to_end = true
		end
	end
end

function LogWindow:setHints(hints)
	self.hints = hints

	-- Compute max heights based on cell width
	self.textarea_start_x = 1
	self.textarea_end_x = self.hint_cell_width - 1
	for _,hint in ipairs(self.hints) do
		hint.height = math.max(
			self:calcMessageHeight({{ text = hint.entrance or "" }}),
			self:calcMessageHeight({{ type = "item_id", text = hint.item, player = hint.receiving_player }}),
			self:calcMessageHeight({{ type = "location_id", text = hint.location, player = hint.finding_player }})
		)
	end
	self:sortHints()
end

function LogWindow:update()
	if self.gui == nil then return end

	if not InputIsMouseButtonDown(self.c.codes.mouse.lc) then
		self.just_closed = false
	end
	self:updateDimensionsAndCalc()

	if not self.visible then return end
	self:StartFrame()
	self:drawWindow()
end

return LogWindow
