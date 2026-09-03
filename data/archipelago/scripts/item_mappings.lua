-- Keeping this slim to prevent conflicts when included in patch files
-- redeliverable means it will be delivered in async
-- newgame means it will be delivered on new game
return {
	[20000] = { redeliverable = true, newgame = true }, -- progressive portal
	[20003] = { perk = "EXTRA_PERK", redeliverable = true, newgame = true },
	[20004] = { perk = "SAVING_GRACE", redeliverable = true, newgame = true },
	[20005] = { perk = "TRICK_BLOOD_MONEY", redeliverable = true, newgame = true },
	[20006] = { perk = "AP_PERK_REROLL", redeliverable = true, newgame = true }, -- perk that enables perk rerolling
	[20007] = { perk = "NO_MORE_KNOCKBACK", redeliverable = true, newgame = true },
	[20008] = { perk = "MANA_FROM_KILLS", redeliverable = true, newgame = true },
	[20009] = { perk = "RADAR_ENEMY", redeliverable = true, newgame = true },
	[20010] = { perk = "IRON_STOMACH", redeliverable = true, newgame = true },
	[20011] = { perk = "WAND_RADAR", redeliverable = true, newgame = true },
	[20012] = { perk = "ITEM_RADAR", redeliverable = true, newgame = true },
	[20013] = { perk = "ADVENTURER", redeliverable = true, newgame = true },
	[20014] = { perk = "ABILITY_ACTIONS_MATERIALIZED", redeliverable = true, newgame = true },
	[20015] = { perk = "UNLIMITED_SPELLS", redeliverable = true, newgame = true },
	[20016] = { perk = "AP_PERK_REROLL_DISCOUNT", redeliverable = true, newgame = true },
	[20020] = { perk = "AP_CHEST_RADAR", redeliverable = true, newgame = true },

	[110000] = {},	-- Trap

	[110001] = { items = { "data/entities/items/pickup/heart.xml" }, redeliverable = true, newgame = true },
	[110002] = { items = { "data/entities/items/pickup/spell_refresh.xml" }, redeliverable = true },
	[110003] = { items = { "data/entities/items/pickup/potion.xml" }, potion = true },

	[110004] = { items = { "data/entities/items/pickup/goldnugget_200.xml" }, gold_amount = 200, redeliverable = true },
	[110005] = { items = { "data/entities/items/pickup/goldnugget_1000.xml" }, gold_amount = 1000, redeliverable = true },

	[110006] = { items = { "data/entities/items/wand_level_01.xml", "data/entities/items/wand_unshuffle_01.xml" }, redeliverable = true, newgame = true, wand = true },
	[110007] = { items = { "data/entities/items/wand_level_02.xml", "data/entities/items/wand_unshuffle_02.xml" }, redeliverable = true, newgame = true, wand = true },
	[110008] = { items = { "data/entities/items/wand_level_03.xml", "data/entities/items/wand_unshuffle_03.xml" }, redeliverable = true, newgame = true, wand = true },
	[110009] = { items = { "data/entities/items/wand_level_04.xml", "data/entities/items/wand_unshuffle_04.xml" }, redeliverable = true, newgame = true, wand = true },
	[110010] = { items = { "data/entities/items/wand_level_05.xml", "data/entities/items/wand_unshuffle_05.xml" }, redeliverable = true, newgame = true, wand = true },
	[110011] = { items = { "data/entities/items/wand_level_06.xml", "data/entities/items/wand_unshuffle_06.xml" }, redeliverable = true, newgame = true, wand = true },
	[110012] = { items = { "data/archipelago/entities/items/ap_kantele.xml" }, redeliverable = true, newgame = true, wand = true },

	[110013] = { perk = "PROTECTION_FIRE", redeliverable = true, newgame = true },
	[110014] = { perk = "PROTECTION_RADIOACTIVITY", redeliverable = true, newgame = true },
	[110015] = { perk = "PROTECTION_EXPLOSION", redeliverable = true, newgame = true },
	[110016] = { perk = "PROTECTION_MELEE", redeliverable = true, newgame = true },
	[110017] = { perk = "PROTECTION_ELECTRICITY", redeliverable = true, newgame = true },
	[110018] = { perk = "EDIT_WANDS_EVERYWHERE", redeliverable = true, newgame = true },
	[110019] = { perk = "REMOVE_FOG_OF_WAR", redeliverable = true, newgame = true },
	[110020] = { perk = "MAP", redeliverable = true, newgame = true }, -- spatial awareness perk, for runs including toveri boss
	[110021] = { perk = "RESPAWN", redeliverable = true, newgame = true }, -- extra life

	[110022] = { items = { "data/archipelago/entities/items/orbs/ap_orb_randomizer_spawned.xml" }, orb = true, redeliverable = true, newgame = true },

	[110023] = { items = { "data/entities/items/pickup/potion_random_material.xml" }, potion = true }, -- random potion
	[110024] = { items = { "data/entities/items/pickup/potion_secret.xml" }, potion = true }, -- secret potion
	[110025] = { items = { "data/entities/items/pickup/powder_stash.xml" }, redeliverable = true, newgame = true }, -- powder pouch
	[110026] = { items = { "data/entities/items/pickup/physics_die.xml" } }, -- chaos die
	[110027] = { items = { "data/entities/items/pickup/physics_greed_die.xml" } }, -- greed die
	[110028] = { items = { "data/entities/items/pickup/safe_haven.xml" }, redeliverable = true, newgame = true }, -- kammi
	[110029] = { items = { "data/entities/items/pickup/gourd.xml" }, redeliverable = true, newgame = true }, -- gourd
	[110030] = { items = { "data/entities/items/pickup/beamstone.xml" }, redeliverable = true, newgame = true }, -- sadekivi
	[110031] = { items = { "data/entities/items/pickup/broken_wand.xml" }, redeliverable = true, newgame = true }, -- broken wand

	[110032] = { items = { "data/archipelago/entities/items/pw_teleporter.xml" }, redeliverable = true, newgame = true, wand = true }, -- pw teleporter for pw options
}
