local Object = dofile("data/archipelago/lib/classic/classic.lua")
local JSON = dofile("data/archipelago/lib/json.lua")

-- TODO: We should consider the following edge cases
--	1. We don't have write access or some other program took hold of the file
--	2. The file gets corrupted or the game crashes mid-write (for this we can maybe solve it with backups)

local Cache = Object:extend()

function Cache:new(cache_name)
	self.cache_name = cache_name
	self.cache = {}
end

function Cache:get_filename()
	return "mods/archipelago/cache/" .. self.cache_name .. ".json"
end

function Cache:reset()
	self.cache = {}
	self:write()
end

function Cache:restore()
	local f = io.open(self:get_filename(), "r")
	self.cache = JSON:decode(f:read("*a"))
	f:close()
end

function Cache:write()
	local f = io.open(self:get_filename(), "w")
	f:write(JSON:encode(self.cache))
	f:close()
end

function Cache.make_key(...)
	local arg = {...}
	return table.concat(arg, "|")
end

function Cache:set(key, value)
	self.cache[key] = (value or true)
	self:write()
end

function Cache:get(key, default_value)
	return self.cache[key] or default_value
end

function Cache:is_set(key)
	return self.cache[key] ~= nil
end

return Cache
