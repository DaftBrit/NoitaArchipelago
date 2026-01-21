---@class ConnIcon
---@field msg_override string?
---@field state STATE
---@field gui gui
---@field button_pressed boolean?
local ConnIcon = {}

--- @enum STATE
local STATE = {
	DISCONNECTED = 0,
	CONNECTING = 1,
	CONNECTED = 2
}

--- @class ConnState
--- @field img string
--- @field msg string

--- @type ConnState[]
local CONNECTION_STATES = {
	[STATE.DISCONNECTED] = {
		img = "data/archipelago/ui/disconnected.png",
		msg = "$ap_not_connected_desc",
	},
	[STATE.CONNECTING] = {
		img = "data/archipelago/ui/connecting.png",
		msg = "$ap_connecting_desc",
	},
	[STATE.CONNECTED] = {
		img = "data/archipelago/ui/connected.png",
		msg = "$ap_connected_desc",
	},
}

---@return string
function ConnIcon:img()
	return CONNECTION_STATES[self.state].img
end

---@return string
function ConnIcon:msg()
	return CONNECTION_STATES[self.state].msg
end

function ConnIcon:create()
	self.gui = GuiCreate()
	self:setConnecting()
end

function ConnIcon:updateDimensions()
	local screen_width, screen_height = GuiGetScreenDimensions(self.gui)

	self.screen_width = screen_width
	self.screen_height = screen_height

	if not self.img_width or not self.img_height then
		self.img_width, self.img_height = GuiGetImageDimensions(self.gui, self:img())
	end
end

function ConnIcon:drawMainButton()
	GuiIdPushString(self.gui, "MAIN BTN")

	local x = self.screen_width - self.img_width - 8
	local y = self.screen_height - self.img_height - 8
	local result = GuiImageButton(self.gui, 0, x, y, "", self:img())

	-- Applies a tooltip to the button we just created
	local message = self.msg_override or self:msg()
	GuiTooltip(self.gui, message, "")

	GuiIdPop(self.gui)
	return result
end

function ConnIcon:update()
	if self.gui == nil then return end
	self:updateDimensions()

	GuiStartFrame(self.gui)

	self.button_pressed = self:drawMainButton()
end

---@param state STATE
---@param message string?
function ConnIcon:setState(state, message)
	self.msg_override = message
	self.state = state
end

---@param message string?
function ConnIcon:setDisconnected(message)
	self:setState(STATE.DISCONNECTED, message)
end

---@param message string?
function ConnIcon:setConnected(message)
	self:setState(STATE.CONNECTED, message)
end

function ConnIcon:setConnecting()
	self:setState(STATE.CONNECTING)
end

---@return boolean
function ConnIcon:pressed()
	return self.button_pressed or false
end

return ConnIcon
