local Globals = dofile("data/archipelago/scripts/globals.lua")
dofile_once("data/scripts/lib/utilities.lua")

local GiftWindow = {}

local ID_SCROLL_GIFTS = 54576
local ID_BTN_REFRESH = 54578

local ID_BTN_ACCEPT_GIFT = 55001
local ID_BTN_REJECT_GIFT = 65001
local ID_BTN_ICON = 75001

function GiftWindow:create(ap, gifting)
	self.gui = GuiCreate()
	self.ap = ap
	self.gifting = gifting
	self:close()
end

function GiftWindow:open()
	Globals.GiftWindowOpen:set(1)
end

function GiftWindow:close()
	Globals.GiftWindowOpen:reset()
end

function GiftWindow:is_open()
	return self.gui ~= nil and Globals.GiftWindowOpen:is_set()
end

function GiftWindow:refresh()
  -- TODO
end

local SUPPORTED_TRAITS = {
  ["Wand"] = true,
  ["Spell"] = true,
  ["Book"] = true,
  ["Stone"] = true,
  ["Grass"] = true,
  ["Flower"] = true,
  ["Speed"] = true,
  ["Monster"] = true,
  ["Fiber"] = true,
  ["Material"] = true,
  ["Ore"] = true,
  ["Trap"] = true,
  ["Wood"] = true,
  ["Egg"] = true,
  ["Food"] = true,
  ["Fruit"] = true,
  ["Heal"] = true,
  ["Vegetable"] = true,
  ["Animal"] = true,
  ["Coal"] = true,
  ["Consumable"] = true,
  ["Copper"] = true,
  ["Drink"] = true,
  ["Gold"] = true,
  ["Metal"] = true,
  ["Mineral"] = true,
  ["Resource"] = true,
  ["Seed"] = true,
  ["Seeds"] = true,
  ["Silver"] = true,
  ["Vine"] = true,
  ["Weapon"] = true,
  ["Zombie"] = true,
  ["Mana"] = true,
  ["Bomb"] = true,
  ["Buff"] = true,
  ["Cooking"] = true,
  ["Crystal"] = true,
  ["Damage"] = true,
  ["Fish"] = true,
  ["Gem"] = true,
  ["Iron"] = true,
  ["Life"] = true,
  ["Meat"] = true,
  ["Radioactive"] = true,
  ["Slowness"] = true,
  ["Steel"] = true,
  ["Cure"] = true,
  ["Cold"] = true,
  ["Heat"] = true,
}

local meats = {
  ["Meat"] = "meat",
  ["Lightly-Cooked Meat"] = "meat_warm",
  ["Cooked Meat"] = "meat_hot",
  ["Fully-Cooked Meat"] = "meat_done",
  ["Burned Meat"] = "meat_burned",
  ["Ambiguous Meat"] = "meat_confusion",
  ["Cursed Meat"] = "meat_cursed",
  ["Dry Cursed Meat"] = "meat_cursed_dry",
  ["Slimy Cursed Meat"] = "meat_slime_cursed",
  ["Ethereal Meat"] = "meat_teleport",
  ["Frog Meat"] = "meat_frog",
  ["Meat of an Innocent Creature"] = "meat_helpless",
  ["Rotten Meat"] = "rotten_meat",
  ["Stinky Meat"] = "meat_polymorph_protection",
  ["Wobbly Meat"] = "meat_fast",
  ["Worm Meat"] = "meat_worm",
  ["Slimy Meat"] = "meat_slime",
  ["Green Slimy Meat"] = "meat_slime_green",
  ["Toxic Meat"] = "rotten_meat_radioactive",
  ["Unstable Meat"] = "meat_polymorph"
}


local function preprocess_gift(gift)
  -- TODO verify source game
  local result = {
    id = gift.ID,
    name = gift.ItemName,
    amount = gift.Amount,
    value = gift.ItemValue,
    sender_slot = gift.SenderSlot,
    receiver_slot = gift.ReceiverSlot,
    trait = {},
    quality = {},
    duration = {},
  }

  for _, trait in ipairs(gift.Traits) do
    if SUPPORTED_TRAITS[trait.Trait] then
      result.trait[trait.Trait] = true
      result.quality[trait.Trait] = trait.Quality
      result.duration[trait.Trait] = trait.Duration
    end
  end

  return result
end

-- TODO These will just be callback functions so we don't duplicate the if statements
local function spawn_material(material_name, quantity)
  -- TODO
end

local function spawn_entity(entity_name, quantity)
  -- TODO
end

local function spawn_spell(spell_name, quantity)
  -- TODO
end

function GiftWindow:ProcessGift(gift_raw)
  local gift = preprocess_gift(gift_raw)

  if gift.Wand then
    -- TODO Noita Wand
  elseif gift.Spell then
    -- TODO Noita Spell
  elseif gift.Book then
    -- TODO Noita book
  elseif gift.Flower then
    -- TODO flower material
  elseif gift.Vine then
    -- TODO vine material
  elseif gift.Grass or gift.Fiber then
    -- TODO grass material
  elseif gift.Cooking then
  elseif gift.Vegetable then
  elseif gift.Fruit then
  elseif gift.Egg then
    if gift.Heat then
      -- Toasty Egg
    elseif gift.Cold then
      -- Chilly Egg
    elseif gift.Radioactive then
      -- Slimy Egg
    elseif gift.Zombie then
      -- Egg (Hurtta)
    elseif gift.Fish then
      -- Egg with fish
    elseif gift.Monster then
      -- Egg (Red)
    elseif gift.Animal then
      -- Chicken or duck egg
    else
      -- Hollow Egg
    end
  elseif gift.Fish then
    -- feeeesh
  elseif gift.Zombie then
    -- Hurtta (charmed or no?)
  elseif gift.Monster then
    -- ??? will have to check other traits here
  elseif gift.Animal then
    -- TODO Animals
  elseif gift.Seed or gift.Seeds then
    -- Just use seed material for now until we dive into memeland
  elseif gift.Coal then
    -- Coal material
  elseif gift.Ore then
    if gift.Iron then
      -- Iron Ore
    elseif gift.Copper then
      -- Copper Ore
    elseif gift.Silver then
      -- Silver Ore
    elseif gift.Gold then
      -- Gold Ore
    elseif gift.Radioactive then
      -- Radioactive ore
    elseif gift.Metal then
      -- Other metal ore
    else
      -- Other ore
    end
  elseif gift.Iron then
    -- Iron material
  elseif gift.Copper then
    -- Copper material
  elseif gift.Steel then
    -- Steel material
  elseif gift.Silver then
    -- Silver material
  elseif gift.Gold then
    -- Gold
  elseif gift.Metal then
    -- Other metal
  elseif gift.Gem then
    -- Gems (we don't define any yet)
  elseif gift.Crystal then
    -- Crystals (we don't define any yet)
  elseif gift.Mineral then
    -- Minerals (we don't define any yet)
  elseif gift.Stone then
    -- TODO create stone item or use some stone material?
  elseif gift.Rock then
    -- Rock item
  elseif gift.Boulder then
    -- Just dump a boulder in the room for fun
  elseif gift.Resource then
    -- ??
  elseif gift.Meat then
    -- TODO further split this by Trap and Buff
    -- First check if it matches any one of ours
    if gift.Animal or gift.Fish then
      -- Meat of an innocent creature
    elseif gift.Radioactive then
      -- Toxic Meat
    elseif gift.Buff then
      -- Fully-cooked meat, Stinky Meat, Wobbly Meat, Worm Meat
    elseif gift.Trap then
      -- Cursed Meat, Rotten Meat, Slimy Meat
    elseif gift.Heat then
      -- Cooked Meat?
    else
      -- Regular Meat
    end
  elseif gift.Food then
    -- Other food
  elseif gift.Bomb then
    -- TODO bomb spell or new item with limited stack?
  end
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

function GiftWindow:update()
	if not self:is_open() then return end

	GuiStartFrame(self.gui)
	GuiOptionsClear(self.gui)

	local screen_width, screen_height = GuiGetScreenDimensions(self.gui)

	GuiBeginAutoBox(self.gui)
		GuiLayoutBeginVertical(self.gui, 25, 25)
			GuiOptionsAddForNextWidget(self.gui, GUI_OPTION.DrawSemiTransparent)
			GuiText(self.gui, 0, 0, "Archipelago Gifting Interface")

			GuiLayoutBeginHorizontal(self.gui, 0, 0, false, 8, 8)

				GuiLayoutBeginVertical(self.gui, 0, 0, false, 8)
					GuiText(self.gui, 0, 0, "Basin Inventory")
					GuiBeginScrollContainer(self.gui, ID_SCROLL_GIFTS, 0, 0, screen_width / 4, screen_height / 2)
						self:show_gifts(screen_width / 4)
					GuiEndScrollContainer(self.gui)
				GuiLayoutEnd(self.gui)

			GuiLayoutEnd(self.gui)

			GuiLayoutAddVerticalSpacing(self.gui, 16)

			GuiButton(self.gui, ID_BTN_REFRESH, screen_width / 4 - 20, 0, "Refresh Giftbox")

		GuiLayoutEnd(self.gui)
		GuiZSetForNextWidget(self.gui, 100)
	GuiEndAutoBoxNinePiece(self.gui)
end

return GiftWindow
