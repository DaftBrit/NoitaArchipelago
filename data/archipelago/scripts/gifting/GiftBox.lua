local Object = dofile("data/archipelago/lib/classic/classic.lua") --- @type Object
local UUID = dofile_once("data/archipelago/lib/uuid.lua") --- @type UUID
local GiftGlue = dofile("data/archipelago/scripts/gifting/GiftGlue.lua") --- @type GiftGlue
local Cache = dofile("data/archipelago/scripts/caches.lua") --- @type Caches
local Log = dofile("data/archipelago/scripts/logger.lua") ---@type Logger
local JSON = dofile("data/archipelago/lib/json.lua")

--- @class GiftBox
--- @field ap APClient?
--- @field motherbox {[string]:MotherBoxEntry}
--- @field giftbox {[string]:GiftItem}
--- @field last_giftbox_update_time number
--- @field glue GiftGlue
local GiftBox = Object:extend()

--- @class GiftTrait
--- @field trait string
--- @field quality number?
--- @field duration number?

--- @class GiftItem
--- @field id string
--- @field item_name string
--- @field amount integer must be > 0
--- @field item_value integer?
--- @field traits GiftTrait[]
--- @field sender_slot integer
--- @field receiver_slot integer
--- @field sender_team integer
--- @field receiver_team integer
--- @field is_refund boolean

--- @class MotherBoxEntry
--- @field is_open boolean
--- @field accepts_any_gift boolean
--- @field desired_traits string[]
--- @field minimum_gift_data_version integer
--- @field maximum_gift_data_version integer

---
---	## MotherBox
---		- SetNotify the motherbox to keep recipients updated.
---		- InitMotherbox will also notify and we can confirm we've added ourselves while also getting the other players' info.
---		- ~~Once added we can save it to the options cache, and only use Get for future runs.~~ or not?
---
--- ## Giftbox
---		- Sending a gift - wait for the SetReply before removing it, since it contains the uuid in its new location.
---		- Taking a gift - only give the gift after the SetReply.
---		- Refunding a gift - only do this after taking it out of the giftbox. (take gift -> send refund gift)
---

function GiftBox:new()
	self.ap = nil
	self.motherbox = {}
	self.giftbox = {}
	self.last_giftbox_update_time = GameGetRealWorldTimeSinceStarted()
	self.glue = GiftGlue()
end

---@param ap APClient
function GiftBox:SetAP(ap)
	self.ap = ap
end

---@param slot integer?
---@return string
function GiftBox:PlayerNumStr(slot)
	if slot ~= nil then return tostring(slot) end
	return tostring(self.ap:get_player_number())
end

---@param slot integer?
---@return string
function GiftBox:GetGiftboxKey(slot)
	return "GiftBox;" .. tostring(self.ap:get_team_number()) .. ";" .. self:PlayerNumStr(slot)
end

---@return string
function GiftBox:GetMotherboxKey()
	return "GiftBoxes;" .. tostring(self.ap:get_team_number())
end

function GiftBox:InitMotherbox()
	local motherbox_slot_info = {
		[self:PlayerNumStr()] = {
			is_open = true,
			accepts_any_gift = true,
			desired_traits = { "Spell", "Wand" },
			minimum_gift_data_version = 3,
			maximum_gift_data_version = 3,
		},
		dummy = true -- treat as object instead of list (wtf)
	}

	self.ap:Set(self:GetMotherboxKey(), {}, true, {
		{ "update", motherbox_slot_info },
		{ "pop", "dummy" },
	})
end

function GiftBox:RequestGiftboxData()
	self.ap:Get({ self:GetGiftboxKey() })
end

---@param gift GiftItem
function GiftBox:SendGift(gift)
	gift.id = gift.id or UUID.generate()
	gift.sender_slot = gift.sender_slot or self.ap:get_player_number()
	gift.sender_team = gift.sender_team or self.ap:get_team_number()
	gift.receiver_team = gift.receiver_team or self.ap:get_team_number()
	gift.is_refund = gift.is_refund or false

	self.ap:Set(self:GetGiftboxKey(gift.receiver_slot), {}, true, {
		{ operation = "update", value = {
			[gift.id] = gift
		}}
	}, { giftbox_sent = true })
end

---@param gift GiftItem
function GiftBox:RefundGift(gift)
	local sender_slot = gift.sender_slot
	local sender_team = gift.sender_team

	gift.sender_slot = gift.receiver_slot
	gift.sender_team = gift.receiver_team
	gift.receiver_slot = sender_slot
	gift.receiver_team = sender_team
	gift.is_refund = true

	self.ap:Set(self:GetGiftboxKey(gift.receiver_slot), {}, true, {
		{ operation = "update", value = {
			[gift.id] = gift
		}}
	}, { giftbox_sent = true })
end

---@param gift_id string
function GiftBox:TakeGift(gift_id)
	self.ap:Set(self:GetGiftboxKey(), {}, true, {
		{ operation = "pop", value = gift_id }
	}, { giftbox_take = true })
end

---@param motherbox {[string]:MotherBoxEntry}
function GiftBox:ProcessMotherBox(motherbox)
	self.motherbox = motherbox
end

---@param giftbox {[string]:GiftItem}
function GiftBox:ProcessGiftBox(giftbox)
	self.giftbox = giftbox
end

---@param key string
---@param value any
---@param command {[string]: any}
function GiftBox:ParseReply(key, value, command)
	--- TODO:
	--- 1. Split SetReply and Retrieved to get the uuid that changed
	--- 2. Pass specifically which uuid was added/removed
	--- 3. Pass info to Glue
	--- 4. Tell UI to update itself
	if command.giftbox_sent ~= nil then
		-- a gift we sent
		Log.Info("GIFT SENT: " .. JSON:encode(value))
		self.glue:RemoveGiftFromWorld(value)
	elseif command.giftbox_take ~= nil then
		-- a gift we pulled out
		Log.Info("GIFT TAKE: " .. JSON:encode(value))
		self.glue:AddGiftToWorld(value)
	elseif key == self:GetGiftboxKey() then
		-- anything in our giftbox
		Log.Info("GIFT RECEIVED: " .. JSON:encode(value))
	elseif key == self:GetMotherboxKey() then
		-- mother box update
		Log.Info("MOTHERBOX RECEIVED: " .. JSON:encode(value))
	end
end

---@param data {[string]: any}
---@param command {[string]: any}
function GiftBox:OnSetReply(data, command)
	for k, v in pairs(data) do
		self:ParseReply(k, v, command)
	end
end

return GiftBox
