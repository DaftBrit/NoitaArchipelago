local Globals = dofile("data/archipelago/scripts/globals.lua")
local IncomingGift = dofile("data/archipelago/ui/gift_translate_incoming.lua")

dofile_once("data/scripts/lib/utilities.lua")

local GiftWindow = dofile("data/archipelago/lib/ui_lib.lua") --- @class UI_class

local ACCESS_RADIUS2 = 20*20


function GiftWindow:create(ap, gifting)
	self:New()
	self:updateDimensionsAndCalc()

	self.ap = ap
	self.gifting = gifting

	self.gift_list = {}

	-- Sample gifts (for testing)
	self.gift_list = {
		{
			id = "1",
			item_name = "Wand",
			amount = 1,
			traits = {
				-- Universal traits, tells Gifting system and other games what it is
				{ trait = "Wand", quality = 3 }, -- quality = tier
				-- { trait = "Legendary" }, -- if wand is rare
				{ trait = "RangedWeapon" },
				{ trait = "Weapon" },

				-- Appearance traits, determines the wand graphics so it appears the same in other clients
				{ trait = "noita_wand_image", quality = 958 }, -- appearance
				{ trait = "noita_wand_grip_x", quality = 2 },
				{ trait = "noita_wand_grip_y", quality = 5 },
				{ trait = "noita_wand_tip_x", quality = 21 },
				{ trait = "noita_wand_tip_y", quality = 5 },

				-- Stats and specifications
				{ trait = "noita_wand_reload_time", quality = 3 }, -- reload time after casting all spells
				{ trait = "noita_wand_fire_rate_wait", quality = 10 }, -- fire rate cooldown
				{ trait = "noita_wand_spread_degrees", quality = 6 }, -- spread
				{ trait = "noita_wand_speed_multiplier", quality = 1.2 }, -- speed
				{ trait = "noita_wand_capacity", quality = 5 }, -- number of slots
				{ trait = "noita_wand_shuffle" }, -- Whether spells on the wand are shuffled each time it's fired
				{ trait = "noita_wand_actions_per_round", quality = 1 }, -- number of spells shot each time it's fired
				{ trait = "noita_wand_mana_max", quality = 400 }, -- Max mana
				{ trait = "noita_wand_mana_charge_speed", quality = 40 }, -- Mana charge speed

				-- Spells on the wand
				{ trait = "noita_wand_always_cast_DIGGER" }, -- trait is always_cast_SPELLID
				{ trait = "noita_wand_spell_1_LIGHT_BULLET" }, -- wand_spell_SLOTNUMBER_SPELLID
				{ trait = "noita_wand_spell_2_LIGHT_BOMB", duration = 2 }, -- duration is remaining charges of the spell
			},
			sender_slot = 1,
			receiver_slot = 1,
			sender_team = 1,
			receiver_team = 1,
		},
		{
			id = "2",
			item_name = "Bomb",
			amount = 1,
			traits = {
				{ trait = "Bomb", duration = 5 },
				{ trait = "Spell", duration = 2 }, -- duration = remaining charges
			},
			sender_slot = 1,
			receiver_slot = 1,
			sender_team = 1,
			receiver_team = 1,
		},
		{
			id = "3",
			item_name = "Acid Potion",
			amount = 1,
			traits = {
				{ trait = "Potion", duration = 100 }, -- duration = quantity * effect length
				{ trait = "Container", duration = 100 }, -- duration = max quantity
				{ trait = "Acid", duration = 100 }, -- duration = quantity * effect length
			},
			sender_slot = 1,
			receiver_slot = 1,
			sender_team = 1,
			receiver_team = 1,
		},
		{
			id = "4",
			item_name = "Bomb",
			amount = 1,
			traits = {
				{ trait = "Bomb", duration = 5 },
			},
			sender_slot = 1,
			receiver_slot = 1,
			sender_team = 1,
			receiver_team = 1,
		},
		{
			id = "5",
			item_name = "Emerald Tablet of Thoth",
			amount = 1,
			traits = {
				{ trait = "Book", quality = 1 }, -- quality = book type?
				{ trait = "Stone" },
				{ trait = "Green" },
			},
			sender_slot = 1,
			receiver_slot = 1,
			sender_team = 1,
			receiver_team = 1,
		},
		{
			id = "6",
			item_name = "Egg",
			amount = 1,
			traits = {
				{ trait = "Egg" },
				{ trait = "Red" }, -- Colour determines egg type if not name
			},
			sender_slot = 1,
			receiver_slot = 1,
			sender_team = 1,
			receiver_team = 1,
		},
		{
			id = "7",
			item_name = "Silver Pouch",
			amount = 1,
			traits = {
				{ trait = "Container", duration = 100 }, -- duration = max quantity
				{ trait = "Silver", duration = 66 },
				{ trait = "Snow", duration = 30 },
				{ trait = "Grass", duration = 4 },
			},
			sender_slot = 1,
			receiver_slot = 1,
			sender_team = 1,
			receiver_team = 1,
		},
		{
			id = "8",
			item_name = "Broken Wand",
			amount = 1,
			traits = {
				{ trait = "Wand" },
				{ trait = "Broken" },
			},
			sender_slot = 1,
			receiver_slot = 1,
			sender_team = 1,
			receiver_team = 1,
		},
		{
			id = "9",
			item_name = "Shiny Orb",
			amount = 1,
			traits = {
				{ trait = "GoldenRelic" },
			},
			sender_slot = 1,
			receiver_slot = 1,
			sender_team = 1,
			receiver_team = 1,
		},
	}

	self:close()
end


function GiftWindow:updateDimensionsAndCalc()
	self:UpdateDimensions()

	self.box_x = math.floor(self.dim.x / 3)
	self.box_y = math.floor(self.dim.y / 5)
	self.box_width = self.dim.x - self.box_x * 2
	self.box_height = self.dim.y - self.box_y * 2
end


function GiftWindow:open()
	Globals.GiftMailboxOpen:set(1)
	self.was_open = true
end


function GiftWindow:close()
	Globals.GiftMailboxOpen:reset()
	self.was_open = false
end


function GiftWindow:is_open()
	return self.gui ~= nil and Globals.GiftMailboxOpen:is_set()
end


-- ?????? Maybe take an arg and call this with all tracked gifts, gifts go in a cache maybe?
function GiftWindow:refresh_gifts()
end


function GiftWindow:show_gift_entry(name, value, width)
	GuiBeginAutoBox(self.gui)

	GuiLayoutBeginHorizontal(self.gui, 0, 0, false, 8, 8)
    -- TODO
    --GuiImage(self.gui, ID_BTN_ICON + value, 0, 0, self:get_gift_icon())
	GuiText(self.gui, 0, 0, name)
	GuiLayoutEnd(self.gui)

	GuiZSetForNextWidget(self.gui, 50)
	GuiEndAutoBoxNinePiece(self.gui, -1, width)
end


function GiftWindow:show_gifts(width)
	GuiLayoutBeginVertical(self.gui, 0, 0)

  -- read/iterate gifts
  -- self:show_gift_entry...

	GuiLayoutEnd(self.gui)
end


function GiftWindow:should_be_open()
	if not self:is_open() then
		return false
	end

	local player_entity = get_player()
	if player_entity == nil then return false end

	local player_x, player_y = EntityGetTransform(player_entity)
	local sendbox_entity = EntityGetClosestWithTag(player_x, player_y, "ap_mailbox")
	if sendbox_entity == nil then return false end

	local box_x, box_y = EntityGetTransform(sendbox_entity)
	return get_distance2(player_x, player_y, box_x, box_y) < ACCESS_RADIUS2
end


function GiftWindow:drawGift(gift, y)
	GuiLayoutBeginHorizontal(self.gui, 0, y, true)
	self:Image(0, 0, "data/archipelago/ui/games/ap.png")

	self:ColorWhite()
	self:Text(0, 0, gift.item_name or "<UNKNOWN>")

	self:ColorGray()
	if gift.amount and gift.amount > 1 then
		self:Text(0, 0, " x " .. tostring(gift.amount))
	end

	GuiLayoutEnd(self.gui)
end


function GiftWindow:drawGiftList()
	GuiZSet(self.gui, -5002)
	local y = 0 - self.scroll.y

	for _, gift in ipairs(self.gift_list) do
		if y >= 0 - 16 and y <= self.box_height then
			self:drawGift(gift, y)
		end
		y = y + 16
	end
end


function GiftWindow:drawWindow()
	self:SetNext9PieceAlpha(0.5)
	self:Draw9Piece(self.box_x - 8, self.box_y - 11 - 4, -4000, self.box_width + 16, self.box_height + 11 + 12)
	if self:IsHovered() then
		-- Prevent shooting wand and whatever when interacting
		self:BlockInput()
	elseif self:IsLeftClicked() then
		-- Close the window by clicking outside of it
		self:close()
	end

	self:SetNext9PieceAlpha(0.8)
	-- TODO calc list height
	self:ScrollBoxFixed(self.box_x, self.box_y, -5000, self.box_width, self.box_height, #self.gift_list * 40 + 40, "data/ui_gfx/decorations/9piece0_gray.png", 0, 0, self.drawGiftList)
end


function GiftWindow:update()
	if self.gui == nil then return end

	self:updateDimensionsAndCalc()

	if self:should_be_open() then
		self:StartFrame()
		self:drawWindow()
		self.was_open = true
	elseif self:is_open() or self.was_open then
		self:close()
	end
end

return GiftWindow
