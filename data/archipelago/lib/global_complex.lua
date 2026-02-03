local Global = dofile("data/archipelago/lib/globals_manager.lua")
local JSON = dofile("data/archipelago/lib/json.lua")

--- @class GlobalComplex : Global
local GlobalComplex = Global:extend()

---@param str string
---@return string
local function encodeXML(str)
	local result = str:gsub("\"", "&quot;")
	return result
end

---@param str string
---@return string
local function decodeXML(str)
	local result = str:gsub("&quot;", "\"")
	return result
end

---@param key_name string
function GlobalComplex:new(key_name)
	GlobalComplex.super.new(self, key_name)
end

---@param default_value table|nil
---@return table
function GlobalComplex:get_table(default_value)
	local default_value_str = JSON:encode(default_value or {})
	local ret_val_str = self:get(default_value_str)
	return JSON:decode(decodeXML(ret_val_str))
end

---@param value table
function GlobalComplex:set_table(value)
	local tbl_str = encodeXML(JSON:encode(value))
	self:set(tbl_str)
end

---@param value any
function GlobalComplex:append(value)
	local data = self:get_table()
	table.insert(data, value)
	self:set_table(data)
end

---@param key any
---@param value any
function GlobalComplex:add_key(key, value)
	local data = self:get_table()
	data[key] = value
	if value == nil then
		data[tostring(key)] = value
	end
	self:set_table(data)
end

---@param key any
---@return any
function GlobalComplex:get_key_raw(key)
	local data = self:get_table()
	local result = data[key]
	if result == nil and type(key) == "number" then
		result = data[tostring(key)]
	end
	return result
end

---@param key any
---@param default_value any
---@return any
function GlobalComplex:get_key(key, default_value)
	return self:get_key_raw(key) or default_value or {}
end

---@param key any
---@return boolean
function GlobalComplex:has_key(key)
	return self:get_key_raw(key) ~= nil
end

---@param key any
function GlobalComplex:remove_key(key)
	self:add_key(key, nil)
end

function GlobalComplex:reset()
	GlobalsSetValue(self.key, "{}")
end

return GlobalComplex
