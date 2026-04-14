-- streaming_integration/event_list.lua
dofile_once("data/scripts/streaming_integration/event_utilities.lua")
dofile_once("data/archipelago/scripts/ap_utils.lua")
local Log = dofile("data/archipelago/scripts/logger.lua") ---@type Logger

--- Replacement for add_icon_above_head with description included.
---@param game_effect_entity entity_id
---@param icon_file string?
---@param event table
local function AddIconAboveHead(game_effect_entity, icon_file, event)
	if game_effect_entity == nil then return end
	EntityAddComponent2( game_effect_entity, "UIIconComponent",
	{
		name = event.ui_name,
		description = event.ui_description,
		icon_sprite_file = icon_file,
		display_above_head = true,
		display_in_hud = false,
		is_perk = false,
	})
end

---@param effect_entity entity_id
---@param icon_file string?
---@param event table
---@param hudonly boolean?
local function AddIcon(effect_entity, icon_file, event, hudonly)
	if hudonly then
		add_icon_in_hud(effect_entity, icon_file, event)
	else
		AddIconAboveHead(effect_entity, icon_file, event)
	end
end

---@param event table
---@param game_effect string
---@param frames integer
---@param icon string
---@param hudonly boolean?
local function ApplyStatusEffect(event, game_effect, frames, icon, hudonly)
	local player = get_player_always()
	if player == nil then return end

	local effect_comp, effect_entity = GetGameEffectLoadTo(player, game_effect, false)
	if effect_comp ~= 0 and effect_entity ~= 0 then
		ComponentSetValue2(effect_comp, "frames", frames)
		AddIcon(effect_entity, icon, event, hudonly)
	end
end

---@param event table
---@param game_effect_file string
---@param frames integer
---@param icon string
---@param hudonly boolean?
local function ApplyCustomStatusEffect(event, game_effect_file, frames, icon, hudonly)
	local player = get_player_always()
	if player == nil then return end

	local effect_entity = LoadGameEffectEntityTo(player, game_effect_file)
	if effect_entity ~= 0 then
		local effect_comp = EntityGetFirstComponent(effect_entity, "GameEffectComponent")
		if effect_comp ~= nil then
			ComponentSetValue2(effect_comp, "frames", frames)
		end
		AddIcon(effect_entity, icon, event, hudonly)
	end
end

---@type string[]?
local chaos_fungal_shift_pool = nil
local banned_fungal_list = {
	rat_powder = true,
	fungus_powder = true,
	fungus_powder_bad = true,
	monster_powder_test = true,
	rock_hard = true,
	rock_hard_border = true,
}

local total_random_calls = 0
local function InitRandomSeed()
	local x, y = get_spawn_position()
	SetRandomSeed(x + GameGetFrameNum(), y + total_random_calls)
	total_random_calls = total_random_calls + 1
end

local function InitFungalPool()
	if chaos_fungal_shift_pool ~= nil then return end
	chaos_fungal_shift_pool = {}

	-- Same pool as fungal pain
	---@type string[][]
	local all_materials = {
		CellFactory_GetAllLiquids(false),
		CellFactory_GetAllSands(false),
		CellFactory_GetAllGases(false),
		CellFactory_GetAllFires(false),
	}

	for _, category in ipairs(all_materials) do
		for _, material in ipairs(category) do
			local id = CellFactory_GetType(material)
			if not banned_fungal_list[material] and not CellFactory_HasTag(id, "[NO_FUNGAL_SHIFT]") and not CellFactory_HasTag(id, "[box2d]") then
				table.insert(chaos_fungal_shift_pool, material)
			end
		end
	end
end

local already_has_fungal_icon = false
local function HasFungalShiftIcon(entity)
	if already_has_fungal_icon then return true end

	if entity == nil then return false end
	local children = EntityGetAllChildren(entity) or {}
	for _, it in ipairs(children) do
		if (EntityGetName(it) == "fungal_shift_ui_icon") then
			already_has_fungal_icon = true
			return true
		end
	end
	return false
end

local function AddFungalShiftIcon()
	local player = get_player()
	if player == nil or HasFungalShiftIcon(player) then return end

	local icon_entity = EntityCreateNew("fungal_shift_ui_icon")
	EntityAddComponent2(icon_entity, "UIIconComponent", {
		name = "$status_reality_mutation",
		description = "$statusdesc_reality_mutation",
		icon_sprite_file = "data/ui_gfx/status_indicators/fungal_shift.png"
	})
	EntityAddChild(player, icon_entity)
end

local function ChaosFungalShift()
	InitRandomSeed()
	InitFungalPool()

	-- Randomize materials
	local from_material = chaos_fungal_shift_pool[Random(1, #chaos_fungal_shift_pool)]
	local to_material = nil
	for _ = 1,1000 do
		to_material = chaos_fungal_shift_pool[Random(1, #chaos_fungal_shift_pool)]
		if to_material ~= from_material then break end
	end
	if to_material == from_material then
		Log.Error("Failed to get a fungal shift material")
		return
	end

	-- Convert
	local from_id = CellFactory_GetType(from_material)
	local to_id = CellFactory_GetType(to_material)
	Log.Info(CellFactory_GetUIName(from_id) .. " -> " .. CellFactory_GetUIName(to_id))
	ConvertMaterialEverywhere(from_id, to_id)

	-- Effects
	local x, y = get_spawn_position()
	GameTriggerMusicFadeOutAndDequeueAll(5.0)
	GameTriggerMusicEvent("music/oneshot/tripping_balls_01", false, x, y)

	for _ = 1,3 do
		EntityLoad("data/entities/particles/treble_eye.xml", x + Randomf(-120, 120), y + Randomf(-120, 120))
	end

	local from_material_str = GameTextGetTranslatedOrNot(CellFactory_GetUIName(from_id))
	GamePrint(GameTextGet("$logdesc_reality_mutation", from_material_str))
	AddFungalShiftIcon()
end

local archipelago_traps = {
	{
		id = "AP_POLY_SELF",
		ui_name = "$ap_trap_poly_self",
		action = function(event)
			ApplyStatusEffect(event, "POLYMORPH", 600, "data/ui_gfx/status_indicators/polymorph.png", true)
		end
	},
	{
		id = "AP_STUN",
		ui_name = "$ap_trap_stun",
		action = function(event)
			ApplyStatusEffect(event, "ELECTROCUTION", 600, "data/ui_gfx/status_indicators/electrocution.png")
		end
	},
	{
		id = "AP_CONFUSION",
		ui_name = "$ap_trap_confusion",
		action = function(event)
			ApplyStatusEffect(event, "CONFUSION", 1200, "data/ui_gfx/status_indicators/confusion.png")
		end
	},
	{
		id = "AP_ON_FIRE",
		ui_name = "$ap_trap_on_fire",
		action = function(event)
			ApplyStatusEffect(event, "ON_FIRE", 900, "data/ui_gfx/status_indicators/on_fire.png")
		end
	},
	{
		id = "AP_TELEPORT",
		ui_name = "$ap_trap_teleport",
		action = function(event)
			ApplyStatusEffect(event, "UNSTABLE_TELEPORTATION", 120, "data/ui_gfx/status_indicators/teleportation.png")
		end
	},
	{
		id = "AP_POISON",
		ui_name = "$ap_trap_poison",
		action = function(event)
			ApplyStatusEffect(event, "POISON", 1200, "data/ui_gfx/status_indicators/poisoned.png")
		end
	},
	{
		id = "AP_CHAOS_FUNGAL_SHIFT",
		ui_name = "$ap_trap_chaos_fungal_shift",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/entities/misc/effect_trip_02.xml", 300, "data/ui_gfx/status_indicators/trip.png", true)
			ChaosFungalShift()
			ChaosFungalShift()
			ChaosFungalShift()
		end
	}
}

for _, trap in ipairs(archipelago_traps) do
	trap.ui_description = trap.ui_description or trap.ui_name or trap.id
	trap.ui_author = trap.ui_author or "Archipelago"
	trap.ui_icon = trap.ui_icon or ""
	trap.weight = trap.weight or 1.0
	trap.kind = trap.kind or STREAMING_EVENT_BAD

	table.insert(streaming_events, trap)
end
