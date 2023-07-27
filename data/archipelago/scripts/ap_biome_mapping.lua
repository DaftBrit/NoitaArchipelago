-- this file shows a list of biomes and what things can spawn in them
-- the purpose is to be able to set options for checks based on pedestals or hidden hp-up hearts/chests
-- first_hc is the first location ID for the hidden chests in the walls

return {
	["$biome_coalmine"] = { main_path = true, first_hc = 110046, first_ped = 110066,},
	["$biome_coalmine_alt"] = { main_path = true, first_hc = 110046, first_ped = 110066,},
	["$biome_excavationsite"] = { main_path = true, first_hc = 110126, first_ped = 110146,},
	["$biome_fungicave"] = { side_path = true, first_hc = 110166, first_ped = 110186,},
	["$biome_snowcave"] = { main_path = true, first_hc = 110206, first_ped = 110226,},
	["$biome_snowcastle"] = { main_path = true, first_hc = 110246, first_ped = 110266,},
	["$biome_rainforest"] = { main_path = true, first_hc = 110286, first_ped = 110306,}, -- Underground Jungle
	["$biome_rainforest_dark"] = { side_path = true, first_hc = 110326, first_ped = 110346,}, -- Lukki Lair
	["$biome_vault"] = { main_path = true, first_hc = 110366, first_ped = 110386,},
	["$biome_crypt"] = { main_path = true, first_hc = 110406, first_ped = 110426,}, -- Temple of the Art
	["$biome_fun"] = { main_world = true, first_hc = 110526, first_ped = 110546,}, -- Overgrown Cavern
	["$biome_wizardcave"] = { main_world = true, first_hc = 110446, first_ped = 110466,},
	["$biome_robobase"] = { main_world = true, first_hc = 110486, first_ped = 110506,},
	["$biome_vault_frozen"] = { main_world = true, first_hc = 110566, first_ped = 110586,},
	["$biome_tower"] = { main_world = true, first_hc = 110606, first_ped = 110626,},
	["$biome_meat"] = { main_world = true, first_hc = 110086, first_ped = 110106,},
}
