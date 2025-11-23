dofile_once("data/scripts/game_helpers.lua")
dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/archipelago/scripts/ap_utils.lua")

local function APOrbInitRandom()
	local AP = dofile("data/archipelago/scripts/constants.lua")
	local Globals = dofile("data/archipelago/scripts/globals.lua")

	local entity_id = GetUpdatedEntityID()
	local pos_x, pos_y = EntityGetTransform(entity_id)

	local orbcomp = EntityGetComponent(entity_id, "OrbComponent")
	local spritecomp = EntityGetComponent(entity_id, "SpriteComponent")
	local orb_id = -1

	for _, comp_id in pairs(orbcomp) do
		orb_id = ComponentGetValue2(comp_id, "orb_id")
		--this variable just stores the original orb_id elsewhere
		addNewInternalVariable(entity_id, "OriginalID", "value_int", orb_id)
		EntityRemoveComponent(entity_id, comp_id)
	end

	local pw_offset = 0
	if pos_x <= -17920 then
		-- west orbs have orb_id increased by 128, and location_ids are increased by 669
		pw_offset = AP.WEST_OFFSET - 128
	elseif pos_x >= 17920 then
		-- east orbs have orb_id increased by 256, and location_ids are increased by 1338
		pw_offset = AP.EAST_OFFSET - 256
	end
	local location_id = orb_id + AP.FIRST_ORB_LOCATION_ID + pw_offset
	if not Globals.MissingLocationsSet:has_key(location_id) then return end

	local location = Globals.LocationScouts:get_key(location_id)
	local flags = location.item_flags
	local orb_image = "ap_logo_orb"
	local enable_prog_icon = false
	local enable_useful_icon = false
	local enable_filler_icon = true

	if bit.band(flags, AP.ITEM_FLAG_USEFUL) ~= 0 then
		enable_useful_icon = true
		enable_filler_icon = false
	end
	if bit.band(flags, AP.ITEM_FLAG_PROGRESSION) ~= 0 then
		enable_prog_icon = true
		enable_filler_icon = false
	end

	if bit.band(flags, AP.ITEM_FLAG_TRAP) ~= 0 then
		orb_image = "ap_logo_orb_trap_" .. tostring(Random(1,3))
		-- if it is not prog+trap or useful+trap, give it a random icon
		if enable_filler_icon then
			local random_number = Random(1, 3)
			if random_number == 1 then
				enable_filler_icon = false
				enable_prog_icon = true
			elseif random_number == 2 then
				enable_filler_icon = false
				enable_useful_icon = true
			end
		end
	end

	if flags ~= nil then
		for _, comp_id in pairs(spritecomp) do
			ComponentSetValue2(comp_id, "image_file", "data/items_gfx/orbs/orb.xml")
		end

		EntityAddComponent2(entity_id, "SpriteComponent", {
			image_file = "data/archipelago/entities/items/icons/" .. orb_image .. ".png",
			offset_x = 7,
			offset_y = 20,
			z_index = 0.8,
			update_transform_rotation = false
		})
		if enable_prog_icon == true then
			EntityAddComponent2(entity_id, "SpriteComponent", {
				image_file = "data/archipelago/entities/items/icons/progression_icon.png",
				offset_x = 0,
				offset_y = 10,
				z_index = 0.7,
			})
		end
		if enable_useful_icon == true then
			EntityAddComponent2(entity_id, "SpriteComponent", {
				image_file = "data/archipelago/entities/items/icons/useful_icon.png",
				offset_x = 7,
				offset_y = 19,
				z_index = 0.7,
			})
		end
		if enable_filler_icon == true then
			EntityAddComponent2(entity_id, "SpriteComponent", {
				image_file = "data/archipelago/entities/items/icons/filler_icon.png",
				offset_x = 0,
				offset_y = 10,
				z_index = 0.7,
			})
		end
	end
end

APOrbInitRandom()
