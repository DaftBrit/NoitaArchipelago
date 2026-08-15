local Object = dofile("data/archipelago/lib/classic/classic.lua")
local Global = dofile("data/archipelago/lib/globals_manager.lua")

--- @class GlobalOption : Object
--- @field value Global
--- @field flag_name string
--- @field initialized boolean
local GlobalOption = Object:extend()

---@param name string
function GlobalOption:new(name)
	self.value = Global("AP_OPT_" .. name)
	self.flag_name = "AP_CHANGED_OPT_" .. name
	self.initialized = false
end

---@return boolean
function GlobalOption:hasChanged()
	return GameHasFlagRun(self.flag_name)
end

---@return nil
function GlobalOption:clearChanged()
	return GameRemoveFlagRun(self.flag_name)
end

---@return string
function GlobalOption:get()
	return self.value:get()
end

---@param value any
function GlobalOption:set(value)
	self.value:set(value)
	GameAddFlagRun(self.flag_name)
end

---@return boolean
function GlobalOption:isInitialized()
	return self.initialized
end

return GlobalOption
