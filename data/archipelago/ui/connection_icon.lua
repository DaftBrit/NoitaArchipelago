local ConnIcon = {}

local ID_BTN = 44470

local STATE = {
	DISCONNECTED = 0,
	CONNECTING = 1,
	CONNECTED = 2
}

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

function ConnIcon:img()
	return CONNECTION_STATES[self.state].img
end

function ConnIcon:msg()
	return CONNECTION_STATES[self.state].msg
end

function ConnIcon:create()
	self.gui = GuiCreate()
	self:setConnecting()
end

function ConnIcon:update()
	if self.gui == nil then return end

	GuiStartFrame(self.gui)

	local screen_width, screen_height = GuiGetScreenDimensions(self.gui)

	if not self.img_width or not self.img_height then
		self.img_width, self.img_height = GuiGetImageDimensions(self.gui, self:img())
	end

	local x = screen_width - self.img_width - 8
	local y = screen_height - self.img_height - 8
	GuiImageButton(self.gui, ID_BTN, x, y, "", self:img())

	-- Applies a tooltip to the button we just created
	local message = self.msg_override or self:msg()
	GuiTooltip(self.gui, message, "")
end

function ConnIcon:setState(state, message)
	self.msg_override = message
	self.state = state
end

function ConnIcon:setDisconnected(message)
	self:setState(STATE.DISCONNECTED, message)
end

function ConnIcon:setConnected()
	self:setState(STATE.CONNECTED)
end

function ConnIcon:setConnecting()
	self:setState(STATE.CONNECTING)
end

return ConnIcon
