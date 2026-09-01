dofile("data/scripts/lib/mod_settings.lua") -- see this file for documentation on some of the features.
dofile("data/scripts/lib/utilities.lua") -- for GUI_OPTION


local MOD_VERSION = "1.6.0"
local mod_id = "archipelago" -- This should match the name of your mod's folder.
mod_settings_version = 1 -- This is a magic global that can be used to migrate settings to new mod versions. call mod_settings_get_version() before mod_settings_update() to get the old value.

-- This file can't access other files from this or other mods in all circumstances.
-- Settings will be automatically saved.
-- Settings don't have access unsafe lua APIs.

-- Use ModSettingGet() in the game to query settings.
-- For some settings (for example those that affect world generation) you might want to retain the current value until a certain point, even
-- if the player has changed the setting while playing.
-- To make it easy to define settings like that, each setting has a "scope" (e.g. MOD_SETTING_SCOPE_NEW_GAME) that will define when the changes
-- will actually become visible via ModSettingGet(). In the case of MOD_SETTING_SCOPE_NEW_GAME the value at the start of the run will be visible
-- until the player starts a new game.
-- ModSettingSetNextValue() will set the buffered value, that will later become visible via ModSettingGet(), unless the setting scope is MOD_SETTING_SCOPE_RUNTIME.

local translations = {
	["$ap_menu_server_settings_name"] = { en="Server" },
	["$ap_menu_server_settings_desc"] = { en="Archipelago server settings" },
	["$ap_menu_integration_settings_name"] = { en="Integrations" },
	["$ap_menu_integration_settings_desc"] = { en="Archipelago integration settings.\nCan be changed when connected to a room, the settings will be specific to that room." },
	["$ap_menu_server_settings_address_name"] = { en="Server" },
	["$ap_menu_server_settings_address_desc"] = { en="Server address" },
	["$ap_menu_server_settings_port_name"] = { en="Port" },
	["$ap_menu_server_settings_port_desc"] = { en="Server Port" },
	["$ap_menu_server_settings_slot_name"] = { en="Slot" },
	["$ap_menu_server_settings_slot_desc"] = { en="Slot name" },
	["$ap_menu_server_settings_password_name"] = { en="Password" },
	["$ap_menu_server_settings_password_desc"] = { en="Password" },
	["$ap_menu_server_settings_debug_items_name"] = { en="Debug Items" },
	["$ap_menu_server_settings_debug_items_desc"] = { en="Makes debug items and perks spawn when starting a new run." },
	["$ap_orb_art_settings_name"] = { en="Orb Art" },
	["$ap_orb_art_settings_desc"] = { en="Changes the appearance of orbs spawned by the randomizer.\nDoes not affect orbs spawned by the game itself." },
	["$ap_death_link_settings_name"] = { en="Allow Death Link" },
	["$ap_death_link_settings_desc"] = { en="Off = Death Link is always off.\nOn = Death Link is always on.\nTraps = When receiving a Death Link, trigger a random\ntrap instead. Death Links are still sent." },
	["$ap_trap_link_settings_name"] = { en="Trap Link" },
	["$ap_trap_link_settings_desc"] = { en="When any client with Trap Link on receives a trap,\nall clients with Trap Link receive the same trap." },
	["$ap_damage_link_settings_name"] = { en="Damage Link" },
	["$ap_damage_link_settings_desc"] = { en="When any client with Damage Link receives damage,\nall clients with Damage Link receive damage." },
	["$ap_knockback_link_settings_name"] = { en="Knockback Link" },
	["$ap_knockback_link_settings_desc"] = { en="When any client with Knockback Link receives knockback,\nall clients with Knockback Link receive knockback." },
	["$ap_menu_game_settings_name"] = { en="Game" },
	["$ap_menu_game_settings_desc"] = { en="Game-specific settings for the Archipelago mod." },
	["$ap_menu_killsanity_settings_name"] = { en="Killsanity" },
	["$ap_menu_killsanity_settings_desc"] = { en="Game-specific settings for Killsanity credit." },
	["$ap_log_limit_settings_name"] = { en="Log Limit" },
	["$ap_log_limit_settings_desc"] = { en="Maximum number of log lines to store and render in the log window." },
	["$ap_menu_commands_name"] = { en="Commands" },
	["$ap_menu_commands_desc"] = { en="Commands that can be used for the current Archipelago session." },
	["$ap_messages_settings_name"] = { en = "Text Messages" },
	["$ap_messages_settings_desc"] = { en = "Determine which text messages are shown.\n  All = Show all messages\n  Self = Show only messages pertaining to yourself\n  None = Never receive messages" },
	["$ap_join_messages_settings_name"] = { en = "Join/Leave Messages" },
	["$ap_join_messages_settings_desc"] = { en = "Determine whether to show join/leave messages (hidden if Text Messages is set to None)" },
	["$ap_killcredit_settings_name"] = { en = "Kill Credit" },
	["$ap_killcredit_settings_desc"] = { en = "Determines how kill credit is granted.\nRules based is tailored for best experience." },
	["$ap_kills_in_fog_settings_name"] = { en = "Obscured Deaths" },
	["$ap_kills_in_fog_settings_desc"] = { en = "Unexplainable deaths in fogged areas count as kills." },
	["$ap_option_traps"] = { en = "Traps" },
	["$ap_option_yaml"] = { en = "YAML (Room Settings)" },
}

local lang_id = "en"

---@param msg string
---@return string
local function T(msg)
	local translation_table = translations[msg] or {}
	return translation_table[lang_id] or translation_table["en"] or GameTextGetTranslatedOrNot(msg)
end

-- Global override to create clear field buttons (pretty much just a hack)
local OldGuiTextInput = GuiTextInput
GuiTextInput = function(gui, id, x, y, text, width, max_length, allowed_characters)
	GuiOptionsAdd(gui, GUI_OPTION.Layout_InsertOutsideRight)
	GuiColorSetForNextWidget(gui, 0.5, 0.5, 0.5, 0.5)
	local cleared = GuiButton(gui, id + 69420, x + 100, y, "X")
	GuiOptionsRemove(gui, GUI_OPTION.Layout_InsertOutsideRight)

	local value = OldGuiTextInput(gui, id, x, y, text, width, max_length, allowed_characters)
	if cleared then
		return ""
	end
	return value
end

---@param opt_value string
---@param opt_list table[]
---@return integer
local function GetOptionIndex(opt_value, opt_list)
	for i, opt in ipairs(opt_list) do
		if opt[1] == opt_value then
			return i
		end
	end
	return 1
end

---@param opt_global_id string
---@param default string
---@return string
local function GetSharedValue(opt_global_id, default)
	local result = GlobalsGetValue("AP_OPT_" .. opt_global_id)
	if result == nil or result == "" then
		return default
	end
	return tostring(result)
end

---@param opt_global_id string
---@param value string
local function SetSharedValue(opt_global_id, value)
	GlobalsSetValue("AP_OPT_" .. opt_global_id, value)
	GameAddFlagRun("AP_CHANGED_OPT_" .. opt_global_id)
end

---@param gui gui
---@param disabled boolean
---@param opt_global_id string
---@param opt_name string
---@param opt_list table[]
local function APRoomOption(gui, disabled, opt_global_id, opt_name, opt_desc, opt_list)
	GuiIdPushString(gui, opt_global_id)

	local opt_id = 1	-- default (YAML)
	if disabled then
		GuiOptionsAddForNextWidget(gui, GUI_OPTION.Disabled)
	else
		opt_id = GetOptionIndex(GetSharedValue(opt_global_id, "yaml"), opt_list)
	end

	local clicked, rclick = GuiButton(gui, 1, 0, 0, opt_name .. ": " .. opt_list[opt_id][2])
	GuiTooltip(gui, opt_desc, "")

	if not disabled then
		if rclick then
			opt_id = 1
		elseif clicked then
			opt_id = opt_id + 1
			if opt_id > #opt_list then
				opt_id = 1
			end
		end
		SetSharedValue(opt_global_id, opt_list[opt_id][1])
	end

	GuiIdPop(gui)
end

local DeathLinkOpts = {
	{ "yaml", T("$ap_option_yaml") },
	{ "off", T("$option_off") },
	{ "on", T("$option_on") },
	{ "traps", T("$ap_option_traps") },
}
local function APDeathLinkOption(mod_id, gui, in_main_menu, im_id, setting)
	APRoomOption(gui, in_main_menu, "DEATH_LINK", T("$ap_death_link_settings_name"), T("$ap_death_link_settings_desc"), DeathLinkOpts)
end

local TrapLinkOpts = {
	{ "yaml", T("$ap_option_yaml") },
	{ "off", T("$option_off") },
	{ "on", T("$option_on") },
}
local function APTrapLinkOption(mod_id, gui, in_main_menu, im_id, setting)
	APRoomOption(gui, in_main_menu, "TRAP_LINK", T("$ap_trap_link_settings_name"), T("$ap_trap_link_settings_desc"), TrapLinkOpts)
end

local DamageLinkOpts = {
	{ "yaml", T("$ap_option_yaml") },
	{ "off", T("$option_off") },
	{ "on", T("$option_on") },
}
local function APDamageLinkOption(mod_id, gui, in_main_menu, im_id, setting)
	APRoomOption(gui, in_main_menu, "DAMAGE_LINK", T("$ap_damage_link_settings_name"), T("$ap_damage_link_settings_desc"), DamageLinkOpts)
end

local KnockbackLinkOpts = {
	{ "yaml", T("$ap_option_yaml") },
	{ "off", T("$option_off") },
	{ "on", T("$option_on") },
}
local function APKnockbackLinkOption(mod_id, gui, in_main_menu, im_id, setting)
	APRoomOption(gui, in_main_menu, "KNOCKBACK_LINK", T("$ap_knockback_link_settings_name"), T("$ap_knockback_link_settings_desc"), KnockbackLinkOpts)
end

local mod_settings =
{
	{
		image_filename = "mods/archipelago/data/archipelago/logo.png",
		ui_fn = mod_setting_image,
	},
	{
		ui_name = "Version " .. MOD_VERSION,
		ui_fn = mod_setting_title,
	},
	{
		category_id = "ap_server_settings",
		ui_name = T("$ap_menu_server_settings_name"),
		ui_description = T("$ap_menu_server_settings_desc"),
		settings = {
			{
				id = "server_address",
				ui_name = T("$ap_menu_server_settings_address_name"),
				ui_description = T("$ap_menu_server_settings_address_desc"),
				value_default = "archipelago.gg",
				text_max_length = 120,
				allowed_characters = "%-.0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz~",
				scope = MOD_SETTING_SCOPE_RUNTIME_RESTART,
			},
			{
				id = "server_port",
				ui_name = T("$ap_menu_server_settings_port_name"),
				ui_description = T("$ap_menu_server_settings_port_desc"),
				value_default = "",
				text_max_length = 5,
				allowed_characters = "0123456789",
				scope = MOD_SETTING_SCOPE_RUNTIME_RESTART,
			},
			{
				id = "slot_name",
				ui_name = T("$ap_menu_server_settings_slot_name"),
				ui_description = T("$ap_menu_server_settings_slot_desc"),
				value_default = "",
				text_max_length = 120,
				scope = MOD_SETTING_SCOPE_NEW_GAME,
			},
			{
				id = "passwd",
				ui_name = T("$ap_menu_server_settings_password_name"),
				ui_description = T("$ap_menu_server_settings_password_desc"),
				value_default = "",
				text_max_length = 120,
				scope = MOD_SETTING_SCOPE_NEW_GAME,
			},
			{
				id = "messages",
				ui_name = T("$ap_messages_settings_name"),
				ui_description = T("$ap_messages_settings_desc"),
				value_default = "self",
				values = {
					{"all", "All"},
					{"self", "Self"},
					{"none", "None"}
				},
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				id = "join_leave_messages",
				ui_name = T("$ap_join_messages_settings_name"),
				ui_description = T("$ap_join_messages_settings_desc"),
				value_default = true,
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
		},
	},
	{
		category_id = "ap_integration_settings",
		ui_name = T("$ap_menu_integration_settings_name"),
		ui_description = T("$ap_menu_integration_settings_desc"),
		settings = {
			{
				ui_fn = APDeathLinkOption,
			},
			{
				ui_fn = APTrapLinkOption,
			},
			{
				ui_fn = APDamageLinkOption,
			},
			{
				ui_fn = APKnockbackLinkOption,
			},
		},
	},
	{
		category_id = "ap_game_settings",
		ui_name = T("$ap_menu_game_settings_name"),
		ui_description = T("$ap_menu_game_settings_desc"),
		settings = {
			{
				id = "orb_art",
				ui_name = T("$ap_orb_art_settings_name"),
				ui_description = T("$ap_orb_art_settings_desc"),
				value_default = "ap_logo",
				values = {
					{"vanilla", "Vanilla"},
					{"ap_logo", "AP Logo"},
					{"spinny_logo", "Spinny Logo"},
					{"porb", "Porb"},
					{"glorb", "Glorb"}
				},
				scope = MOD_SETTING_SCOPE_NEW_GAME,
			},
			{
				id = "log_limit",
				ui_name = T("$ap_log_limit_settings_name"),
				ui_description = T("$ap_log_limit_settings_desc"),
				value_default = 1000,
				value_min = 100,
				value_max = 5000,
				scope = MOD_SETTING_SCOPE_RUNTIME_RESTART,
			},
			{
				id = "debug_items",
				ui_name = T("$ap_menu_server_settings_debug_items_name"),
				ui_description = T("$ap_menu_server_settings_debug_items_desc"),
				value_default = false,
				scope = MOD_SETTING_SCOPE_NEW_GAME,
				hidden = true,
			},
		},
	},
	{
		category_id = "ap_killsanity_settings",
		ui_name = T("$ap_menu_killsanity_settings_name"),
		ui_description = T("$ap_menu_killsanity_settings_desc"),
		settings = {
			{
				id = "kill_credit",
				ui_name = T("$ap_killcredit_settings_name"),
				ui_description = T("$ap_killcredit_settings_desc"),
				value_default = "rules",
				values = {
					{"restricted", "Restricted (direct kills only)"},
					{"rules", "Rules Based (more forgiving)"},
					{"everything", "Always"},
				},
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				id = "kills_in_fog",
				ui_name = T("$ap_kills_in_fog_settings_name"),
				ui_description = T("$ap_kills_in_fog_settings_desc"),
				value_default = "no",
				values = {
					{"no", "Excluded"},
					{"yes", "Included"},
				},
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
		},
	},
}

-- This function is called to ensure the correct setting values are visible to the game via ModSettingGet(). your mod's settings don't work if you don't have a function like this defined in settings.lua.
-- This function is called:
--		- when entering the mod settings menu (init_scope will be MOD_SETTINGS_SCOPE_ONLY_SET_DEFAULT)
-- 		- before mod initialization when starting a new game (init_scope will be MOD_SETTING_SCOPE_NEW_GAME)
--		- when entering the game after a restart (init_scope will be MOD_SETTING_SCOPE_RESTART)
--		- at the end of an update when mod settings have been changed via ModSettingsSetNextValue() and the game is unpaused (init_scope will be MOD_SETTINGS_SCOPE_RUNTIME)
function ModSettingsUpdate( init_scope )
	-- Hack which gets the lang id but warns in noita_dev
	lang_id = GameTextGet("$")
	local old_version = mod_settings_get_version( mod_id ) -- This can be used to migrate some settings between mod versions.
	mod_settings_update( mod_id, mod_settings, init_scope )
end

-- This function should return the number of visible setting UI elements.
-- Your mod's settings wont be visible in the mod settings menu if this function isn't defined correctly.
-- If your mod changes the displayed settings dynamically, you might need to implement custom logic.
-- The value will be used to determine whether or not to display various UI elements that link to mod settings.
-- At the moment it is fine to simply return 0 or 1 in a custom implementation, but we don't guarantee that will be the case in the future.
-- This function is called every frame when in the settings menu.
function ModSettingsGuiCount()
	return mod_settings_gui_count( mod_id, mod_settings )
end

-- This function is called to display the settings UI for this mod. Your mod's settings wont be visible in the mod settings menu if this function isn't defined correctly.
function ModSettingsGui( gui, in_main_menu )
	mod_settings_gui( mod_id, mod_settings, gui, in_main_menu )
end
