local Global = dofile("data/archipelago/lib/globals_manager.lua")
local JSON = dofile("data/archipelago/lib/json.lua")

local GlobalComplex = Global:extend()

function GlobalComplex:new(key_name)
  GlobalComplex.super.new(self, key_name)
end

function GlobalComplex:getTable(default_value)
	return JSON:decode(self:get(JSON:encode(default_value or {})))
end

function GlobalComplex:setTable(value)
	self:set(JSON:encode(value))
end

function GlobalComplex:append(value)
	local data = self:getTable()
	table.insert(data, value)
	self:setTable(data)
end

function GlobalComplex:addKey(key, value)
	local data = self:getTable()
	data[key] = value
	self:setTable(data)
end

function GlobalComplex:getKey(key, default_value)
	local data = self:getTable()
	return data[key] or default_value or {}
end

function GlobalComplex:reset()
	GlobalsSetValue(self.key, "{}")
end

return GlobalComplex
