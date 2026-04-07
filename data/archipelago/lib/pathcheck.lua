
local source_path = (debug.getinfo(3, "S") or {}).source
print_error(source_path)

local is_bad_path = false
local mod_path = "mods/archipelago/"
if source_path ~= nil then
	local path = source_path:match("(.+)init.lua")
	mod_path = path

	if path ~= "mods/archipelago/" then
		is_bad_path = true
	end
end

---Retrieves the mod path only if it is incorrectly located.
---@return string|nil nil if the path is correct, otherwise the currently bad path
function BadPath()
	if is_bad_path then return mod_path end
	return nil
end

---Retrieves the current mod path.
---@return string
function ModPath()
	return mod_path
end
