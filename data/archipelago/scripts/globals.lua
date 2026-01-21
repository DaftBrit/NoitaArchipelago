local Global = dofile("data/archipelago/lib/globals_manager.lua") --- @type Global
local GlobalComplex = dofile("data/archipelago/lib/global_complex.lua") --- @type GlobalComplex

--- @class Globals
local Globals = {
	LocationUnlockQueue = GlobalComplex("AP_COMPONENT_ITEM_UNLOCK_QUEUE"), --- @type GlobalComplex
	ShopScoutedQueue = GlobalComplex("AP_COMPONENT_SHOPITEM_SCOUTED_QUEUE"), --- @type GlobalComplex
	ShopScouted = GlobalComplex("AP_COMPONENT_SHOPITEM_SCOUTED"), --- @type GlobalComplex
	Seed = Global("ARCHIPELAGO_SEED"), --- @type Global
	FirstLoadDone = Global("ARCHIPELAGO_FIRST_LOAD_DONE"), --- @type Global
	PlayerSlot = Global("ARCHIPELAGO_PLAYER_SLOT"), --- @type Global
	HMPortalsUnlocked = Global("ARCHIPELAGO_PORTALS_UNLOCKED"), --- @type Global

	LocationScouts = GlobalComplex("AP_LOCATIONSCOUTS_DATA"), --- @type GlobalComplex
	MissingLocationsSet = GlobalComplex("AP_MISSING_LOCATIONS"), --- @type GlobalComplex
	PedestalLocationsSet = GlobalComplex("AP_PEDESTAL_LOCATIONS"), --- @type GlobalComplex

	LogHistory = GlobalComplex("AP_LOG_HISTORY"), --- @type GlobalComplex
}

return Globals
