local Global = dofile("data/archipelago/lib/globals_manager.lua")
local JSON = dofile("data/archipelago/lib/json.lua")

local GlobalComplex = Global:extend()

function GlobalComplex:new(key_name)
	GlobalComplex.super.new(self, key_name)
end

function GlobalComplex:get_table(default_value)
	return JSON:decode(self:get(JSON:encode(default_value or {})))
end

function GlobalComplex:set_table(value)
	self:set(JSON:encode(value))
end

function GlobalComplex:append(value)
	local data = self:get_table()
	table.insert(data, value)
	self:set_table(data)
end

function GlobalComplex:add_key(key, value)
	local data = self:get_table()
	data[key] = value
	if value == nil then
		data[tostring(key)] = value
	end
	self:set_table(data)
end

function GlobalComplex:get_key_raw(key)
	local data = self:get_table()
	local result = data[key]
	if result == nil and type(key) == "number" then
		result = data[tostring(key)]
	end
	return result
end

function GlobalComplex:get_key(key, default_value)
	return self:get_key_raw(key) or default_value or {}
end

function GlobalComplex:has_key(key)
	return self:get_key_raw(key) ~= nil
end

function GlobalComplex:remove_key(key)
	self:add_key(key, nil)
end

function GlobalComplex:reset()
	GlobalsSetValue(self.key, "{}")
end

return GlobalComplex
