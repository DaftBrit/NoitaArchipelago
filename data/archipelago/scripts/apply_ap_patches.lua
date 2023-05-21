
-- TRANSLATIONS
local TRANSLATIONS_FILE = "data/translations/common.csv"
local translations = ModTextFileGetContent(TRANSLATIONS_FILE) .. ModTextFileGetContent("data/archipelago/translations.csv")
ModTextFileSetContent(TRANSLATIONS_FILE, translations)

-- SCRIPT EXTENSIONS
ModLuaFileAppend("data/scripts/biomes/temple_altar.lua", "data/archipelago/scripts/patches/extend_temple_altar.lua")
ModLuaFileAppend("data/scripts/biomes/boss_arena.lua", "data/archipelago/scripts/patches/extend_temple_altar.lua")
ModLuaFileAppend("data/scripts/biomes/snowcastle_cavern.lua", "data/archipelago/scripts/patches/extend_snowcastle_cavern.lua")
ModLuaFileAppend("data/scripts/perks/perk_list.lua", "data/archipelago/scripts/patches/ap_extend_perk_list.lua")
ModLuaFileAppend("data/entities/animals/boss_centipede/ending/sampo_start_ending_sequence.lua", "data/archipelago/scripts/patches/ap_extend_ending.lua")
ModLuaFileAppend("data/entities/animals/boss_centipede/sampo_pickup.lua", "data/archipelago/scripts/patches/ap_extend_sampo_pickup.lua")

ModLuaFileAppend("data/entities/animals/boss_alchemist/death.lua", "data/archipelago/scripts/bosses/ap_alchemist_death.lua")
ModLuaFileAppend("data/scripts/animals/boss_dragon_death.lua", "data/archipelago/scripts/bosses/ap_dragon_death.lua")
ModLuaFileAppend("data/scripts/animals/friend_death.lua", "data/archipelago/scripts/bosses/ap_friend_death.lua")
ModLuaFileAppend("data/entities/animals/boss_limbs/boss_limbs_death.lua", "data/archipelago/scripts/bosses/ap_koipi_death.lua")
ModLuaFileAppend("data/entities/animals/boss_centipede/death_check.lua", "data/archipelago/scripts/bosses/ap_kolmi_death.lua")
ModLuaFileAppend("data/entities/animals/boss_fish/death.lua", "data/archipelago/scripts/bosses/ap_leviathan_death.lua")
ModLuaFileAppend("data/entities/animals/maggot_tiny/death.lua", "data/archipelago/scripts/bosses/ap_maggot_death.lua")
ModLuaFileAppend("data/entities/animals/boss_robot/death.lua", "data/archipelago/scripts/bosses/ap_mecha_death.lua")
ModLuaFileAppend("data/entities/animals/boss_wizard/death.lua", "data/archipelago/scripts/bosses/ap_mestari_death.lua")
ModLuaFileAppend("data/entities/animals/boss_ghost/death.lua", "data/archipelago/scripts/bosses/ap_skull_death.lua")
ModLuaFileAppend("data/entities/animals/boss_pit/boss_pit_death.lua", "data/archipelago/scripts/bosses/ap_squidward_death.lua")
ModLuaFileAppend("data/entities/animals/boss_gate/gate_monster_death.lua", "data/archipelago/scripts/bosses/ap_triangle_death.lua")

ModLuaFileAppend("data/scripts/items/orb_init.lua", "data/archipelago/scripts/patches/ap_orb_init_random.lua")
ModLuaFileAppend("data/scripts/items/orb_pickup.lua", "data/archipelago/scripts/patches/ap_orb_pickup_random.lua")

ModLuaFileAppend("data/scripts/biome_scripts.lua", "data/archipelago/scripts/patches/ap_heart_replacer.lua")
ModLuaFileAppend("data/scripts/biome_scripts.lua", "data/archipelago/scripts/patches/ap_pedestal_replacer.lua")
ModLuaFileAppend("data/scripts/biomes/coalmine.lua", "data/archipelago/scripts/patches/ap_pedestal_replacer.lua")

ModLuaFileAppend("data/scripts/buildings/forge_item_convert.lua", "data/archipelago/scripts/patches/extend_forge_item_convert.lua")