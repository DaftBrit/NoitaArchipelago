dofile_once("gun_actions")

local translations_csv = ModTextFileGetContent("data/archipelago/translations.csv")

local Common = {}

local function translate_english_name(key)
  return _G.APGifting.Translate[key] or key
end

local function create_relation_table(name, materials_list)
  _G.APGifting[name] = {
    FromInternal = {},
    ToInternal = {},
  }

  for _, material_name in ipairs(materials_list) do
    local id = CellFactory_GetType(material_name)
    local ui_name = translate_english_name(CellFactory_GetUIName(id))

    _G.APGifting[name].FromInternal[material_name] = ui_name
    _G.APGifting[name].ToInternal[ui_name:lower()] = material_name
  end
end

local function init_english_translations()
  _G.APGifting.Translate = {}
  for line in translations_csv:gmatch("([^\n]+)\n?") do
    local key, text = line:match("([^,]*),([^,]*),.*")

    _G.APGifting.Translate["$" .. key] = text
  end
end

-- Define material maps including material aliases
-- See https://noita.wiki.gg/wiki/Modding:Material_IDs and sort by name to find dupe names
local function init_materials()
  create_relation_table("Liquids", CellFactory_GetAllLiquids(false))
  create_relation_table("Powders", CellFactory_GetAllSands(false))
  create_relation_table("Gasses", CellFactory_GetAllGases(false))

  -- Overrides
  _G.APGifting.Liquids.ToInternal["blood"] = "blood"
  _G.APGifting.Liquids.ToInternal["magical liquid"] = nil
  _G.APGifting.Liquids.FromInternal["plasma_fading"] = nil
  _G.APGifting.Liquids.FromInternal["plasma_fading_bright"] = nil
  _G.APGifting.Liquids.FromInternal["plasma_fading_green"] = nil
  _G.APGifting.Liquids.FromInternal["plasma_fading_pink"] = nil
  _G.APGifting.Liquids.ToInternal["molten aluminium"] = "aluminium_molten"
  _G.APGifting.Liquids.ToInternal["molten aluminum"] = "aluminium_molten" -- Alt spelling
  _G.APGifting.Liquids.ToInternal["molten glass"] = "glass_molten"
  _G.APGifting.Liquids.ToInternal["molten metal"] = "metal_sand_molten"
  _G.APGifting.Liquids.ToInternal["molten plastic"] = "plastic_molten"
  _G.APGifting.Liquids.ToInternal["molten steel"] = "steel_static_molten" -- It's this or defining stuff for every Steel variant

  -- All of these are just called "Slime" in-game
  _G.APGifting.Liquids.ToInternal["slime"] = "slime"
  _G.APGifting.Liquids.FromInternal["slime"] = "slime"
  _G.APGifting.Liquids.ToInternal["green slime"] = "slime_green"
  _G.APGifting.Liquids.FromInternal["slime_green"] = "green slime"
  _G.APGifting.Liquids.ToInternal["yellow slime"] = "slime_yellow"
  _G.APGifting.Liquids.FromInternal["slime_yellow"] = "yellow slime"

  _G.APGifting.Liquids.ToInternal["swamp"] = "swamp"
  _G.APGifting.Liquids.ToInternal["swamp water"] = "water_swamp"
  _G.APGifting.Liquids.FromInternal["water_swamp"] = "swamp water"
  _G.APGifting.Liquids.ToInternal["toxic sludge"] = "radioactive_liquid"
  _G.APGifting.Liquids.ToInternal["water"] = "water"

  -- Gasses
  _G.APGifting.Gasses.ToInternal["flammable gas"] = "acid_gas"
  _G.APGifting.Gasses.ToInternal["smoke"] = "smoke"
  _G.APGifting.Gasses.ToInternal["steam"] = "steam"
  _G.APGifting.Gasses.ToInternal["toxic gas"] = "radioactive_gas"

  -- Powders
  -- Soil (TODO use tags instead)
  _G.APGifting.Powders.ToInternal["soil"] = "soil"
  _G.APGifting.Powders.ToInternal["barren soil"] = "soil_dead"
  _G.APGifting.Powders.ToInternal["dead soil"] = "soil_dead"
  _G.APGifting.Powders.FromInternal["soil_dead"] = "barren soil"
  _G.APGifting.Powders.ToInternal["dark soil"] = "soil_dark"
  _G.APGifting.Powders.FromInternal["soil_dark"] = "Dark Soil"
  _G.APGifting.Powders.ToInternal["fungal soil"] = "fungisoil"
  _G.APGifting.Powders.FromInternal["soil_lush"] = "lush soil"
  _G.APGifting.Powders.ToInternal["lush soil"] = "soil_lush"
  _G.APGifting.Powders.FromInternal["soil_lush_dark"] = "lush dark soil"
  _G.APGifting.Powders.ToInternal["lush dark soil"] = "soil_lush_dark"

  -- TODO fungal spore variants

  _G.APGifting.Powders.FromInternal["fungi_creeping_secret"] = "mystery fungus"
  _G.APGifting.Powders.ToInternal["fungus"] = "fungi_green"

  -- Grass (TODO use tags instead)
  _G.APGifting.Powders.ToInternal["grass"] = "grass"
  _G.APGifting.Powders.ToInternal["dark grass"] = "grass_dark"
  _G.APGifting.Powders.FromInternal["grass_dark"] = "dark grass"
  _G.APGifting.Powders.ToInternal["dry grass"] = "grass_dry"
  _G.APGifting.Powders.FromInternal["grass_dry"] = "dry grass"

  -- Gunpowder (TODO use tags instead)
  _G.APGifting.Powders.ToInternal["gunpowder"] = "gunpowder_tnt"
  _G.APGifting.Powders.ToInternal["inert gunpowder"] = "gunpowder"
  _G.APGifting.Powders.FromInternal["gunpowder"] = "inert gunpowder"
  _G.APGifting.Powders.ToInternal["explosive gunpowder"] = "gunpowder_explosive"
  _G.APGifting.Powders.FromInternal["gunpowder_explosive"] = "explosive gunpowder"

  _G.APGifting.Powders.ToInternal["ice"] = "ice"
  _G.APGifting.Powders.FromInternal["metal"] = "metal_sand"
  _G.APGifting.Powders.ToInternal["sand"] = "sand"
  _G.APGifting.Powders.ToInternal["sandstone"] = "sandstone"

  -- Seeds (TODO use tags instead)
  _G.APGifting.Powders.ToInternal["spore"] = "spore"
  _G.APGifting.Powders.ToInternal["seed"] = "ceiling_plant_material"
  _G.APGifting.Powders.ToInternal["red seed"] = "plant_material_red"
  _G.APGifting.Powders.FromInternal["plant_material_red"] = "red seed"

  _G.APGifting.Powders.ToInternal["slimy meat"] = "meat_slime_sand"
  _G.APGifting.Powders.FromInternal["gunpowder_unstable_boss_limbs"] = nil

  _G.APGifting.Powders.ToInternal["snow"] = "snow"
end

local function init_spells()
  _G.APGifting.Spells = {
    FromInternal = {},
    ToInternal = {},
  }

  for _, spell in actions do
    local name = translate_english_name(spell.name)
    _G.APGifting.Spells.ToInternal[name:lower()] = spell.id
    _G.APGifting.Spells.FromInternal[spell.id] = name
    _G.APGifting.SpellIcons[spell.id] = spell.sprite
    _G.APGifting.SpellType[spell.id] = spell.type
  end
end

-- TODO wands (pain)

function Common.Initialize()
  if _G.APGifting ~= nil then return end
  _G.APGifting = {}

  init_english_translations()
  init_materials()
  init_spells()
end

function Common.GetInternalLiquidName(name)
  return _G.APGifting.Liquids.ToInternal[name]
end

function Common.GetInternalGasName(name)
  return _G.APGifting.Gasses.ToInternal[name]
end

function Common.GetInternalPowderName(name)
  return _G.APGifting.Powders.ToInternal[name]
end

function Common.GetInternalSpellName(name)
  return _G.APGifting.Spells.ToInternal[name]
end

function Common.GetInternalItemName(name)
  -- TODO
end

function Common.GetInternalCreatureName(name)
  -- TODO
end

function Common.GetInternalStatusName(name)
  -- TODO
end

-- Internal material name
function Common.GetMaterialIcon(material_name)
  return "generated/material_icons/" .. material_name .. ".png"
end

function Common.GetSpellIcon(spell_name)
  return _G.APGifting.SpellIcons[spell_name]
end

return Common
