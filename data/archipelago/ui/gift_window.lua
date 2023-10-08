local GiftWindow = {}

function GiftWindow:create()
	self.gui = GuiCreate()
end

function GiftWindow:update()
  if self.gui == nil then return end

	GuiStartFrame(self.gui)

  -- TODO  
end

return GiftWindow
