local Object = dofile("data/archipelago/lib/classic/classic.lua")

local GlobalImpl = Object:extend()

function GlobalImpl:new(key_name)
	self.key = key_name
end

-- Gets a global, returned as a string. Automatically converts `default_value` to a number.
function GlobalImpl:get(default_value)
	return GlobalsGetValue(self.key, tostring(default_value) or "")
end

-- Gets a global, returned as a number.
function GlobalImpl:get_num(default_value)
	return tonumber(self:get(default_value))
end

-- Sets a global, automatically converts `value` to a string.
function GlobalImpl:set(value)
	GlobalsSetValue(self.key, tostring(value))
end

function GlobalImpl:reset()
	GlobalsSetValue(self.key, "")
end

function GlobalImpl:is_set()
	return self:get() ~= ""
end

return GlobalImpl
