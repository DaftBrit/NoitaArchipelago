return {
	-- Item IDs
	TRAP_ID = 110000,

	-- Location IDs
	FIRST_SHOP_LOCATION_ID = 110000,
	LAST_SHOP_LOCATION_ID = 110045,

	FIRST_ORB_LOCATION_ID = 110658,
	LAST_ORB_LOCATION_ID = 110668,

	FIRST_SPELL_REFRESH_LOCATION_ID = 110005,
	FIRST_SECRET_SHOP_LOCATION_ID = 110042,
	LAST_SECRET_SHOP_LOCATION_ID = 110045,

	-- The below are for the hidden chests and pedestals in different biomes
	FIRST_BIOME_LOCATION_ID = 110046,
	LAST_BIOME_LOCATION_ID = 110645,

	-- Parallel world location ID offsets, to be added to location IDs for pw locations
	WEST_OFFSET = 669,
	EAST_OFFSET = 1338,

	-- Parallel world exclusions
	LAVA_LAKE_ORB = 110661,
	FIRST_NON_PW_SHOP = 110036,
	LAST_NON_PW_SHOP = 110045,


	-- Item IDs for items where we want to spawn them a little differently
	HEART_ITEM_ID = 110001,
	REFRESH_ITEM_ID = 110002,
	POTION_ITEM_ID = 110003,
	FIRST_WAND_ITEM_ID = 110006,
	LAST_WAND_ITEM_ID = 110012,
	MAP_PERK_ID = 110020,
	ORB_ITEM_ID = 110022,
	RANDOM_POTION_ITEM_ID = 110023,
	SECRET_POTION_ITEM_ID = 110024,
	POWDER_STASH_ITEM_ID = 110025,
	KAMMI_ITEM_ID = 110028,


	-- Item flag constants.
	-- See https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#networkitem
	ITEM_FLAG_PROGRESSION = 1,
	ITEM_FLAG_USEFUL = 2,
	ITEM_FLAG_TRAP = 4,
}