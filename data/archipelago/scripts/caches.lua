local SeedCache = dofile("data/archipelago/scripts/seeded_cache.lua") ---@type SeededCache
local ItemCache = dofile("data/archipelago/scripts/item_delivery_cache.lua") ---@type ItemCache

--- @class Caches
local Caches = {
	ItemDelivery = ItemCache("delivered"), ---@type ItemCache
	LocationInfo = SeedCache("location_scouts_info"), ---@type SeededCache
	Options = SeedCache("options"), ---@type SeededCache
}

return Caches
