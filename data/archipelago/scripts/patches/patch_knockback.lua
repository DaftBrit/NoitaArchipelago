local nxml = dofile_once("data/archipelago/lib/nxml.lua") ---@type nxml

for xml in nxml.edit_file("data/entities/misc/effect_knockback.xml") do
	xml:create_child("LuaComponent", {
		_tags = "ap_knockback",
		script_source_file = "data/archipelago/scripts/knocked.lua",
		remove_after_executed = 1,
	})
end
