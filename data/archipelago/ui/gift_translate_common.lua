dofile_once("gun_actions")

local Common = {}


local function create_relation_table(name, materials_list)
  Common[name] = {
    FromInternal = {},
    ToInternal = {},
  }

  for _, material_name in ipairs(materials_list) do
    local id = CellFactory_GetType(material_name)
    local ui_name = CellFactory_GetUIName(id)

    Common[name].FromInternal[material_name] = ui_name
    Common[name].ToInternal[ui_name:lower()] = material_name
  end
end

-- Define material maps including material aliases
-- See https://noita.wiki.gg/wiki/Modding:Material_IDs and sort by name to find dupe names
local function init_materials()
  create_relation_table("Liquids", CellFactory_GetAllLiquids(false))
  create_relation_table("Powders", CellFactory_GetAllSands(false))
  create_relation_table("Gasses", CellFactory_GetAllGases(false))

  -- Overrides
  Common.Liquids.ToInternal["blood"] = "blood"
  Common.Liquids.ToInternal["magical liquid"] = nil
  Common.Liquids.FromInternal["plasma_fading"] = nil
  Common.Liquids.FromInternal["plasma_fading_bright"] = nil
  Common.Liquids.FromInternal["plasma_fading_green"] = nil
  Common.Liquids.FromInternal["plasma_fading_pink"] = nil
  Common.Liquids.ToInternal["molten aluminium"] = "aluminium_molten"
  Common.Liquids.ToInternal["molten aluminum"] = "aluminium_molten" -- Alt spelling
  Common.Liquids.ToInternal["molten glass"] = "glass_molten"
  Common.Liquids.ToInternal["molten metal"] = "metal_sand_molten"
  Common.Liquids.ToInternal["molten plastic"] = "plastic_molten"
  Common.Liquids.ToInternal["molten steel"] = "steel_static_molten" -- It's this or defining stuff for every Steel variant

  -- All of these are just called "Slime" in-game
  Common.Liquids.ToInternal["slime"] = "slime"
  Common.Liquids.FromInternal["slime"] = "Slime"
  Common.Liquids.ToInternal["green slime"] = "slime_green"
  Common.Liquids.FromInternal["slime_green"] = "Green Slime"
  Common.Liquids.ToInternal["yellow slime"] = "slime_yellow"
  Common.Liquids.FromInternal["slime_yellow"] = "Yellow Slime"

  Common.Liquids.ToInternal["swamp"] = "swamp"
  Common.Liquids.ToInternal["swamp water"] = "water_swamp"
  Common.Liquids.FromInternal["water_swamp"] = "Swamp Water"
  Common.Liquids.ToInternal["toxic sludge"] = "radioactive_liquid"
  Common.Liquids.ToInternal["water"] = "water"

  -- Gasses
  Common.Gasses.ToInternal["flammable gas"] = "acid_gas"
  Common.Gasses.ToInternal["smoke"] = "smoke"
  Common.Gasses.ToInternal["steam"] = "steam"
  Common.Gasses.ToInternal["toxic gas"] = "radioactive_gas"

  -- Powders
  -- Soil (TODO use tags instead)
  Common.Powders.ToInternal["soil"] = "soil"
  Common.Powders.ToInternal["barren soil"] = "soil_dead"
  Common.Powders.ToInternal["dead soil"] = "soil_dead"
  Common.Powders.FromInternal["soil_dead"] = "Barren Soil"
  Common.Powders.ToInternal["dark soil"] = "soil_dark"
  Common.Powders.FromInternal["soil_dark"] = "Dark Soil"
  Common.Powders.ToInternal["fungal soil"] = "fungisoil"
  Common.Powders.FromInternal["soil_lush"] = "Lush Soil"
  Common.Powders.ToInternal["lush soil"] = "soil_lush"
  Common.Powders.FromInternal["soil_lush_dark"] = "Lush Dark Soil"
  Common.Powders.ToInternal["lush dark soil"] = "soil_lush_dark"

  -- TODO fungal spore variants

  Common.Powders.FromInternal["fungi_creeping_secret"] = "Mystery Fungus"
  Common.Powders.ToInternal["fungus"] = "fungi_green"

  -- Grass (TODO use tags instead)
  Common.Powders.ToInternal["grass"] = "grass"
  Common.Powders.ToInternal["dark grass"] = "grass_dark"
  Common.Powders.FromInternal["grass_dark"] = "Dark Grass"
  Common.Powders.ToInternal["dry grass"] = "grass_dry"
  Common.Powders.FromInternal["grass_dry"] = "Dry Grass"
  Common.Powders.ToInternal["frozen grass"] = "grass_ice"
  Common.Powders.FromInternal["grass_ice"] = "Frozen Grass"

  -- Gunpowder (TODO use tags instead)
  Common.Powders.ToInternal["gunpowder"] = "gunpowder_tnt"
  Common.Powders.ToInternal["inert gunpowder"] = "gunpowder"
  Common.Powders.FromInternal["gunpowder"] = "Inert Gunpowder"
  Common.Powders.ToInternal["explosive gunpowder"] = "gunpowder_explosive"
  Common.Powders.FromInternal["gunpowder_explosive"] = "Explosive Gunpowder"

  Common.Powders.ToInternal["ice"] = "ice"
  Common.Powders.ToInternal["sand"] = "sand"
  Common.Powders.ToInternal["sandstone"] = "sandstone"

  -- Seeds (TODO use tags instead)
  Common.Powders.ToInternal["spore"] = "spore"
  Common.Powders.ToInternal["seed"] = "ceiling_plant_material"
  Common.Powders.ToInternal["red seed"] = "plant_material_red"
  Common.Powders.FromInternal["plant_material_red"] = "Red Seed"

  Common.Powders.ToInternal["slimy meat"] = "meat_slime_sand"
  Common.Powders.FromInternal["gunpowder_unstable_boss_limbs"] = nil

  Common.Powders.ToInternal["snow"] = "snow"
end

local function init_spells()
  Common["Spells"] = {
    FromInternal = {},
    ToInternal = {},
  }

  for _, spell in actions do
    local name = GameTextGetTranslatedOrNot(spell.name)
    Common.Spells.ToInternal[name:lower()] = spell.id
    Common.Spells.FromInternal[spell.id] = name
  end
end

-- TODO wands (pain)







return Common
