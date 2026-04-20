dofile_once("data/scripts/streaming_integration/event_utilities.lua")
--dofile_once("data/archipelago/scripts/ap_utils.lua")
-- streaming_integration/event_list.lua

---@param event table
---@param game_effect string
---@param frames integer
---@param icon string
local function ApplyStatusEffect(event, game_effect, frames, icon)
	local player = get_player()
	if player == nil then return end

	local effect_comp, effect_entity = GetGameEffectLoadTo(player, game_effect, false)
	if effect_comp ~= nil and effect_entity ~= nil then
		ComponentSetValue2(effect_comp, "frames", frames)
		add_icon_above_head(effect_entity, "data/ui_gfx/status_indicators/polymorph.png", event)
	end
end

local archipelago_traps = {
	{
		id = "AP_POLY_SELF",
		ui_name = "$ap_trap_poly_self",
		action = function(event)
			ApplyStatusEffect(event, "POLYMORPH", 600, "data/ui_gfx/status_indicators/polymorph.png")
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
			ApplyStatusEffect(event, "ON_FIRE", 1200, "data/ui_gfx/status_indicators/on_fire.png")
		end
	},
}

for _, trap in ipairs(archipelago_traps) do
	trap.ui_description = trap.ui_description or trap.ui_name or trap.id
	trap.ui_author = trap.ui_author or "Archipelago"
	trap.ui_icon = trap.ui_icon or ""
	trap.weight = trap.weight or 1.0
	trap.kind = trap.kind or STREAMING_EVENT_BAD

	table.insert(streaming_events, trap)
end
