local entity_id = GetUpdatedEntityID()

local discount_mem = EntityGetFirstComponentIncludingDisabled(entity_id, "VariableStorageComponent", "ap_last_update_price")
local itemcost_comp = EntityGetFirstComponentIncludingDisabled(entity_id, "ItemCostComponent")
if discount_mem == nil or itemcost_comp == nil then return end

local cost = ComponentGetValue2(itemcost_comp, "cost") ---@type integer
local discounts = tonumber(GlobalsGetValue("AP_PERK_REROLL_DISCOUNTS", "0")) or 0
local applied_discounts = ComponentGetValue2(discount_mem, "value_int") ---@type integer

if applied_discounts < discounts then
	for _ = applied_discounts, discounts - 1 do
		cost = math.floor(cost * 0.9)
	end

	ComponentSetValue2(discount_mem, "value_int", discounts)
	ComponentSetValue2(itemcost_comp, "cost", cost)
end
