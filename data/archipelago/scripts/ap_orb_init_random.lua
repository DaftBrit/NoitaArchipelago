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

	local location = Globals.LocationScouts:get_key(orb_id + Constants.FIRST_ORB_LOCATION_ID)
	local flags = location.item_flags

	-- there's no AP.ITEM_FLAG_JUNK, so the default appearance is junk instead
	--local orb_file = "ap_orb_junk"

	--if bit.band(flags, AP.ITEM_FLAG_TRAP) ~= 0 then
	--	orb_file = "ap_orb_trap_" .. tostring(Random(1,3))
	--elseif bit.band(flags, AP.ITEM_FLAG_USEFUL) ~= 0 then
	--	orb_file = "ap_orb_useful"
	--elseif bit.band(flags, AP.ITEM_FLAG_PROGRESSION) ~= 0 then
	--	orb_file = "ap_orb_progression"
	--end
	--
	--for _, comp_id in pairs(spritecomp) do
	--	ComponentSetValue2(comp_id, "image_file", "data/archipelago/entities/items/orbs/" .. orb_file .. ".xml")
	--end

	--local orb_file = "ap_orb_useful"
	--
	--for _, comp_id in pairs(spritecomp) do
	--	ComponentSetValue2(comp_id, "image_file", "data/archipelago/entities/items/orbs/" .. orb_file .. ".xml")
	--end

	for _, comp_id in pairs(spritecomp) do
		ComponentSetValue2(comp_id, "image_file", "data/items_gfx/orbs/orb.xml")
	end

	local game_overlay_icon = "ap_logo_orb"
	local overlay_file = "filler_icon"

	if bit.band(flags, AP.ITEM_FLAG_TRAP) ~= 0 then
		overlay_file = "trap_icon"
	elseif bit.band(flags, AP.ITEM_FLAG_USEFUL) ~= 0 then
		print("skip useful for overlay")
	elseif bit.band(flags, AP.ITEM_FLAG_PROGRESSION) ~= 0 then
		overlay_file = "progression_icon"
	end

	local game_overlay_entity = EntityLoad("data/archipelago/entities/items/overlay/" .. game_overlay_icon .. ".xml", pos_x, pos_y)
	EntityAddChild(entity_id, game_overlay_entity)

	local overlay_entity = EntityLoad("data/archipelago/entities/items/overlay/" .. overlay_file .. ".xml", pos_x, pos_y)
	EntityAddChild(entity_id, overlay_entity)

	--this variable just stores the original orb_id elsewhere, not sure if it'll be needed later?
	addNewInternalVariable(entity_id, "OriginalID", "value_int", orb_id)
end

APOrbInitRandom()
