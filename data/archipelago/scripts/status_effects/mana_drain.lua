local entity = GetUpdatedEntityID()
local player = EntityGetRootEntity(entity)

local inventory = GameGetAllInventoryItems(player) or {}
for _, item in ipairs(inventory) do
	print_error("item...")
	local abil = EntityGetFirstComponentIncludingDisabled(item, "AbilityComponent")
	if abil ~= nil then
		local mana = tonumber(ComponentGetValue2(abil, "mana")) or 0
		local charge_speed = ComponentGetValue2(abil, "mana_charge_speed")
		ComponentSetValue2(abil, "mana", math.max(mana - charge_speed / 45, 0))
	end
end
