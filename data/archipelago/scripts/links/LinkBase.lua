local Object = dofile("data/archipelago/lib/classic/classic.lua") --- @type Object
local GlobalOption = dofile("data/archipelago/lib/cross_script_opt.lua") --- @type GlobalOption
local Cache = dofile("data/archipelago/scripts/caches.lua") --- @type Caches

---@class LinkBase : Object
---@field tag string
---@field setting_name string
---@field opt GlobalOption
---@field manager LinkManager
---@field opt_map {[integer]:string}
---@field opt_valid {[string]:number?}
local LinkBase = Object:extend()

---@param tag string
---@param setting_name string
---@param opt_map {[integer]:string}
function LinkBase:new(tag, setting_name, opt_map)
	self.tag = tag
	self.setting_name = setting_name
	self.opt = GlobalOption(setting_name:upper())
	self.opt_map = opt_map
	self.opt_valid = { yaml = 1, off = 1 }
	for _, optname in pairs(opt_map) do
		self.opt_valid[optname] = 1
	end
end

---Interface
---@param data table
function LinkBase:Received(data)
	error("Link interface not implemented")
end

---@param data table
function LinkBase:SendBounce(data)
	if self.manager ~= nil then
		self.manager:SendBouncePacket(data, self.tag)
	end
end

---Returns the actual option for this Link.
---If settings say "yaml" then it will look up the slot option and convert it to an option string.
---If any settings are invalid it defaults to "off".
---@return string
function LinkBase:GetSetting()
	local opt = Cache.Options:get(self.setting_name, "yaml")
	if opt == "yaml" then
		opt = self.opt_map[self.manager:GetSlotOption(self.setting_name)] or "off"
	end
	return opt
end

---@param connect_tags {[string]:any?}
function LinkBase:SyncSetting(connect_tags)
	Cache.Options:set(self.setting_name, self.opt:get())
	if self.opt:hasChanged() then
		self.opt:clearChanged()
	end

	local opt = self:GetSetting()
	if opt ~= "off" then
		connect_tags[self.tag] = 1
	else
		connect_tags[self.tag] = nil
	end
end

function LinkBase:InitSetting()
	local cached_opt = Cache.Options:get(self.setting_name, "yaml")
	if self.opt_valid[cached_opt] == nil then
		-- ensure it's always valid (corrupted, changed, etc)
		cached_opt = "yaml"
	end
	self.opt:set(cached_opt)
end

return LinkBase
