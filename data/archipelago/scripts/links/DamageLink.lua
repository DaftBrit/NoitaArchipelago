local LinkBase = dofile("data/archipelago/scripts/links/LinkBase.lua") ---@type LinkBase
local Globals = dofile("data/archipelago/scripts/globals.lua") --- @type Globals

---@class DamageLink : LinkBase
---@field damage_saved number Damage saved over time when below the send threshold
local DamageLink = LinkBase:extend()

function DamageLink:new()
	LinkBase.super.new(self, "SharedDamage", "damage_link", { "on" })
end

---@param data table
function DamageLink:Received(data)
	local player = get_player()
	if player == nil then return end
	if type(data.damage_points) ~= "number" then return end

	local msg = GameTextGet("$ap_damagelink_received", tostring(data.damage_points), data.source or "Unknown")
	GamePrint(msg)

	EntityInflictDamage(player, data.damage_points / MagicNumbersGetValue("GUI_HP_MULTIPLIER"), "DAMAGE_CURSE", "DamageLink - " .. msg, "NONE", 0, 0)
end

function DamageLink:CheckDamageLinkQueue()
	if self:GetSetting() ~= "off" then
		local damagequeue = Globals.DamageLinkQueue:get_table()
		for _,amount in ipairs(damagequeue) do
			self.damage_saved = self.damage_saved + amount
		end

		if self.damage_saved > 1 then
			self:SendBounce({
				damage_points = math.floor(self.damage_saved),
			})
			self.damage_saved = self.damage_saved - math.floor(self.damage_saved)
		end
	end
	Globals.DamageLinkQueue:reset()
end
