---@type nxml
local nxml = dofile_once("data/archipelago/lib/nxml.lua")

local scenePaths = {
	"data/biome/_pixel_scenes.xml",
	"data/biome/_pixel_scenes_newgame_plus.xml",
}

for _, scenePath in ipairs(scenePaths) do
	for xml in nxml.edit_file(scenePath) do
		local scenes = xml:first_of("PixelSceneFiles")

		-- Create the tag if a mod has mucked with it
		if not scenes then
			scenes = xml:create_child("PixelSceneFiles")
		end
		scenes:add_child(nxml.parse([[<File>data/archipelago/biome_impl/ap_egg.xml</File>]]))
	end
end
