-- this file shows a list of biomes and what things can spawn in them
-- the purpose is to be able to set options for checks based on pedestals or hidden hp-up hearts/chests
-- first_hc is the first location ID for the hidden chests in the walls

return {
    ["Mines"] = { name = "$biome_coalmine", main_path = true, first_hc = 112000, first_ped = 112500,},
    ["Collapsed Mines"] = { name = "$biome_coalmine_alt", side_path = true, first_hc = 112020, first_ped = 112520,},
    ["Coal Pits"] = { name = "$biome_excavationsite", main_path = true, first_hc = 112040, first_ped = 112540,},
    ["Fungal Caverns"] = { name = "$biome_fungicave", side_path = true, first_hc = 112060, first_ped = 112560,},
    ["Snowy Depths"] = { name = "$biome_snowcave", main_path = true, first_hc = 112080, first_ped = 112580,},
    ["Hiisi Base"] = { name = "$biome_snowcastle", main_path = true, first_hc = 112100, first_ped = 112600,},
    ["Underground Jungle"] = { name = "$biome_rainforest", main_path = true, first_hc = 112120, first_ped = 112620,},
    ["Lukki Lair"] = { name = "$biome_rainforest_dark", side_path = true, first_hc = 112140, first_ped = 112640,},
    ["Vault"] = { name = "$biome_vault", main_path = true, first_hc = 112160, first_ped = 112660,},
    ["Temple of the Art"] = { name = "$biome_crypt", main_path = true, first_hc = 112180, first_ped = 112680,},
    ["Overgrown Cavern"] = { name = "$biome_fun", main_world = true, first_hc = 112200, first_ped = 112700,},
    ["Wizards' Den"] = { name = "$biome_wizardcave", main_world = true, first_hc = 112220, first_ped = 112720,},
    ["Power Plant"] = { name = "$biome_robobase", main_world = true, first_hc = 112240, first_ped = 112740,},
    ["Frozen Vault"] = { name = "$biome_vault_frozen", main_world = true, first_hc = 112260, first_ped = 112760,},
    ["The Tower"] = { name = "$biome_tower", main_world = true, first_hc = 112280, first_ped = 112780,},
}