local nxml = dofile_once("data/archipelago/lib/nxml.lua")

local scenePaths = {
	"data/biome/_pixel_scenes.xml",
	"data/biome/_pixel_scenes_newgame_plus.xml",
}

function APExtendPixelScenes()
	for _, scenePath in ipairs(scenePaths) do

		local content = ModTextFileGetContent(scenePath)
		local xml = nxml.parse(content)
		xml:first_of("PixelSceneFiles"):add_child(nxml.parse([[<File>data/archipelago/biome_impl/ap_egg.xml</File>]]))
		ModTextFileSetContent(scenePath, tostring(xml))

	end
end

APExtendPixelScenes()