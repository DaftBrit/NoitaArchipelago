local Object = dofile("data/archipelago/lib/classic/classic.lua")
local JSON = dofile("data/archipelago/lib/json.lua")
local Log = dofile("data/archipelago/scripts/logger.lua")
local Global = dofile("data/archipelago/lib/globals_manager.lua")

-- TODO: We should consider the following edge cases
--	1. We don't have write access or some other program took hold of the file
--	2. The file gets corrupted or the game crashes mid-write (for this we can maybe solve it with backups)

local Cache = Object:extend()

function Cache:new(cache_name)
	self.cache_name = cache_name
	self.cache_id = "AP_CACHE_" .. cache_name
	self.dirty_id = self.cache_id .. "_dirty"
	_G[self.dirty_id] = true
	_G[self.cache_id] = {}
end

function Cache:get_filename()
	return "archipelago_cache/" .. self.cache_name .. ".json"
end

function Cache:reset()
	_G[self.cache_id] = {}
	self:write()
end

function Cache:restore()
	local filename = self:get_filename()
	local f, err = io.open(filename, "r")
	if f == nil then
		Log.Warn("Failed to open cache for read: " .. filename .. "\n" .. tostring(err))
		return
	end

	_G[self.cache_id] = JSON:decode(f:read("*a")) or {}
	f:close()
	_G[self.dirty_id] = false
end

function Cache:write()
	local filename = self:get_filename()
	local f, err = io.open(filename, "w")
	if f == nil then
		Log.Error("Failed to open cache for write: " .. filename .. "\n" .. tostring(err))
		return
	end

	f:write(JSON:encode(_G[self.cache_id]))
	f:close()
	_G[self.dirty_id] = false
end

function Cache.make_key(...)
	local arg = {...}
	return table.concat(arg, "|")
end

function Cache:check_dirty()
	if _G[self.dirty_id] then
		self:restore()
	end
end

function Cache:set(key, value)
	self:check_dirty()
	_G[self.cache_id][key] = (value or true)
	self:write()
end

function Cache:get(key, default_value)
	self:check_dirty()

	local result = _G[self.cache_id][key]
	if result == nil and type(key) == "number" then
		result = _G[self.cache_id][tostring(key)]
	end
	return result or default_value
end

function Cache:is_set(key)
	self:check_dirty()
	return _G[self.cache_id][key] ~= nil
end

function Cache:is_empty()
	self:check_dirty()
	return rawequal(next(_G[self.cache_id]), nil)
end

function Cache:reference()
	return _G[self.cache_id]
end

return Cache
