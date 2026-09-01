local LinkBase = dofile("data/archipelago/scripts/links/LinkBase.lua") ---@type LinkBase
local Globals = dofile("data/archipelago/scripts/globals.lua") --- @type Globals
dofile_once("data/archipelago/scripts/trap_utils.lua")

---@class TrapLink : LinkBase
local TrapLink = LinkBase:extend()

function TrapLink:new()
	TrapLink.super.new(self, "TrapLink", "trap_link", { "on" })
end

---@param data table
function TrapLink:Received(data)
	-- TODO sync fungals and other RNG
	RecvTrapLink(data["source"], data["trap_name"], data["noita_id"])
end

function TrapLink:CheckTrapLinkQueue()
	local traps = Globals.TrapLinkQueue:get_table()
	for _,trap in ipairs(traps) do
		-- TODO send fungals and other RNG for trap sync
		self:SendBounce({
			trap_name = trap.trap_name,
			noita_id = trap.noita_id,
		})
	end
	Globals.TrapLinkQueue:reset()
end

return TrapLink
