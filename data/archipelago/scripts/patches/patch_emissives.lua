-- Emissive sprites do not get passed to the shader, so our shader based traps render incorrectly.
-- We try to "fix" this by disabling some emissive properties.

local nxml = dofile_once("data/archipelago/lib/nxml.lua") ---@type nxml
dofile_once("data/scripts/gun/gun_actions.lua")

local function get_projectile(related)
	if type(related) == "string" then return related end
	if type(related) == "table" and type(related[1]) == "string" then return related[1] end
	return ""
end


local modify_list = {}

for _,action in ipairs(actions) do
	local file = get_projectile(action.related_projectiles)
	if ModDoesFileExist(file) then
		modify_list[file] = true

		local xml = nxml.parse_file(file)

		for comp in xml:each_of("Base") do
			local basefile = tostring(comp:get("file"))
			if ModDoesFileExist(basefile) then
				modify_list[basefile] = true
			end
		end

		for comp in xml:each_of("ProjectileComponent") do
			local muzzle = tostring(comp:get("muzzle_flash_file"))
			if ModDoesFileExist(muzzle) then
				modify_list[muzzle] = true
			end
		end
	end
end

for file,_ in pairs(modify_list) do
	for xml in nxml.edit_file(file) do
		for comp in xml:each_of("SpriteComponent") do
			comp:set("emissive", 0)
		end
	end
end
