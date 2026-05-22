
local ap_status_list = {
	{
		id = "AP_144P",
		ui_name = "$ap_trap_144p",
		ui_icon = "data/archipelago/ui_gfx/status_effects/144p.png",
		effect_entity = "data/archipelago/entities/misc/effect_144p.xml",
		is_harmful = true,
	},
	{
		id = "AP_FLIP_VER",
		ui_name = "$ap_trap_flip_vertical",
		ui_icon = "data/archipelago/ui_gfx/status_effects/flip_vertical.png",
		effect_entity = "data/archipelago/entities/misc/effect_flip_ver.xml",
		is_harmful = true,
	},
	{
		id = "AP_FLIP_HOR",
		ui_name = "$ap_trap_flip_horizontal",
		ui_icon = "data/archipelago/ui_gfx/status_effects/flip_horizontal.png",
		effect_entity = "data/archipelago/entities/misc/effect_flip_hor.xml",
		is_harmful = true,
	},
	{
		id = "AP_ZOOM_IN",
		ui_name = "$ap_trap_zoom_in",
		ui_icon = "data/archipelago/ui_gfx/status_effects/zoom_in.png",
		effect_entity = "data/archipelago/entities/misc/effect_zoom_in.xml",
		is_harmful = true,
	},
	{
		id = "AP_ZOOM_OUT",
		ui_name = "$ap_trap_zoom_out",
		ui_icon = "data/archipelago/ui_gfx/status_effects/zoom_out.png",
		effect_entity = "data/archipelago/entities/misc/effect_zoom_out.xml",
		is_harmful = true,
	},
	{
		id = "AP_FISH_EYE",
		ui_name = "$ap_trap_fisheye",
		ui_icon = "data/archipelago/ui_gfx/status_effects/fisheye.png",
		effect_entity = "data/archipelago/entities/misc/effect_fisheye.xml",
		is_harmful = true,
	},
	{
		id = "AP_INVERT_COLOUR",
		ui_name = "$ap_trap_invert_colour",
		effect_entity = "data/archipelago/entities/misc/effect_invert_colours.xml",
		is_harmful = true,
	},
	{
		id = "AP_INVIS_BAD",
		ui_name = "$ap_trap_invisible_bad",
		ui_icon = "data/ui_gfx/status_indicators/invisibility.png",
		effect_entity = "data/archipelago/entities/misc/effect_invisible_bad.xml",
		is_harmful = true,
	},
	{
		id = "AP_MANA_DRAIN",
		ui_name = "$ap_trap_mana_drain",
		ui_icon = "data/archipelago/ui_gfx/status_effects/mana_degradation.png",
		effect_entity = "data/archipelago/entities/misc/effect_mana_drain.xml",
		is_harmful = true,
	},
	{
		id = "AP_POLY_FROG",
		ui_name = "$ap_trap_poly_frog",
		ui_icon = "data/ui_gfx/status_indicators/polymorph_random.png",
		effect_entity = "data/archipelago/entities/misc/effect_poly_frog.xml",
		remove_cells_that_cause_when_activated = true,
		is_harmful = true,
	},
	{
		id = "AP_EXTREME_CHAOS",
		ui_name = "$ap_trap_extreme_chaos",
		ui_icon = "data/ui_gfx/status_indicators/trip.png",
		effect_entity = "data/archipelago/entities/misc/effect_extreme_chaos.xml",
		is_harmful = true,
	},
	{
		id = "AP_DOUBLE_DAMAGE",
		ui_name = "$ap_trap_double_damage",
		ui_icon = "data/ui_gfx/status_indicators/wither.png",
		effect_entity = "data/archipelago/entities/misc/effect_double_damage.xml",
		is_harmful = true,
	},
	{
		id = "AP_DRYSPELL",
		ui_name = "$ap_trap_dryspell",
		ui_description = "$ap_trap_dryspell_desc",
		ui_icon = "data/archipelago/ui_gfx/status_effects/dryspell2.png",
		effect_entity = "data/archipelago/entities/misc/effect_double_damage.xml",
		is_harmful = true,
	},
	{
		id = "AP_CAMERA_ROTATE",
		ui_name = "$ap_trap_camera_rotate",
		effect_entity = "data/archipelago/entities/misc/effect_camera_rotate.xml",
		is_harmful = true,
	},
	{
		id = "AP_SHEEP_SFX",
		ui_name = "$ap_trap_sheep_sfx",
		ui_icon = "data/ui_gfx/status_indicators/polymorph.png",
		effect_entity = "data/archipelago/entities/misc/effect_sheep_sfx.xml",
		is_harmful = true,
	},
	{
		id = "AP_BECOME_SPEED",
		ui_name = "$ap_trap_become_speed",
		ui_description = "$ap_trap_become_speed_desc",
		ui_icon = "data/archipelago/ui_gfx/status_effects/become_speed.png",
		effect_entity = "data/archipelago/entities/misc/effect_speed.xml",
		is_harmful = true,
	},
	{
		id = "AP_STICK_DRIFT",
		ui_name = "$ap_trap_stick_drift",
		effect_entity = "data/archipelago/entities/misc/effect_stick_drift.xml",
		is_harmful = true,
	},
	{
		id = "AP_JUMP_TRAP",
		ui_name = "$ap_trap_jump",
		effect_entity = "data/archipelago/entities/misc/effect_jumping.xml",
		is_harmful = true,
	},
	{
		id = "AP_UNDERWATER",
		ui_name = "$ap_trap_underwater",
		effect_entity = "data/archipelago/entities/misc/effect_underwater.xml",
		is_harmful = true,
	},
	{
		id = "AP_LAG",
		ui_name = "$ap_trap_lag",
		ui_icon = "data/archipelago/ui_gfx/status_effects/lag_player.png",
		effect_entity = "data/archipelago/entities/misc/effect_lag.xml",
		is_harmful = true,
	},
	{
		id = "AP_MONKEY_MASH",
		ui_name = "$ap_trap_monkey_mash",
		effect_entity = "data/archipelago/entities/misc/effect_monkey_mash.xml",
		is_harmful = true,
	},
	{
		id = "AP_WIDE",
		ui_name = "$ap_trap_wide",
		effect_entity = "data/archipelago/entities/misc/effect_wide.xml",
		is_harmful = true,
	},
	{
		id = "AP_TINY",
		ui_name = "$ap_trap_tiny",
		effect_entity = "data/archipelago/entities/misc/effect_tiny.xml",
		is_harmful = true,
	},
	{
		id = "AP_MONOCHROME",
		ui_name = "$ap_trap_spooky",
		effect_entity = "data/archipelago/entities/misc/effect_monochrome.xml",
		is_harmful = true,
	},
	{
		id = "AP_FRACTURE",
		ui_name = "$ap_trap_fracture",
		effect_entity = "data/archipelago/entities/misc/effect_fracture.xml",
		is_harmful = true,
	},
	{
		id = "AP_SPELLS_TO_BOMBS",
		ui_name = "$ap_trap_spells_to_bombs",
		ui_description = "$ap_trap_spells_to_bombs_desc",
		effect_entity = "data/archipelago/entities/misc/effect_bombs.xml",
		is_harmful = true,
	},
	{
		id = "AP_SWAPPER_CURSE",
		ui_name = "$ap_trap_swapper_curse",
		ui_icon = "data/archipelago/ui_gfx/status_effects/plagiarize_swapper.png",
		effect_entity = "data/archipelago/entities/misc/effect_swapper_curse.xml",
		is_harmful = true,
	},
}

for _, status in ipairs(ap_status_list) do
	status.ui_description = status.ui_description or status.ui_name
	status.ui_icon = status.ui_icon or "data/archipelago/ui_gfx/status_effects/ap.png"
	status.effect_entity = status.effect_entity or ""

	table.insert(status_effects, status)
end
