-- This file gets called every n frames
dofile_once("data/scripts/lib/utilities.lua")
local JSON = dofile("data/archipelago/lib/json.lua")
local ShopItems = dofile("data/archipelago/scripts/shopitem_utils.lua")

local function decodeXML(str)
	return str:gsub("&quot;", "\"")
end

if GameHasFlagRun("AP_LocationInfo_received") then
	local entity_id = GetUpdatedEntityID()

	local component = get_variable_storage_component(entity_id, "ap_shop_data")
	local data_str = ComponentGetValue2(component, "value_string")
	local data = JSON:decode(decodeXML(data_str))

	local x, y = EntityGetTransform(GetUpdatedEntityID())
	ShopItems.generate_ap_shop_item_entity(data.location_id, x, y)

	EntityAddComponent2(entity_id, "VariableStorageComponent", {
		_tags="archipelago,enabled_in_world",
		name="ap_shop_data",
		value_string=data_str
	})

	EntityAddComponent2(entity_id, "LuaComponent", {
		_tags="archipelago",
		script_source_file="data/archipelago/scripts/shopitem_processed.lua",
		execute_on_added="1",
		execute_every_n_frame="-1",
		call_init_function="1",
		script_item_picked_up="data/archipelago/scripts/shopitem_processed.lua",
	})
	EntityKill(entity_id)
end
