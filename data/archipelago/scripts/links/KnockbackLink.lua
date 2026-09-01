local LinkBase = dofile("data/archipelago/scripts/links/LinkBase.lua") ---@type LinkBase
local Globals = dofile("data/archipelago/scripts/globals.lua") --- @type Globals

---@class KnockbackLink : LinkBase
local KnockbackLink = LinkBase:extend()

function KnockbackLink:new()
	KnockbackLink.super.new(self, "KnockbackLink", "knockback_link", { "on" })
end

---@param data table
function KnockbackLink:Received(data)
	local player = get_player_always()
	if player == nil then return end
	if type(data.value) ~= "table" then return end

	if GameGetGameEffect(player, "KNOCKBACK_IMMUNITY") ~= 0 or GameGetGameEffect(player, "PROTECTION_ALL") ~= 0 then
		local msg = GameTextGet("$ap_knockbacklink_immune", data.source or "Unknown")
		GamePrint(msg)
		return
	end

	local msg = GameTextGet("$ap_knockbacklink_received", data.source or "Unknown", data.cause or "Unknown")
	GamePrint(msg)

	-- TODO maybe just use an invisible bullet instead?
	local effect = LoadGameEffectEntityTo(player, "data/entities/misc/effect_knockback.xml")
	local lua_comp = EntityGetFirstComponent(effect, "LuaComponent", "ap_knockback")
	if lua_comp ~= nil then
		EntityRemoveComponent(effect, lua_comp)
	end

	local char_data = EntityGetFirstComponent(player, "CharacterDataComponent")
	if char_data ~= nil then
		local vx = (data.value.x or 0) * 2
		local vy = -(data.value.y or 60) * 2
		ComponentSetValue2(char_data, "mVelocity", vx, vy)
	end
end

function KnockbackLink:CheckKnockbackLinkQueue()
	if self:GetSetting() ~= "off" then
		local knockbacks = Globals.KnockbackLinkQueue:get_table()
		local vx = 0
		local vy = 0
		local causes = {}
		for _,knock in ipairs(knockbacks) do
			vx = vx + knock.x
			vy = vy + knock.y
			table.insert(causes, knock.cause)
		end

		vx = math.floor(vx * 0.5)
		vy = -math.floor(vy * 0.5)

		if math.abs(vx) >= 5 or math.abs(vy) >= 5 then
			self:SendBounce({
				cause = table.concat(causes, ", "),
				value = {
					x = vx,
					y = vy,
				},
			})
		end
	end
	Globals.KnockbackLinkQueue:reset()
end

return KnockbackLink
