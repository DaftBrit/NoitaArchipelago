local SeedCache = dofile("data/archipelago/scripts/seeded_cache.lua")
local ItemCache = dofile("data/archipelago/scripts/item_delivery_cache.lua")

return {
	ItemDelivery = ItemCache("delivered"),
	LocationInfo = SeedCache("location_scouts_info"),
}
