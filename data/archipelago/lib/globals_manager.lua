local Object = dofile("data/archipelago/lib/classic/classic.lua")

--- @class Global : Object
local GlobalImpl = Object:extend()

---@param key_name string
function GlobalImpl:new(key_name)
	self.key = key_name
end

--- Gets a global, returned as a string. Automatically converts `default_value` to a number.
---comment
---@param default_value any
---@return string
function GlobalImpl:get(default_value)
	default_value = default_value or ""
	return GlobalsGetValue(self.key, tostring(default_value))
end

--- Gets a global, returned as a number.
---@param default_value number
---@return number?
function GlobalImpl:get_num(default_value)
	return tonumber(self:get(default_value))
end

--- Sets a global, automatically converts `value` to a string.
---@param value any
function GlobalImpl:set(value)
	GlobalsSetValue(self.key, tostring(value))
end

function GlobalImpl:reset()
	GlobalsSetValue(self.key, "")
end

---@return boolean
function GlobalImpl:is_set()
	return self:get() ~= ""
end

return GlobalImpl
