local LinkBase = dofile("data/archipelago/scripts/links/LinkBase.lua") ---@type LinkBase
dofile_once("data/archipelago/scripts/ap_utils.lua")

---@class DeathLink : LinkBase
---@field last_death_time number
local DeathLink = LinkBase:extend()

function DeathLink:new()
	DeathLink.super.new(self, "DeathLink", "death_link", { "on", "traps" })
	self.last_death_time = GameGetRealWorldTimeSinceStarted()
end

---@return boolean
function DeathLink:CanDeathLink()
	return self:GetSetting() ~= "off" and GameGetRealWorldTimeSinceStarted() > self.last_death_time + 2
end

function DeathLink:UpdateDeathTime()
	self.last_death_time = GameGetRealWorldTimeSinceStarted()
end

---@param data table
function DeathLink:Received(data)
	if not self:CanDeathLink() then return end

	local death_link_option = self:GetSetting()

	if data.cause == nil or data.cause == "" then
		local message = GameTextGet(death_link_option == "on" and "$ap_died" or "$ap_died_traps", tostring(data.source or "Unknown"))
		GamePrintImportant(message, "$ap_deathlink_triggered")
	else
		GamePrintImportant(data.cause, "$ap_deathlink_triggered")
	end

	local player = get_player()
	-- Don't try anything if the player doesn't exist (gj you dodged it)
	if player == nil then return end

	if death_link_option == "on" then
		if not DecreaseExtraLife(player) then
			local gsc_id = EntityGetFirstComponentIncludingDisabled(player, "GameStatsComponent")
			if gsc_id ~= nil then
				ComponentSetValue2(gsc_id, "extra_death_msg", data.cause)
			end
			EntityKill(player)
		end
	else
		BadTimes(true)
	end
	self:UpdateDeathTime()
end

function DeathLink:OnPlayerDied()
	if not self:CanDeathLink() then return end
	if not self.manager.ap then return end

	local death_msg = GetCauseOfDeath() or "skill issue"
	local slotname = self.manager.ap:get_slot()
	self:SendBounce({
		cause = slotname .. " died to " .. death_msg,
	})
	self:UpdateDeathTime()
end

return DeathLink
