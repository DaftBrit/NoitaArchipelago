return {
	-- Item IDs
	TRAP_ID = 110000,

	-- Location IDs
	FIRST_SHOP_LOCATION_ID = 111000,
	LAST_SHOP_LOCATION_ID = 111045,

	FIRST_ORB_LOCATION_ID = 110658,
	LAST_ORB_LOCATION_ID = 110668,

	FIRST_SPELL_REFRESH_LOCATION_ID = 110005,
	FIRST_SECRET_SHOP_LOCATION_ID = 110042,
	LAST_SECRET_SHOP_LOCATION_ID = 110045,

	-- The below are for the hidden chests and pedestals in different biomes
	FIRST_BIOME_LOCATION_ID = 110046,
	LAST_BIOME_LOCATION_ID = 110645,


	-- Item IDs for items where we want to spawn them a little differently
	HEART_ITEM_ID = 110001,
	MAP_PERK_ID = 110020,
	ORB_ITEM_ID = 110022,


	-- Item flag constants.
	-- See https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#networkitem
	ITEM_FLAG_PROGRESSION = 1,
	ITEM_FLAG_USEFUL = 2,
	ITEM_FLAG_TRAP = 4,
}