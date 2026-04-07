
---@class PauseMenu
---@field gui gui
local PauseMenu = {
	gui = GuiCreate()
}

---@param mod_version string
---@param slot_options SlotOpts?
---@param deathlink number
function PauseMenu:update(mod_version, slot_options, deathlink)
	local win_condition = ""
	local shop_price_multiplier = 1
	local hm_portals = ""
	if slot_options ~= nil then
		if slot_options.victory_condition ~= nil then
			win_condition = ({ "Greed Ending", "Pure Ending (11 Orbs)", "Peaceful Ending (33 Orbs)", "Yendor Ending (34 Orbs!?)" })[slot_options.victory_condition + 1]
		end
		shop_price_multiplier = slot_options.shop_price or 1
		hm_portals = ({ "Open", "Locked" })[(slot_options.lock_portals or 0) + 1]
	end

	local status = {
		"Archipelago Version: " .. mod_version,
		"Win Condition: " .. win_condition,
		"Deathlink: " .. ({"Off", "On", "Traps"})[deathlink + 1],
		"Shop Price Multiplier: x" .. tostring(shop_price_multiplier),
		"Holy Mountain Portals: " .. hm_portals,
	}

	GuiLayoutBeginVertical(self.gui, 12.5, 10, true)
	for _, msg in ipairs(status) do
		GuiColorSetForNextWidget(self.gui, 0.35, 0.35, 0.35, 0.5)
		GuiText(self.gui, 0, 0, msg)
	end
	GuiLayoutEnd(self.gui)
end

return PauseMenu
