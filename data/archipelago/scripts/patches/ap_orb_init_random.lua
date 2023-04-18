dofile_once( "data/scripts/game_helpers.lua" )
dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/archipelago/scripts/ap_utils.lua")

local function APOrbInitRandom()
	local AP = dofile("data/archipelago/scripts/constants.lua")
	local Globals = dofile("data/archipelago/scripts/globals.lua")
	local Constants = dofile("data/archipelago/scripts/constants.lua")

	local entity_id = GetUpdatedEntityID()
	local pos_x, pos_y = EntityGetTransform(entity_id)

	local orbcomp = EntityGetComponent(entity_id, "OrbComponent")
	local spritecomp = EntityGetComponent(entity_id, "SpriteComponent")
	local orb_id = -1

	for _, comp_id in pairs(orbcomp) do
		orb_id = ComponentGetValueInt(comp_id, "orb_id")
		EntityRemoveComponent(entity_id, comp_id)
	end

	local location_id = orb_id + Constants.FIRST_ORB_LOCATION_ID
	if not Globals.MissingLocationsSet:has_key(location_id) then return end

	local location = Globals.LocationScouts:get_key(location_id)
	local flags = location.item_flags
	local orb_image = "ap_logo_orb"
	local check_type_icon = "filler_icon"

	--this variable just stores the original orb_id elsewhere
	addNewInternalVariable(entity_id, "OriginalID", "value_int", orb_id)

	if flags == nil then
		print("this orb is not a location check")
	elseif bit.band(flags, AP.ITEM_FLAG_TRAP) ~= 0 then
		check_type_icon = "empty_icon"
		orb_image = "ap_logo_orb_trap_" .. tostring(Random(1,3))
	elseif bit.band(flags, AP.ITEM_FLAG_USEFUL) ~= 0 then
		check_type_icon = "empty_icon"
	elseif bit.band(flags, AP.ITEM_FLAG_PROGRESSION) ~= 0 then
		check_type_icon = "progression_icon"
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
		})

		EntityAddComponent2(entity_id, "SpriteComponent", {
			image_file = "data/archipelago/entities/items/icons/" .. check_type_icon .. ".png",
			offset_x = 0,
			offset_y = 10,
			z_index = 0.7,
		})
	end
end

APOrbInitRandom()
