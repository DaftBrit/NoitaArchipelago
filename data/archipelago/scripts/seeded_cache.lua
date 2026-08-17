local Cache = dofile("data/archipelago/lib/cache_manager.lua") --- @type Cache
local Globals = dofile("data/archipelago/scripts/globals.lua") --- @type Globals

---@class SeededCache : Cache
---@field super Cache
local SeededCache = Cache:extend()

function SeededCache:new(cache_name)
	SeededCache.super.new(self, cache_name)
end

---@return string
function SeededCache:get_filename()
	local path_parts = { self.cache_name, Globals.Seed:get(), Globals.RoomID:get(), Globals.PlayerSlot:get() }
	return "archipelago_cache/" .. table.concat(path_parts, "_") .. ".json"
end

return SeededCache
