---@class Constants
return {
	-- Item flag constants.
	-- See https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#networkitem
	ITEM_FLAG_PROGRESSION = 1, --- @type integer
	ITEM_FLAG_USEFUL = 2, --- @type integer
	ITEM_FLAG_TRAP = 4, --- @type integer

	-------------------------------------------------------------------------
	-- Item IDs
	TRAP_ID = 110000, --- @type integer

	-- Location IDs
	-- 5 items per shop followed by the spell refresh, 6 per Holy Mountain
	FIRST_SHOP_LOCATION_ID = 110000, --- @type integer
	LAST_SHOP_LOCATION_ID = 110045, --- @type integer

	FIRST_ORB_LOCATION_ID = 110658, --- @type integer
	LAST_ORB_LOCATION_ID = 110668, --- @type integer

	FIRST_SPELL_REFRESH_LOCATION_ID = 110005, --- @type integer
	FIRST_SECRET_SHOP_LOCATION_ID = 110042, --- @type integer
	LAST_SECRET_SHOP_LOCATION_ID = 110045, --- @type integer

	-- The below are for the hidden chests and pedestals in different biomes
	FIRST_BIOME_LOCATION_ID = 110046, --- @type integer
	LAST_BIOME_LOCATION_ID = 110645, --- @type integer

	-- Parallel world location ID offsets, to be added to location IDs for pw locations
	WEST_OFFSET = 669, --- @type integer
	EAST_OFFSET = 1338, --- @type integer

	-- Parallel world exclusions
	LAVA_LAKE_ORB = 110661, --- @type integer
	FIRST_NON_PW_SHOP = 110036, --- @type integer
	LAST_NON_PW_SHOP = 110045, --- @type integer

	-- Item IDs for items where we want to spawn them a little differently
	HEART_ITEM_ID = 110001, --- @type integer
	REFRESH_ITEM_ID = 110002, --- @type integer
	POTION_ITEM_ID = 110003, --- @type integer
	FIRST_WAND_ITEM_ID = 110006, --- @type integer
	LAST_WAND_ITEM_ID = 110012, --- @type integer
	MAP_PERK_ID = 110020, --- @type integer
	ORB_ITEM_ID = 110022, --- @type integer
	RANDOM_POTION_ITEM_ID = 110023, --- @type integer
	SECRET_POTION_ITEM_ID = 110024, --- @type integer
	POWDER_STASH_ITEM_ID = 110025, --- @type integer
	KAMMI_ITEM_ID = 110028, --- @type integer
	GOURD_ITEM_ID = 110029, --- @type integer
	BEAMSTONE_ITEM_ID = 110030, --- @type integer
	BROKEN_WAND_ITEM_ID = 110031, --- @type integer

	-- Major update stuff

	-- this is required 7 times or not at all per new slot option
	PROGRESSIVE_PORTAL_ITEM_ID = 20000, --- @type integer

	-- not sure how to do these yet
	PROGRESSIVE_LEFT_PARALLEL_WORLD = 20001, --- @type integer
	PROGRESSIVE_RIGHT_PARALLEL_WORLD = 20002, --- @type integer

	-- Killsanity
	FIRST_ANIMAL_LOCATION_ID = 200000, --- @type integer

	-- Spellsanity
	SPELL_FIRST_ITEM_ID = 30000, --- @type integer

	-- Perksanity
	UNLOCK_PERK_FIRST_ITEM_ID = 40000, --- @type integer
}