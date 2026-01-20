local ap_original_material_area_checker_failed = material_area_checker_failed
local ap_original_material_area_checker_success = material_area_checker_success

local Globals = dofile_once("data/archipelago/scripts/globals.lua") --- @type Globals

local function get_hm_portal_num(y)
	if y < 1500 then return 1 -- Mines
	elseif y < 3000 then return 2 -- Coal Pits
	elseif y < 5500 then return 3 -- Snowy Depths
	elseif y < 7000 then return 4 -- Hiisi Base
	elseif y < 9500 then return 5 -- Underground Jungle
	elseif y < 11500 then return 6 -- The Vault
	else return 7 -- Temple of the Art
	end
end

-- true if unlocked, false if locked
local function archipelago_test_portal()
	local entity_id = GetUpdatedEntityID()

	if GameHasFlagRun("ap_portals_locked") then
		local _, y = EntityGetTransform(entity_id)
		local currentHM = get_hm_portal_num(y)
		local totalHM = Globals.HMPortalsUnlocked:get_num(0)
		if currentHM > totalHM then
			-- Portal locked
			EntitySetComponentsWithTagEnabled(entity_id, "enabled_by_liquid", false)
			EntitySetComponentsWithTagEnabled(entity_id, "locked_by_archipelago", true)
			return false
		end
	end

	-- Disable locking mechanism
	EntitySetComponentsWithTagEnabled(entity_id, "locked_by_archipelago", false)
	return true
end

function material_area_checker_failed(pos_x, pos_y)
	local entity_id = GetUpdatedEntityID()

	-- Portal loses teleportatium, should vanish completely
	EntitySetComponentsWithTagEnabled(entity_id, "locked_by_archipelago", false)
	ap_original_material_area_checker_failed(pos_x, pos_y)
end

function material_area_checker_success(pos_x, pos_y)
	if GameHasFlagRun("ap_connected_once") and archipelago_test_portal() then
		ap_original_material_area_checker_success(pos_x, pos_y)
	end
end
