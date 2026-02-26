local WangUtil = dofile_once("data/archipelago/lib/wang_util.lua") ---@type WangUtil

-- Biome patches
ModLuaFileAppend("data/scripts/biomes/coalmine.lua", "data/archipelago/scripts/patches/extend_biome_generic.lua")

local Coalmine = WangUtil("data/wang_tiles/coalmine.png") ---@type WangUtil
--Coalmine:InjectOpenPixel(0xff342069)
Coalmine:InjectOpenPixel(0xff692034)
