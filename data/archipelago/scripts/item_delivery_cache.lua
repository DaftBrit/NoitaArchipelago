local SeedCache = dofile("data/archipelago/scripts/seeded_cache.lua")

local ItemCache = SeedCache:extend()

function ItemCache:new(cache_name)
	ItemCache.super.new(self, cache_name)
end

-- Assume/hope that json.lua doesn't write the keys as strings
function ItemCache:num_items()
  return #self:reference()
end

return ItemCache
