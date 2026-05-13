
local Globals = dofile("data/archipelago/scripts/globals.lua") --- @type Globals
local Log = dofile("data/archipelago/scripts/logger.lua") ---@type Logger

--[[
TrapLink spreadsheet candidates:
- Fungal Shift Trap
- Polymorph Trap
- Blind Trap
- Invisible Enemies Trap
- Chaos Polymorph Trap
]]

local traplink_aliases_recv = {
	["ANIMAL TRAP"] = "AP_POLY_SELF",
	["BOMB TRAP"] = "RAIN_BOMB",
	["BOMB"] = "RAIN_BOMB",
	["BONK TRAP"] = "AP_STUN",
	["BULLET TIME TRAP"] = "SLOW_BULLETS",
	["BURN TRAP"] = "AP_ON_FIRE",
	["CHAOS CONTROL TRAP"] = "AP_STUN",
	["CONFUSE TRAP"] = "AP_CONFUSION",
	["CONFUSION TRAP"] = "AP_CONFUSION",
	["CONFOUND TRAP"] = "AP_CONFUSION",
	["ELECTROCUTION TRAP"] = "AP_STUN",
	["FIRE TRAP"] = "AP_ON_FIRE",
	["GAS TRAP"] = "PLAYER_GAS",
	["GHOST"] = "TINY_GHOST_ENEMY",
	["HICCUP TRAP"] = "DRUNK_PLAYER",
	["PARALYSIS TRAP"] = "AP_STUN",
	["PARALYZE TRAP"] = "AP_STUN",
	["POLICE TRAP"] = "SPAWN_SHOPKEEPER",
	["REVERSAL TRAP"] = "AP_CONFUSION",
	["REVERSE CONTROLS TRAP"] = "AP_CONFUSION",
	["REVERSE TRAP"] = "AP_CONFUSION",
	["SLOW TRAP"] = "SLOW_PLAYER",
	["FRAME SLIME TRAP"] = "SLOW_PLAYER",
	["SLOWNESS TRAP"] = "SLOW_PLAYER",
	["CURSE TRAP"] = "SLOW_PLAYER",
	["STUN TRAP"] = "AP_STUN",
	["TELEPORT TRAP"] = "AP_TELEPORT",
	["POISON TRAP"] = "AP_POISON",
	["POISON MUSHROOM"] = "AP_POISON",
	["CHAOS TRAP"] = "AP_CHAOS_FUNGAL_SHIFT",
	["BEE TRAP"] = "AP_BEES",
	["ICE TRAP"] = "AP_FREEZE",
	["FREEZE TRAP"] = "AP_FREEZE",
	["FROZEN TRAP"] = "AP_FREEZE",
	["FROST TRAP"] = "AP_CHILLED",
	["TNT TRAP"] = "AP_TNT",
	["TNT BARREL TRAP"] = "AP_TNT_BARREL",
	["PIXELATE TRAP"] = "AP_144P",
	["PIXELLATION TRAP"] = "AP_144P",
	["144P TRAP"] = "AP_144P",
	["FLIP VERTICAL TRAP"] = "AP_FLIP_VER",
	["SCREEN FLIP TRAP"] = "AP_FLIP_HOR",
	["FLIP HORIZONTAL TRAP"] = "AP_FLIP_HOR",
	["FLIP TRAP"] = "AP_FLIP_HOR",
	["MIRROR TRAP"] = "AP_FLIP_HOR",
	["ZOOM IN TRAP"] = "AP_ZOOM_IN",
	["ZOOM OUT TRAP"] = "AP_ZOOM_OUT",
	["ZOOM TRAP"] = "AP_ZOOM_IN",
	["FISH EYE TRAP"] = "AP_FISH_EYE",
	["INVERT COLORS TRAP"] = "AP_INVERT_COLOUR",
	["RANDOM STATUS TRAP"] = "AP_RANDOM_STATUS",
	["CLEAR IMAGE TRAP"] = "REMOVE_GROUND",
	["DAMAGE TRAP"] = "AP_INSTANT_DAMAGE",
	["INSTANT DEATH TRAP"] = "AP_INSTANT_DEATH",
	["BLUE BALLS CURSE"] = "AP_ONE_HP",
	["ONE HIT KO"] = "AP_ONE_HP",
	["INVISIBLE TRAP"] = "AP_INVIS_BAD",
	["INVISIBILITY TRAP"] = "AP_INVIS_BAD",
	["INVISIBALL TRAP"] = "AP_INVIS_BAD",
	["MANA DRAIN TRAP"] = "AP_MANA_DRAIN",
	["FROG TRAP"] = "AP_POLY_FROG",
	["EXTREME CHAOS MODE"] = "AP_EXTREME_CHAOS",
	["RADIATION TRAP"] = "AP_RADIOACTIVE",
	["GRAVITY_TRAP"] = "GRAVITY_PLAYER",
	["WHOOPS! TRAP"] = "AP_WHOOPS_TRAP",
	["EMPTY ITEM BOX TRAP"] = "AP_EMPTY_ITEM_BOX",
	["EJECT ABILITY"] = "AP_EJECT_ABILITY",
	["DOUBLE DAMAGE"] = "AP_DOUBLE_DAMAGE",
	["CAMERA ROTATE TRAP"] = "AP_CAMERA_ROTATE",
	["AAA TRAP"] = "AP_SHEEP_SFX",
	["BUBBLE TRAP"] = "AP_STUN",
	["FAST TRAP"] = "AP_BECOME_SPEED",
	["ENCHANTMENT TRAP"] = "AP_BECOME_SPEED",
	["GADGET SHUFFLE TRAP"] = "AP_SPELL_SHUFFLE",
	["Sticky Floor Trap"] = "AP_STICKY_GROUND",
}

local traplink_aliases_send = {
	AP_CONFUSION = "Confuse Trap",
	AP_ON_FIRE = "Fire Trap",
	AP_POLY_SELF = "Animal Trap",
	AP_STUN = "Stun Trap",
	DRUNK_PLAYER = "Hiccup Trap",
	PLAYER_GAS = "Gas Trap",
	RAIN_BOMB = "Bomb Trap",
	SLOW_BULLETS = "Bullet Time Trap",
	SLOW_PLAYER = "Slow Trap",
	SPAWN_SHOPKEEPER = "Police Trap",
	TINY_GHOST_ENEMY = "Ghost",
	TWITCH_EXTENDED_FIRE_TRAP = "Fire Trap",
	TWITCH_EXTENDED_STUN = "Stun Trap",
	TWITCH_EXTENDED_TP_STREAMER = "Teleport Trap",
	AP_TELEPORT = "Teleport Trap",
	AP_POISON = "Poison Trap",
	AP_CHAOS_FUNGAL_SHIFT = "Chaos Trap",
	TWITCH_EXTENDED_FUNGAL_SHIFT = "Chaos Trap",
	AP_BEES = "Bee Trap",
	AP_FREEZE = "Ice Trap",
	AP_CHILLED = "Frost Trap",
	AP_TNT = "TNT Trap",
	AP_TNT_BARREL = "TNT Barrel Trap",
	AP_144P = "Pixelate Trap",
	AP_FLIP_VER = "Flip Vertical Trap",
	AP_FLIP_HOR = "Flip Horizontal Trap",
	AP_ZOOM_IN = "Zoom Trap",
	AP_ZOOM_OUT = "Zoom Out Trap",
	AP_FISH_EYE = "Fish Eye Trap",
	AP_INVERT_COLOUR = "Invert Colors Trap",
	AP_RANDOM_STATUS = "Random Status Trap",
	REMOVE_GROUND = "Clear Image Trap",
	AP_INSTANT_DAMAGE = "Damage Trap",
	AP_INSTANT_DEATH = "Instant Death Trap",
	AP_ONE_HP = "One Hit KO",
	AP_INVIS_BAD = "Invisible Trap",
	AP_MANA_DRAIN = "Mana Drain Trap",
	AP_POLY_FROG = "Frog Trap",
	AP_EXTREME_CHAOS = "Extreme Chaos Mode",
	AP_RADIOACTIVE = "Radiation Trap",
	GRAVITY_PLAYER = "Gravity Trap",
	AP_WHOOPS_TRAP = "Whoops! Trap",
	AP_EMPTY_ITEM_BOX = "Empty Item Box Trap",
	AP_EJECT_ABILITY = "Eject Ability",
	AP_DOUBLE_DAMAGE = "Double Damage",
	AP_CAMERA_ROTATE = "Camera Rotate Trap",
	AP_SHEEP_SFX = "Aaa Trap",
	AP_BECOME_SPEED = "Fast Trap",
	AP_SPELL_SHUFFLE = "Gadget Shuffle Trap",
	AP_STICKY_GROUND = "Sticky Floor Trap",
}

local ap_streaming_initialized = false
local ap_local_streaming_events = {} ---@type table[]
local ap_local_streaming_event_lookup = {} ---@type {[string]: table}

function InitStreamingTraps()
	if ap_streaming_initialized then return end
	ap_streaming_initialized = true

	dofile_once("data/scripts/streaming_integration/event_list.lua")
	for _, event in ipairs(streaming_events) do
		if event.kind and event.kind <= STREAMING_EVENT_BAD then
			ap_local_streaming_event_lookup[event.id] = event
		end
	end
end

local function UpdateEnabledTraps()
	dofile_once("data/scripts/streaming_integration/event_list.lua")

	ap_local_streaming_events = {}
	for _, event in ipairs(streaming_events) do
		if event.enabled == nil or event.enabled then
			if event.kind and event.kind <= STREAMING_EVENT_BAD then
				table.insert(ap_local_streaming_events, event)
			end
		end
	end
end

---Rewrite of `_streaming_run_event`
---@param id string
function RunStreamingEvent(id)
	local evt = ap_local_streaming_event_lookup[id]
	if evt == nil then
		Log.Error("Streaming event id doesn't exist: " .. id)
		return
	end

	if evt.id == id then
		if evt.action_delayed ~= nil then
			if evt.delay_timer ~= nil then
				local p = get_players()
				for _,player in ipairs(p) do
					add_timer_above_head(player, evt.id, evt.delay_timer)
				end
			end
		elseif evt.action ~= nil then
			evt.action(evt)
		end
	end
end

---Function to spawn traps, uses the noita streaming integration system
---Also look at https://github.com/Miczu/Noita-Twitch-Integration for more bad events ideas.
---@return string? event_id
local function RandomStreamingEventTrap()
	UpdateEnabledTraps()
	if #ap_local_streaming_events == 0 then
		Log.Error("No traps are enabled!")
		return nil
	end

	-- TODO weighted random sample based on `event.weight`

	local event = ap_local_streaming_events[Random(1, #ap_local_streaming_events)]
	GamePrintImportant(event.ui_name, event.ui_description)
	RunStreamingEvent(event.id)
	return event.id
end

--- Receive a trap from TrapLink
---@param source string?
---@param trap_name string
function RecvTrapLink(source, trap_name)
	InitStreamingTraps()

	local noita_trap_name = traplink_aliases_recv[trap_name:upper()]
	if noita_trap_name == nil then
		Log.Warn("No trap name found for: " .. trap_name)
		return
	end

	local message = GameTextGet("$ap_trap_triggered", source or "Unknown", trap_name)
	GamePrintImportant(message, "$ap_trap_triggered_desc")
	RunStreamingEvent(noita_trap_name)
end

---Chooses a random trap, adds it to the trap link queue if it is translatable
---@param notraplink bool? disables sending a traplink, i.e. for when we use traps for deathlink or other mechanic
function BadTimes(notraplink)
	InitStreamingTraps()
	local noita_id = RandomStreamingEventTrap()

	if not notraplink then
		local traplink_name = traplink_aliases_send[noita_id]
		if traplink_name ~= nil then
			Globals.TrapLinkQueue:append(traplink_name)
		end
	end
end
