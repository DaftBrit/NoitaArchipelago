
-- TRANSLATIONS
local TRANSLATIONS_FILE = "data/translations/common.csv"
local translations = ModTextFileGetContent(TRANSLATIONS_FILE) .. ModTextFileGetContent("data/archipelago/translations.csv")
ModTextFileSetContent(TRANSLATIONS_FILE, translations)

-- SCRIPT EXTENSIONS
ModLuaFileAppend("data/scripts/biomes/temple_altar.lua", "data/archipelago/scripts/extend_temple_altar.lua")
ModLuaFileAppend("data/scripts/biomes/boss_arena.lua", "data/archipelago/scripts/extend_temple_altar.lua")
ModLuaFileAppend("data/scripts/perks/perk_list.lua", "data/archipelago/scripts/ap_extend_perk_list.lua")
ModLuaFileAppend("data/entities/animals/boss_centipede/ending/sampo_start_ending_sequence.lua", "data/archipelago/scripts/ap_extend_ending.lua")
