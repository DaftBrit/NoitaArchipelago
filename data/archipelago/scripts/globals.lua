local Global = dofile("data/archipelago/lib/globals_manager.lua")
local GlobalComplex = dofile("data/archipelago/lib/global_complex.lua")

return {
	LocationUnlockQueue = GlobalComplex("AP_COMPONENT_ITEM_UNLOCK_QUEUE"),
	ShopScoutedQueue = GlobalComplex("AP_COMPONENT_SHOPITEM_SCOUTED_QUEUE"),
	ShopScouted = GlobalComplex("AP_COMPONENT_SHOPITEM_SCOUTED"),
	Seed = Global("ARCHIPELAGO_SEED"),
	FirstLoadDone = Global("ARCHIPELAGO_FIRST_LOAD_DONE"),
	PlayerSlot = Global("ARCHIPELAGO_PLAYER_SLOT"),
	HMPortalsUnlocked = Global("ARCHIPELAGO_PORTALS_UNLOCKED"),

	LocationScouts = GlobalComplex("AP_LOCATIONSCOUTS_DATA"),
	MissingLocationsSet = GlobalComplex("AP_MISSING_LOCATIONS"),
	PedestalLocationsSet = GlobalComplex("AP_PEDESTAL_LOCATIONS"),
}
