-- this file shows a list of biomes and what things can spawn in them
-- the purpose is to be able to set options for checks based on pedestals or hidden hp-up hearts/chests

return {
    ["Mines"] = { name = "$biome_coalmine", heart_structures = true, pedestals = true, main_path = true },
    ["Collapsed Mines"] = { name = "$biome_coalmine_alt", heart_structures = true, pedestals = true, side_path = true },
    ["Coal Pits"] = { name = "$biome_excavationsite", heart_structures = true, pedestals = true, main_path = true },
    ["Fungal Caverns"] = { name = "$biome_fungicave", heart_structures = true, pedestals = true, side_path = true },
    ["Snowy Depths"] = { name = "$biome_snowcave", heart_structures = true, pedestals = true, main_path = true },
    ["Hiisi Base"] = { name = "$biome_snowcastle", heart_structures = true, pedestals = true, main_path = true },
    ["Underground Jungle"] = { name = "$biome_rainforest", heart_structures = true, pedestals = true, main_path = true },
    ["Lukki Lair"] = { name = "$biome_rainforest_dark", heart_structures = true, pedestals = true, side_path = true },
    ["Vault"] = { name = "$biome_vault", heart_structures = true, pedestals = true, main_path = true },
    ["Temple of the Art"] = { name = "$biome_crypt", heart_structures = true, pedestals = true, main_path = true },
    ["Overgrown Cavern"] = { name = "$biome_fun", heart_structures = true, pedestals = true, main_world = true },
    ["Wizards' Den"] = { name = "$biome_wizardcave", heart_structures = true, pedestals = true, main_world = true },
    ["Power Plant"] = { name = "$biome_robobase", heart_structures = true, pedestals = true, main_world = true },
    ["Frozen Vault"] = { name = "$biome_vault_frozen", heart_structures = true, pedestals = true, main_world = true },
    ["The Tower"] = { name = "$biome_tower", heart_structures = true, pedestals = true, main_world = true },
}
