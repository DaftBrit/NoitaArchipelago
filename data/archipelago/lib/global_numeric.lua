local Global = dofile("data/archipelago/lib/globals_manager.lua")

--- @class GlobalNumeric : Global
--- @field protected super Global parent object
local GlobalNumeric = Global:extend()

---@param key_name string
function GlobalNumeric:new(key_name)
	GlobalNumeric.super.new(self, key_name)
end

--- Gets a global, returned as a number.
---@param default_value number?
---@return number
function GlobalNumeric:get(default_value)
	default_value = tonumber(default_value) or 0
	local result = GlobalNumeric.super.get(self, default_value)
	return tonumber(result) or 0
end

---@param value number
function GlobalNumeric:add(value)
	self:set(self:get() + tonumber(value))
end

---@param value number
function GlobalNumeric:subtract(value)
	self:set(self:get() - tonumber(value))
end

function GlobalNumeric:increment()
	self:add(1)
end

function GlobalNumeric:decrement()
	self:subtract(1)
end

return GlobalNumeric
