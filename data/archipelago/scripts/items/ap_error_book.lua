local ShopItems = dofile("data/archipelago/scripts/shopitem_utils.lua")
local APUtils = dofile("data/archipelago/scripts/ap_utils.lua")

function init(entity_id)
    local location_id = APUtils.getInternalVariableValue(entity_id, "ap_shop_data", "location_id")
    local x, y = EntityGetTransform(entity_id)
    if GameHasFlagRun("AP_LocationInfo_received") == true then
        ShopItems.generate_ap_shop_item_entity(location_id, x, y)
    end
end