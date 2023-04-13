local function ap_extend_snowcastle_cavern()
	local AP = dofile("data/archipelago/scripts/constants.lua")
	local Globals = dofile("data/archipelago/scripts/globals.lua")
	local ShopItems = dofile("data/archipelago/scripts/shopitem_utils.lua")

  -- Local constants
  local MAX_AP_ITEMS = AP.LAST_SECRET_SHOP_LOCATION_ID - AP.FIRST_SECRET_SHOP_LOCATION_ID + 1
  local HIISI_BASE_ID = 4  -- Hiisi Base

  -- Locals
  local num_items = 0

  -- Override of spawn_shopitem in the original file
  spawn_shopitem = function(x, y)
    local is_ap_shopitem = num_items < MAX_AP_ITEMS
    local location_id = AP.FIRST_SECRET_SHOP_LOCATION_ID + num_items
    local is_not_obtained = is_ap_shopitem and Globals.MissingLocationsSet:has_key(location_id)

    if is_ap_shopitem and is_not_obtained then
      ShopItems.generate_ap_shop_item(location_id, HIISI_BASE_ID, x, y)
    else
      generate_shop_item(x, y, false, nil)
    end
    num_items = num_items + 1
  end
end

ap_extend_snowcastle_cavern()
