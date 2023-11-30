local SeedCache = dofile("data/archipelago/scripts/seeded_cache.lua")

local ItemCache = SeedCache:extend()

function ItemCache:new(cache_name)
	ItemCache.super.new(self, cache_name)
end

-- Assume/hope that json.lua doesn't write the keys as strings
function ItemCache:is_empty()
	for _ in pairs(self:reference()) do
		return false
	end
	return true
end

return ItemCache
