-- this file shows a list of biomes and what things can spawn in them
-- the purpose is to be able to set options for checks based on pedestals or hidden hp-up hearts/chests
-- first_hc is the first location ID for the hidden chests in the walls

return {
    ["$biome_coalmine"] = { main_path = true, first_hc = 112000, first_ped = 112500,},
    ["$biome_coalmine_alt"] = { side_path = true, first_hc = 112020, first_ped = 112520,},
    ["$biome_excavationsite"] = { main_path = true, first_hc = 112040, first_ped = 112540,},
    ["$biome_fungicave"] = { side_path = true, first_hc = 112060, first_ped = 112560,},
    ["$biome_snowcave"] = { main_path = true, first_hc = 112080, first_ped = 112580,},
    ["$biome_snowcastle"] = { main_path = true, first_hc = 112100, first_ped = 112600,},
    ["$biome_rainforest"] = { main_path = true, first_hc = 112120, first_ped = 112620,},
    ["$biome_rainforest_dark"] = { side_path = true, first_hc = 112140, first_ped = 112640,},
    ["$biome_vault"] = { main_path = true, first_hc = 112160, first_ped = 112660,},
    ["$biome_crypt"] = { main_path = true, first_hc = 112180, first_ped = 112680,},
    ["$biome_fun"] = { main_world = true, first_hc = 112200, first_ped = 112700,},
    ["$biome_wizardcave"] = { main_world = true, first_hc = 112220, first_ped = 112720,},
    ["$biome_robobase"] = { main_world = true, first_hc = 112240, first_ped = 112740,},
    ["$biome_vault_frozen"] = { main_world = true, first_hc = 112260, first_ped = 112760,},
    ["$biome_tower"] = { main_world = true, first_hc = 112280, first_ped = 112780,},
}