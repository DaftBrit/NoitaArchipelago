local Common = dofile("data/archipelago/ui/gift_translate_common.lua")
dofile_once("gun_actions")

local GiftTranslate = {}


local SUPPORTED_TRAITS = {
  -- Noita specific traits
  ["Wand"] = true,
  ["Spell"] = true,
  ["Book"] = true,

  -- As many other traits as possible which can map to something
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
    name = gift.ItemName:lower(),
    amount = gift.Amount,
    value = gift.ItemValue,
    sender_slot = gift.SenderSlot,
    receiver_slot = gift.ReceiverSlot,
    trait = {},
    quality = {},
    duration = {},

    -- These are to be filled in gift processing to determine what it is
    spawn = {
      spawn_fn = nil,
      spawn_arg1 = nil,
      spawn_arg2 = nil,
      icon = nil,
    }
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
local function spawn_material(material_name, quantity, x, y)
  GameCreateParticle(material_name, x, y, quantity, 0, 0, false)
end

local function spawn_entity(entity_name, quantity, x, y)
  -- TODO
end

local function spawn_spell(spell_name, quantity, x, y)
  for _=1,quantity do
    CreateItemActionEntity(spell_name, x, y)
  end
end

local function apply_status(status_name, duration, x, y)
  -- TODO
end

-- materials is a list of (material, quantity) pairs
local function spawn_container(container_name, materials, x, y)
end

local function process_liquid(name, quantity)
  local internal_name = Common.GetInternalLiquidName(name);
  if internal_name == nil then return nil end
  return {
    fn = spawn_material,
    spawn_arg1 = internal_name,
    spawn_arg2 = (quantity or 1) * 1000,
    icon = Common.GetMaterialIcon(internal_name)
  }
end

local function process_powder(name, quantity)
  local internal_name = Common.GetInternalPowderName(name);
  if internal_name == nil then return nil end
  return {
    fn = spawn_material,
    spawn_arg1 = internal_name,
    spawn_arg2 = (quantity or 1) * 1000,
    icon = Common.GetMaterialIcon(internal_name)
  }
end

local function process_entity(name, quantity)
  -- TODO
end

local function process_spell(name, quantity)
  local internal_name = Common.GetInternalSpellName(name);
  if internal_name == nil then return nil end
  return {
    fn = spawn_spell,
    spawn_arg1 = internal_name,
    spawn_arg2 = quantity,
    icon = Common.GetSpellIcon(internal_name)
  }
end

local function process_status(name, duration)
  -- TODO
end

local function process_container(name)
  -- TODO
end



function GiftTranslate.ProcessGift(gift_raw)
  local gift = preprocess_gift(gift_raw)

  if gift.Wand then
    -- TODO Noita Wand
  elseif gift.Spell then
    gift.spawn = process_spell(gift.name)
  elseif gift.Book then
    -- TODO Noita book
  elseif gift.Flower then
    -- TODO flower material
  elseif gift.Vine then
    -- TODO vine material
  elseif gift.Grass or gift.Fiber then
    gift.spawn = process_powder("grass")
  elseif gift.Cooking then
    if gift.Meat then
      -- Fully-cooked meat
    else
    end
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
    gift.spawn = process_powder("seed")
  elseif gift.Coal then
    gift.spawn = process_powder("coal")
  elseif gift.Ore then
    if gift.Iron then
      -- Iron Ore
    elseif gift.Copper then
      gift.spawn = process_powder("copper")
    elseif gift.Silver then
      gift.spawn = process_powder("silver")
    elseif gift.Gold then
      gift.spawn = process_powder("gold")
    elseif gift.Radioactive then
      -- Radioactive ore
    elseif gift.Metal then
      gift.spawn = process_powder("metal dust")
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
    if gift.Radioactive then
    else
    end
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
      gift.spawn = process_powder("toxic meat")
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


return GiftTranslate
