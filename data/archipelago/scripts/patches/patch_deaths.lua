local nxml = dofile_once("data/archipelago/lib/nxml.lua") ---@type nxml

local edit_files = {
	"base_humanoid.xml",
	"player_base.xml",
	"base_helpless_animal.xml",

	"animals/fish.xml",
	"animals/fish_large.xml",
	"animals/eel.xml",
	"animals/shooterflower.xml",
	"animals/pebble_physics.xml",
	"animals/lukki/lukki_tiny.xml",
	"animals/lukki/lukki.xml",
	"animals/lukki/lukki_longleg.xml",
	"animals/lukki/lukki_creepy_long.xml",
	"animals/lukki/lukki_dark.xml",
	"animals/worm_tiny.xml",
	"animals/worm.xml",
	"animals/worm_big.xml",
	"animals/worm_skull.xml",
	"animals/worm_end.xml",
	"animals/drone_physics.xml",
	"animals/healerdrone_physics.xml",
	"buildings/snowcrystal.xml",
	"buildings/hpcrystal.xml",
	"animals/ghost.xml",
	"animals/ethereal_being.xml",
	"animals/chest_leggy.xml",
	"animals/parallel/tentacles/parallel_tentacles.xml",
	"animals/special/minipit.xml",
	"animals/meatmaggot.xml",
	"animals/meatmaggot.xml",
}

for _, file in ipairs(edit_files) do
	for xml in nxml.edit_file("data/entities/" .. file) do
		xml:create_child("LuaComponent", { script_death="data/archipelago/entities/animals/entity_died.lua" })
	end
end
