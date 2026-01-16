dofile("data/scripts/lib/mod_settings.lua") -- see this file for documentation on some of the features.
dofile("data/scripts/lib/utilities.lua") -- for GUI_OPTION

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
	["$ap_menu_server_settings_name"] = {
		en="Server Settings"
	},
	["$ap_menu_server_settings_desc"] = {
		en="Archipelago server settings "
	},
	["$ap_menu_server_settings_address_name"] = {
		en="Server"
	},
	["$ap_menu_server_settings_address_desc"] = {
		en="Server address"
	},
	["$ap_menu_server_settings_port_name"] = {
		en="Port"
	},
	["$ap_menu_server_settings_port_desc"] = {
		en="Server Port"
	},
	["$ap_menu_server_settings_slot_name"] = {
		en="Slot"
	},
	["$ap_menu_server_settings_slot_desc"] = {
		en="Slot name"
	},
	["$ap_menu_server_settings_password_name"] = {
		en="Password"
	},
	["$ap_menu_server_settings_password_desc"] = {
		en="Password"
	},
	["$ap_menu_server_settings_debug_items_name"] = {
		en="Debug Items"
	},
	["$ap_menu_server_settings_debug_items_desc"] = {
		en="Makes debug items and perks spawn when starting a new run."
	},
	["$ap_orb_art_settings_name"] = {
		en="Orb Art"
	},
	["$ap_orb_art_settings_desc"] = {
		en="Changes the appearance of orbs spawned by the randomizer.\nDoes not affect orbs spawned by the game itself."
	},
	["$ap_death_link_settings_name"] = {
		en="Allow Death Link"
	},
	["$ap_death_link_settings_desc"] = {
		en="When set to On, the death link setting in your Archipelago YAML will be used.\nWhen set to Off, this will override your YAML and disable death link.\nWhen set to Traps, it will act as On if death link was enabled in your YAML,\nexcept it will trigger a random trap effect when a death link is received.\nBoth On and Traps will still send death links when you die."
	},
	["$ap_collect_items"] = {
		en="> Collect Items"
	},
	["$ap_collect_items_tooltip"] = {
		en="Grants you all the remaining items for your world by collecting them from all games."
	},
	["$ap_release_items"] = {
		en="> Release Items"
	},
	["$ap_release_items_tooltip"] = {
		en="Releases all items contained in your world to other worlds."
	},
	["$ap_menu_game_settings_name"] = {
		en="Game Settings"
	},
	["$ap_menu_game_settings_desc"] = {
		en="Game-specific settings for the Archipelago mod."
	},
	["$ap_log_limit_settings_name"] = {
		en="Log Limit"
	},
	["$ap_log_limit_settings_desc"] = {
		en="Maximum number of log lines to store and render in the log window."
	},
}

local function translate(msg)
	local translation_table = translations[msg] or {}
	local lang_id = GameTextGet("$")
	return translation_table[lang_id] or translation_table["en"] or msg
end

-- Global override to create clear field buttons (pretty much just a hack)
if OldGuiTextInput == nil then -- required for noita_dev.exe to work
	OldGuiTextInput = GuiTextInput
end
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

local mod_id = "archipelago" -- This should match the name of your mod's folder.
mod_settings_version = 1 -- This is a magic global that can be used to migrate settings to new mod versions. call mod_settings_get_version() before mod_settings_update() to get the old value.
local mod_settings =
{
	{
		image_filename = "mods/archipelago/data/archipelago/logo.png",
		ui_fn = mod_setting_image,
	},
	{
		category_id = "ap_server_settings",
		ui_name = translate("$ap_menu_server_settings_name"),
		ui_description = translate("$ap_menu_server_settings_desc"),
		settings = {
			{
				id = "server_address",
				ui_name = translate("$ap_menu_server_settings_address_name"),
				ui_description = translate("$ap_menu_server_settings_address_desc"),
				value_default = "archipelago.gg",
				text_max_length = 120,
				allowed_characters = "%-.0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz~",
				scope = MOD_SETTING_SCOPE_NEW_GAME,
			},
			{
				id = "server_port",
				ui_name = translate("$ap_menu_server_settings_port_name"),
				ui_description = translate("$ap_menu_server_settings_port_desc"),
				value_default = "",
				text_max_length = 5,
				allowed_characters = "0123456789",
				scope = MOD_SETTING_SCOPE_NEW_GAME,
			},
			{
				id = "slot_name",
				ui_name = translate("$ap_menu_server_settings_slot_name"),
				ui_description = translate("$ap_menu_server_settings_slot_desc"),
				value_default = "",
				text_max_length = 120,
				allowed_characters = " !#$%&'()+,-.0123456789;=@ABCDEFGHIJKLMNOPQRSTUVWXYZ[]^_`abcdefghijklmnopqrstuvwxyz{}~",
				scope = MOD_SETTING_SCOPE_NEW_GAME,
			},
			{
				id = "passwd",
				ui_name = translate("$ap_menu_server_settings_password_name"),
				ui_description = translate("$ap_menu_server_settings_password_desc"),
				value_default = "",
				text_max_length = 120,
				scope = MOD_SETTING_SCOPE_NEW_GAME,
			},
			{
				id = "death_link",
				ui_name = translate("$ap_death_link_settings_name"),
				ui_description = translate("$ap_death_link_settings_desc"),
				value_default = "on",
				values = {
					{"off", "Off"},
					{"on", "On"},
					{"traps", "Traps"}
				},
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
		},
	},
	{
		category_id = "ap_game_settings",
		ui_name = translate("$ap_menu_game_settings_name"),
		ui_description = translate("$ap_menu_game_settings_desc"),
		settings = {
			{
				id = "orb_art",
				ui_name = translate("$ap_orb_art_settings_name"),
				ui_description = translate("$ap_orb_art_settings_desc"),
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
				ui_name = translate("$ap_log_limit_settings_name"),
				ui_description = translate("$ap_log_limit_settings_desc"),
				value_default = 1000,
				value_min = 100,
				value_max = 5000,
				scope = MOD_SETTING_SCOPE_RUNTIME_RESTART,

			},
			{
				id = "debug_items",
				ui_name = translate("$ap_menu_server_settings_debug_items_name"),
				ui_description = translate("$ap_menu_server_settings_debug_items_desc"),
				value_default = false,
				scope = MOD_SETTING_SCOPE_NEW_GAME,
				hidden = true,
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
	return mod_settings_gui_count( mod_id, mod_settings ) + 2 -- Add our 2 buttons
end

local function APOptionButton(gui, name, disabled)
	GuiIdPushString(gui, name)

	if disabled then
		GuiOptionsAddForNextWidget(gui, GUI_OPTION.Disabled)
	end

	local result = GuiButton(gui, 1, 0, 0, translate(name))
	GuiTooltip(gui, translate(name .. "_tooltip"), "")

	GuiIdPop(gui)
	return result and not disabled
end

-- This function is called to display the settings UI for this mod. Your mod's settings wont be visible in the mod settings menu if this function isn't defined correctly.
function ModSettingsGui( gui, in_main_menu )
	mod_settings_gui( mod_id, mod_settings, gui, in_main_menu )

	if APOptionButton(gui, "$ap_collect_items", in_main_menu) then
		GameAddFlagRun("ap_collect_items_used")
	end

	if APOptionButton(gui, "$ap_release_items", in_main_menu) then
		GameAddFlagRun("ap_release_items_used")
	end
end
