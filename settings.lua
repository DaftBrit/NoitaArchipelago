dofile("data/scripts/lib/mod_settings.lua") -- see this file for documentation on some of the features.

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
	["$ap_menu_server_settings_auto_release_name"] = {
		en="Auto-Release"
	},
	["$ap_menu_server_settings_auto_release_desc"] = {
		en="Automatically releases your remaining checks from your game when you complete your goal."
	},
	["$ap_menu_server_settings_auto_collect_name"] = {
		en="Auto-Collect"
	},
	["$ap_menu_server_settings_auto_collect_desc"] = {
		en="Automatically collects your remaining items from other games when you complete your goal."
	},
	["$ap_menu_server_settings_debug_items_name"] = {
		en="Debug Items"
	},
	["$ap_menu_server_settings_debug_items_desc"] = {
		en="Makes debug items and perks spawn when starting a new run."
	},
}

local function translate(msg)
	local translation_table = translations[msg] or {}
	local lang_id = GameTextGet("$")
	return translation_table[lang_id] or translation_table["en"] or msg
end

local mod_id = "archipelago" -- This should match the name of your mod's folder.
mod_settings_version = 1 -- This is a magic global that can be used to migrate settings to new mod versions. call mod_settings_get_version() before mod_settings_update() to get the old value. 
mod_settings = 
{
	{
		image_filename = "data/archipelago/logo.png",
		ui_fn = mod_setting_image,
	},
	{
		category_id = "group_of_settings",
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
				id = "auto_release",
				ui_name = translate("$ap_menu_server_settings_auto_release_name"),
				ui_description = translate("$ap_menu_server_settings_auto_release_desc"),
				value_default = false,
				scope = MOD_SETTING_SCOPE_NEW_GAME,
			},
			{
				id = "auto_collect",
				ui_name = translate("$ap_menu_server_settings_auto_collect_name"),
				ui_description = translate("$ap_menu_server_settings_auto_collect_desc"),
				value_default = false,
				scope = MOD_SETTING_SCOPE_NEW_GAME,
			},
			{
				id = "debug_items",
				ui_name = translate("$ap_menu_server_settings_debug_items_name"),
				ui_description = translate("$ap_menu_server_settings_debug_items_desc"),
				value_default = false,
				scope = MOD_SETTING_SCOPE_NEW_GAME,
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
	return mod_settings_gui_count( mod_id, mod_settings )
end

-- This function is called to display the settings UI for this mod. Your mod's settings wont be visible in the mod settings menu if this function isn't defined correctly.
function ModSettingsGui( gui, in_main_menu )
	mod_settings_gui( mod_id, mod_settings, gui, in_main_menu )
end
