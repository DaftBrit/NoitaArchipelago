
local ap_status_list = {
	{
		id="AP_144P",
		ui_name="$ap_trap_144p",
		effect_entity="data/archipelago/entities/misc/effect_144p.xml",
		is_harmful=true,
	},
	{
		id="AP_FLIP_VER",
		ui_name="$ap_trap_flip_vertical",
		effect_entity="data/archipelago/entities/misc/effect_flip_ver.xml",
		is_harmful=true,
	},
	{
		id="AP_FLIP_HOR",
		ui_name="$ap_trap_flip_horizontal",
		effect_entity="data/archipelago/entities/misc/effect_flip_hor.xml",
		is_harmful=true,
	},
	{
		id="AP_ZOOM_IN",
		ui_name="$ap_trap_zoom_in",
		effect_entity="data/archipelago/entities/misc/effect_zoom_in.xml",
		is_harmful=true,
	},
	{
		id="AP_ZOOM_OUT",
		ui_name="$ap_trap_zoom_out",
		effect_entity="data/archipelago/entities/misc/effect_zoom_out.xml",
		is_harmful=true,
	},
	{
		id="AP_FISH_EYE",
		ui_name="$ap_trap_fisheye",
		effect_entity="data/archipelago/entities/misc/effect_fisheye.xml",
		is_harmful=true,
	},
	{
		id="AP_INVERT_COLOUR",
		ui_name="$ap_trap_invert_colour",
		effect_entity="data/archipelago/entities/misc/effect_invert_colours.xml",
		is_harmful=true,
	},
	{
		id="AP_INVIS_BAD",
		ui_name="$ap_trap_invisible_bad",
		ui_icon="data/ui_gfx/status_indicators/invisibility.png",
		effect_entity="data/archipelago/entities/misc/effect_invisible_bad.xml",
		is_harmful=true,
	},
	{
		id="AP_MANA_DRAIN",
		ui_name="$ap_trap_mana_drain",
		ui_icon="data/ui_gfx/status_indicators/mana_regeneration.png",
		effect_entity="data/archipelago/entities/misc/effect_mana_drain.xml",
		is_harmful=true,
	},
	{
		id="AP_POLY_FROG",
		ui_name="$ap_trap_poly_frog",
		ui_icon="data/ui_gfx/status_indicators/polymorph_random.png",
		effect_entity="data/archipelago/entities/misc/effect_poly_frog.xml",
		remove_cells_that_cause_when_activated=true,
		is_harmful=true,
	},
	{
		id="AP_EXTREME_CHAOS",
		ui_name="$ap_trap_extreme_chaos",
		ui_icon="data/ui_gfx/status_indicators/trip.png",
		effect_entity="data/archipelago/entities/misc/effect_extreme_chaos.xml",
		is_harmful=true,
	},
}

for _, status in ipairs(ap_status_list) do
	status.ui_description = status.ui_description or status.ui_name
	status.ui_icon = status.ui_icon or "data/ui_gfx/status_indicators/confusion.png"
	status.effect_entity = status.effect_entity or ""

	table.insert(status_effects, status)
end
