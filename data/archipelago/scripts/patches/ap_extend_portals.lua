
---@type nxml
local nxml = dofile_once("data/archipelago/lib/nxml.lua")

local closed_portal_xml = nxml.parse_file("data/archipelago/entities/buildings/ap_closed_portal.xml")

local function update_portal_xml(xml)
	-- Disable portals by default and have them enabled through code
	for comp in xml:each_child() do
		local tag = comp:get("_tags") or ""
		if tag:find("enabled_by_liquid", 1, true) then
			comp:set("_enabled", 0)
		end
	end

	xml:add_children(closed_portal_xml.children)
end

for xml in nxml.edit_file("data/entities/buildings/teleport_liquid_powered.xml") do
	update_portal_xml(xml)
end

for xml in nxml.edit_file("data/entities/buildings/teleport_ending.xml") do
	update_portal_xml(xml)

	for comp in xml:each_of("ParticleEmitterComponent") do
		comp:set("emitted_material_name", "spark_red")
	end
end

ModLuaFileAppend("data/scripts/buildings/teleport_liquid_check.lua", "data/archipelago/scripts/patches/ap_extend_portals_liquid_check.lua")
