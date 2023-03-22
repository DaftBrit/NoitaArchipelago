local Cache = dofile("data/archipelago/lib/cache_manager.lua")
local Globals = dofile("data/archipelago/scripts/globals.lua")

local SeededCache = Cache:extend()

function SeededCache:new(cache_name)
	SeededCache.super.new(self, cache_name)
end

function SeededCache:get_filename()
	return "mods/archipelago/cache/" .. self.cache_name .. "_" .. Globals.Seed:get() .. "_" .. Globals.Player:get() .. ".json"
end

return SeededCache
