-- Keeping this slim to prevent conflicts when included in patch files

local function init_item(shopitems)
  return {
    shop = shopitems
  }
end

return {
	[110000] = init_item({}),

	[110001] = init_item({ "data/entities/items/pickup/heart.xml" }),
	[110002] = init_item({ "data/entities/items/pickup/spell_refresh.xml" }),
	[110003] = init_item({ "data/entities/items/pickup/potion.xml" }) ,

	[110004] = init_item({ "data/entities/items/pickup/goldnugget_10.xml" }),
	[110005] = init_item({ "data/entities/items/pickup/goldnugget_50.xml" }),
	[110006] = init_item({ "data/entities/items/pickup/goldnugget_200.xml" }),
	[110007] = init_item({ "data/entities/items/pickup/goldnugget_1000.xml" }),

	[110008] = init_item({ "data/entities/items/wand_level_01.xml", "data/entities/items/wand_unshuffle_01.xml" }),
	[110009] = init_item({ "data/entities/items/wand_level_02.xml", "data/entities/items/wand_unshuffle_02.xml" }),
	[110010] = init_item({ "data/entities/items/wand_level_03.xml", "data/entities/items/wand_unshuffle_03.xml" }),
	[110011] = init_item({ "data/entities/items/wand_level_04.xml", "data/entities/items/wand_unshuffle_04.xml" }),
	[110012] = init_item({ "data/entities/items/wand_level_05.xml", "data/entities/items/wand_unshuffle_05.xml" }),
	[110013] = init_item({ "data/entities/items/wand_level_06.xml", "data/entities/items/wand_unshuffle_06.xml" }),

	[110014] = init_item({ perk = "PROTECTION_FIRE" }),
	[110015] = init_item({ perk = "PROTECTION_RADIOACTIVITY" }),
	[110016] = init_item({ perk = "PROTECTION_EXPLOSION" }),
	[110017] = init_item({ perk = "PROTECTION_MELEE" }),
	[110018] = init_item({ perk = "PROTECTION_ELECTRICITY" }),
	[110019] = init_item({ perk = "EDIT_WANDS_EVERYWHERE" }),
	[110020] = init_item({ perk = "REMOVE_FOG_OF_WAR" }),
	[110021] = init_item({ perk = "RESPAWN" }), -- extra life
-- todo: figure out how to make orbs spawn based on their orb file number
	[110022] = init_item({ "mods/archipelago/data/archipelago/entities/items/orbs/ap_orb_progression.xml" }),

	[110023] = init_item({ "data/entities/items/pickup/potion_random_material.xml" }), -- random potion
	[110024] = init_item({ "data/entities/items/pickup/potion_secret.xml" }), -- secret potion
	[110025] = init_item({ "data/entities/items/pickup/physics_die.xml" }), -- chaos die
	[110026] = init_item({ "data/entities/items/pickup/physics_greed_die.xml" }), -- greed die
	[110027] = init_item({ "data/entities/items/pickup/safe_haven.xml" }), -- kammi
	[110028] = init_item({ "data/entities/items/pickup/gourd.xml" }), -- gourd
	[110029] = init_item({ "data/entities/items/pickup/beamstone.xml" }), -- sadekivi
	[110030] = init_item({ "data/entities/items/pickup/broken_wand.xml" }), -- broken wand
	[110031] = init_item({ "data/entities/items/pickup/powder_stash.xml" }), -- powder pouch
	[110032] = init_item({ perk = "MAP" }) -- spatial awareness perk, for runs including toveri boss
}
