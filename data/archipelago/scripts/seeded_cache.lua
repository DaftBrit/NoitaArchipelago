local Cache = dofile("data/archipelago/lib/cache_manager.lua")
local Globals = dofile("data/archipelago/scripts/globals.lua")

local SeededCache = Cache:extend()

function SeededCache:new(cache_name)
	SeededCache.super.new(self, cache_name)
end

function SeededCache:get_filename()
	if contains_element({"checksum_versions", "data_package_item_ids_to_name", "data_package_location_ids_to_name"}, self.cache_name) then
		return "archipelago_cache/" .. self.cache_name .. ".json"
	elseif self.cache_name == "player_games" then
		return "archipelago_cache/" .. self.cache_name .. "_" .. Globals.Seed:get() .. ".json"
	else
		return "archipelago_cache/" .. self.cache_name .. "_" .. Globals.Seed:get() .. "_" .. Globals.PlayerSlot:get() .. ".json"
	end
end

return SeededCache
