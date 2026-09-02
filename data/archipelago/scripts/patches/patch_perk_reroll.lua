local nxml = dofile_once("data/archipelago/lib/nxml.lua") ---@type nxml

local locked_reroll_xml = nxml.parse_file("data/archipelago/entities/buildings/ap_locked_perk_reroll.xml")

for xml in nxml.edit_file("data/entities/items/pickup/perk_reroll.xml") do
	xml:add_children(locked_reroll_xml.children)
end
