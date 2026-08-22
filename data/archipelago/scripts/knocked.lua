local Globals = dofile("data/archipelago/scripts/globals.lua") ---@type Globals

local entity = EntityGetRootEntity(GetUpdatedEntityID())
if not EntityHasTag(entity, "player_unit") and not EntityHasTag(entity, "polymorphed_player") then
	return
end

local comp = EntityGetFirstComponentIncludingDisabled(entity, "CharacterDataComponent")
if comp == nil then return end

local vx, vy = ComponentGetValue2(comp, "mVelocity")

local causes = Globals.LastDamageCauses:get_table()
local counts = {}
for _, cause in ipairs(causes) do
	if cause ~= "" then
		counts[cause] = (counts[cause] or 0) + 1
	end
end
Globals.LastDamageCauses:reset()

local msg_builder = {}
for cause, amt in pairs(counts) do
	local nstr = ""
	if amt ~= 1 then
		nstr = " x" .. tostring(amt)
	end
	table.insert(msg_builder, cause .. nstr)
end

local cause = table.concat(msg_builder, ", ")
Globals.KnockbackLinkQueue:append({ x = vx, y = vy, cause = cause})
