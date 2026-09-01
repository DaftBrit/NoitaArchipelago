local Object = dofile("data/archipelago/lib/classic/classic.lua")
local Log = dofile("data/archipelago/scripts/logger.lua") ---@type Logger
local JSON = dofile("data/archipelago/lib/json.lua")

--- @class LinkManager : Object
--- @field uuid string
--- @field ap APClient?
--- @field links {[string]: LinkBase}
--- @field slot_options SlotOpts?
local LinkManager = Object:extend()

---@param uuid string
function LinkManager:new(uuid)
	self.uuid = uuid
	self.links = {}
end

---@param ap APClient?
function LinkManager:SetAP(ap)
	self.ap = ap
end

---@param slot_options SlotOpts?
function LinkManager:SetSlotOptions(slot_options)
	self.slot_options = slot_options
end

---@param ... LinkBase
function LinkManager:RegisterLinks(...)
	for _, link in ipairs({...}) do
		link.manager = self
		self.links[link.tag] = link
	end
end

---Defaults to 0 (off) when not available
---@param name string
---@return integer
function LinkManager:GetSlotOption(name)
	return self.slot_options and self.slot_options[name] or 0
end

---@param connect_tags {[string]:any?}
function LinkManager:SyncSettings(connect_tags)
	for _, link in pairs(self.links) do
		link:SyncSetting(connect_tags)
	end
end

---@param connect_tags {[string]:any?}
function LinkManager:InitSettings(connect_tags)
	for _, link in pairs(self.links) do
		link:InitSetting()
	end
	self:SyncSettings(connect_tags)
end

---@param data {[string]: any}
---@param tag string
function LinkManager:SendBouncePacket(data, tag)
	if self.ap ~= nil and self.slot_options ~= nil then
		-- Common link fields
		data.source = self.ap:get_slot()
		data.uuid = self.uuid
		data.time = self.ap:get_server_time()

		Log.Info("Sending bounce for " .. tag .. ": " .. JSON:encode(data))
		self.ap:Bounce(data, nil, nil, { tag })
	end
end

---@param msg {[string]: any}
---@return boolean
function LinkManager:ProcessBounce(msg)
	local data = msg["data"]
	if data == nil then return false end

	local has_tag = {}
	for _,tag in ipairs(msg["tags"]) do
		has_tag[tag] = true
	end

	local supported = false
	for tag, link in pairs(self.links) do
		if has_tag[tag] then
			if data["source"] ~= self.ap:get_slot() or data["uuid"] ~= self.uuid then
				link:Received(data)
			end
			supported = true
		end
	end
	return supported
end

---@return {[string]:string}
function LinkManager:GetAllOptions()
	local result = {}
	if self.slot_options ~= nil then
		for tag, link in pairs(self.links) do
			result[tag] = link:GetSetting()
		end
	end
	return result
end

return LinkManager
