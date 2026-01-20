local nxml = dofile_once("data/archipelago/lib/nxml.lua") ---@type nxml

--- @class Modlist
local Modlist = {}

---Gets list of all mod ids by calling ModGetActiveModIDs.
---@return string[]
function Modlist.GetIDs()
	return ModGetActiveModIDs()
end

---Checks if XML element has a boolean flag set
---@param modxml element
---@param tagname string
---@return boolean
local function xml_has_flag(modxml, tagname)
	local value = modxml:get(tagname)
	return value ~= nil and value ~= "0"
end

---Unprotected file read
---@param filename string
---@return string
local function read_whole_file(filename)
	local f = io.open(filename, "r")
	local result = f:read("*a")
	f:close()
	return result
end

---Get detailed description of a mod by reading its mod.xml.
---@param modid string
---@return string
function Modlist.GetDetails(modid)
	local modxmlfilename = "mods/" .. modid .. "/mod.xml"
	if ModDoesFileExist(modxmlfilename) then
		local modxml = nxml.parse_file(modxmlfilename, read_whole_file)

		local modname = modxml:get("name") or modid
		local moddesc = modxml:get("description") or ""

		local tags = {}
		if xml_has_flag(modxml, "request_no_api_restrictions") then
			table.insert(tags, "unsafe")
		end

		if xml_has_flag(modxml, "is_game_mode") then
			table.insert(tags, "gamemode")
		end

		if xml_has_flag(modxml, "game_mode_supports_save_slots") then
			table.insert(tags, "saveslots")
		end

		if xml_has_flag(modxml, "is_translation") then
			table.insert(tags, "translation")
		end

		local modentry = modname .. " [" .. modid .. "] - " .. moddesc
		if #tags ~= 0 then
			modentry = modentry .. " (" .. table.concat(tags, ", ") .. ")"
		end
		return modentry
	else
		return modid .. " - mod.xml not found (Steam?)"
	end
end

---Gets detailed list of all active mods.
---@return string[]
function Modlist.GetDetailList()
	local result = {}

	for _, modid in ipairs(Modlist.GetIDs()) do
		table.insert(result, Modlist.GetDetails(modid))
	end
	return result
end

return Modlist
