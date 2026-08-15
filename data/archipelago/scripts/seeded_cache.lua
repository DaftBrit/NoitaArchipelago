local Cache = dofile("data/archipelago/lib/cache_manager.lua") --- @type Cache
local Globals = dofile("data/archipelago/scripts/globals.lua") --- @type Globals

---@class SeededCache : Cache
local SeededCache = Cache:extend()

function SeededCache:new(cache_name)
	SeededCache.super.new(self, cache_name)
end

---@return string
function SeededCache:get_filename()
	return "archipelago_cache/" .. self.cache_name .. "_" .. Globals.Seed:get() .. "_" .. Globals.PlayerSlot:get() .. ".json"
end

return SeededCache
