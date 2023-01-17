-- Keeping this slim to prevent conflicts when included in patch files

return {
	[110000] = {},	-- Trap

	[110001] = { items = { "data/entities/items/pickup/heart.xml" }, redeliverable = true },
	[110002] = { items = { "data/entities/items/pickup/spell_refresh.xml" }, redeliverable = true },
	[110003] = { items = { "data/entities/items/pickup/potion.xml" } },

	[110004] = { items = { "data/entities/items/pickup/goldnugget_10.xml" }, redeliverable = true },
	[110005] = { items = { "data/entities/items/pickup/goldnugget_50.xml" }, redeliverable = true },
	[110006] = { items = { "data/entities/items/pickup/goldnugget_200.xml" }, redeliverable = true },
	[110007] = { items = { "data/entities/items/pickup/goldnugget_1000.xml" }, redeliverable = true },

	[110008] = { items = { "data/entities/items/wand_level_01.xml", "data/entities/items/wand_unshuffle_01.xml" }, redeliverable = true },
	[110009] = { items = { "data/entities/items/wand_level_02.xml", "data/entities/items/wand_unshuffle_02.xml" }, redeliverable = true },
	[110010] = { items = { "data/entities/items/wand_level_03.xml", "data/entities/items/wand_unshuffle_03.xml" }, redeliverable = true },
	[110011] = { items = { "data/entities/items/wand_level_04.xml", "data/entities/items/wand_unshuffle_04.xml" }, redeliverable = true },
	[110012] = { items = { "data/entities/items/wand_level_05.xml", "data/entities/items/wand_unshuffle_05.xml" }, redeliverable = true },
	[110013] = { items = { "data/entities/items/wand_level_06.xml", "data/entities/items/wand_unshuffle_06.xml" }, redeliverable = true },

	[110014] = { perk = "PROTECTION_FIRE", redeliverable = true },
	[110015] = { perk = "PROTECTION_RADIOACTIVITY", redeliverable = true },
	[110016] = { perk = "PROTECTION_EXPLOSION", redeliverable = true },
	[110017] = { perk = "PROTECTION_MELEE", redeliverable = true },
	[110018] = { perk = "PROTECTION_ELECTRICITY", redeliverable = true },
	[110019] = { perk = "EDIT_WANDS_EVERYWHERE", redeliverable = true },
	[110020] = { perk = "REMOVE_FOG_OF_WAR", redeliverable = true },
	[110021] = { perk = "RESPAWN" }, -- extra life

-- todo: figure out how to make orbs spawn based on their orb file number
	[110022] = { items = { "mods/archipelago/data/archipelago/entities/items/orbs/ap_orb_progression.xml" }, redeliverable = true },

	[110023] = { items = { "data/entities/items/pickup/potion_random_material.xml" } }, -- random potion
	[110024] = { items = { "data/entities/items/pickup/potion_secret.xml" } }, -- secret potion
	[110025] = { items = { "data/entities/items/pickup/physics_die.xml" }, redeliverable = true }, -- chaos die
	[110026] = { items = { "data/entities/items/pickup/physics_greed_die.xml" }, redeliverable = true }, -- greed die
	[110027] = { items = { "data/entities/items/pickup/safe_haven.xml" }, redeliverable = true }, -- kammi
	[110028] = { items = { "data/entities/items/pickup/gourd.xml" }, redeliverable = true }, -- gourd
	[110029] = { items = { "data/entities/items/pickup/beamstone.xml" }, redeliverable = true }, -- sadekivi
	[110030] = { items = { "data/entities/items/pickup/broken_wand.xml" }, redeliverable = true }, -- broken wand
	[110031] = { items = { "data/entities/items/pickup/powder_stash.xml" }, redeliverable = true }, -- powder pouch
	[110032] = { perk = "MAP", redeliverable = true }, -- spatial awareness perk, for runs including toveri boss
}
