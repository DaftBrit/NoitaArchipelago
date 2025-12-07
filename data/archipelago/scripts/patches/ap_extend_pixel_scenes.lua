---@type nxml
local nxml = dofile_once("data/archipelago/lib/nxml.lua")

local scenePaths = {
	"data/biome/_pixel_scenes.xml",
	"data/biome/_pixel_scenes_newgame_plus.xml",
}

for _, scenePath in ipairs(scenePaths) do
	for xml in nxml.edit_file(scenePath) do
		-- Create the tag if a mod has mucked with it
		local scenes = xml:first_of("PixelSceneFiles")
		if not scenes then
			scenes = xml:create_child("PixelSceneFiles")
		end
		scenes:add_child(nxml.parse([[<File>data/archipelago/biome_impl/ap_egg.xml</File>]]))

		-- Also add the fog hole punch here so it reveals faster
		local buffered = xml:first_of("mBufferedPixelScenes")
		if not buffered then
			buffered = xml:create_child("mBufferedPixelScenes")
		end
		buffered:create_child("PixelScene", {
			pos_x = -16384 + 245,
			pos_y = 13824 + 256,
			just_load_an_entity = "data/archipelago/entities/buildings/ap_fog_holepuncher.xml",
		})
	end
end
