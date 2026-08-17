local Global = dofile("data/archipelago/lib/globals_manager.lua") --- @type Global
local GlobalComplex = dofile("data/archipelago/lib/global_complex.lua") --- @type GlobalComplex
local GlobalOption = dofile("data/archipelago/lib/cross_script_opt.lua") --- @type GlobalOption

--- @class Globals
local Globals = {
	LocationUnlockQueue = GlobalComplex("AP_COMPONENT_ITEM_UNLOCK_QUEUE"), --- @type GlobalComplex
	ShopScoutedQueue = GlobalComplex("AP_COMPONENT_SHOPITEM_SCOUTED_QUEUE"), --- @type GlobalComplex
	ShopScouted = GlobalComplex("AP_COMPONENT_SHOPITEM_SCOUTED"), --- @type GlobalComplex
	RedeliveryQueue = GlobalComplex("AP_REDELIVERY_QUEUE"), --- @type GlobalComplex
	Seed = Global("ARCHIPELAGO_SEED"), --- @type Global
	FirstLoadDone = Global("ARCHIPELAGO_FIRST_LOAD_DONE"), --- @type Global
	PlayerSlot = Global("ARCHIPELAGO_PLAYER_SLOT"), --- @type Global
	RoomID = Global("AP_ROOM_ID"), --- @type Global
	HMPortalsUnlocked = Global("ARCHIPELAGO_PORTALS_UNLOCKED"), --- @type Global

	LocationScouts = GlobalComplex("AP_LOCATIONSCOUTS_DATA"), --- @type GlobalComplex
	MissingLocationsSet = GlobalComplex("AP_MISSING_LOCATIONS"), --- @type GlobalComplex
	PedestalLocationsSet = GlobalComplex("AP_PEDESTAL_LOCATIONS"), --- @type GlobalComplex

	LogHistory = GlobalComplex("AP_LOG_HISTORY"), --- @type GlobalComplex
	TrapLinkQueue = GlobalComplex("AP_TRAP_LINK_QUEUE"), --- @type GlobalComplex
	DamageLinkQueue = GlobalComplex("AP_DAMAGE_LINK_QUEUE"), --- @type GlobalComplex

	--- Uses the array index as id, i.e. Sky island tablet = id 1, Lava Lake = id 2
	--- As long as the locations are consistent the contents don't really matter, since they'll be provided by the apworld.
	--- @type GlobalComplex
	HiddenHints = GlobalComplex("AP_HIDDEN_HINTS"),

	DeathLinkSetting = GlobalOption("AP_DEATHLINK"), --- @type GlobalOption
	TrapLinkSetting = GlobalOption("AP_TRAPLINK"), --- @type GlobalOption
	DamageLinkSetting = GlobalOption("AP_DAMAGELINK"), --- @type GlobalOption
}

return Globals
