-- Script run when shop item is picked up
dofile_once("data/scripts/lib/utilities.lua")
local Globals = dofile("data/archipelago/scripts/globals.lua")
local ShopItems = dofile("data/archipelago/scripts/shopitem_utils.lua")


-- Calculates the X offset for the text of the price, used to center the text over the item
local function get_cost_x_offset(price)
	local text = tostring(price)
	local textwidth = 0

	for i=1,#text do
		local l = string.sub( text, i, i )

		if ( l ~= "1" ) then
			textwidth = textwidth + 6
		else
			textwidth = textwidth + 3
		end
	end
	return textwidth * 0.5 - 0.5
end -- get_cost_x_offset

local function get_cost_y_offset(entity_id)
	local offset = 20

	if EntityHasTag(entity_id, "card_action") then
		offset = 25
	end

	return offset
end -- get_cost_y_offset

-- Called when the entity gets created
function init(entity_id)
	if EntityGetFirstComponent(entity_id, "ItemCostComponent", "shop_cost") ~= nil then return end
	local data = ShopItems.get_ap_item_from_entity(entity_id)
	if data.price <= 0 then return end

	local x, y = EntityGetTransform(entity_id)

	-- These are typical shopitem components that would get added in Noita's vanilla shopitem file
	if data.sale then
		EntityLoad("data/entities/misc/sale_indicator.xml", x, y)
	end

	-- https://noita.wiki.gg/wiki/Documentation:_SpriteComponent
	EntityAddComponent2(entity_id, "SpriteComponent", {
		_tags="shop_cost,enabled_in_world",
		image_file="data/fonts/font_pixel_white.xml",
		is_text_sprite=true,
		offset_x=get_cost_x_offset(data.price),
		offset_y=get_cost_y_offset(entity_id),
		update_transform=true,
		update_transform_rotation=false,
		text=tostring(data.price),
		z_index=-1,
	})

	local is_stealable = false
	if BiomeMapGetName(x, y) == "$biome_holymountain" then
		is_stealable = true
	end
	-- https://noita.wiki.gg/wiki/Documentation:_ItemCostComponent
	EntityAddComponent2(entity_id, "ItemCostComponent", {
		_tags="shop_cost,enabled_in_world",
		cost=data.price,
		stealable=is_stealable
	})

	-- https://noita.wiki.gg/wiki/Documentation:_LuaComponent
	EntityAddComponent2(entity_id, "LuaComponent", {
		_tags="shop_cost",
		script_item_picked_up="data/scripts/items/shop_effect.lua"
	})

	-- We also want to disable auto-pickup on any other items
	edit_all_components2(entity_id, "ItemComponent", function(comp,vars)
		vars.auto_pickup = false
	end)
end


-- Called when the entity is picked up
function item_pickup(entity_item, entity_who_picked, name)
	-- Guard against Fair Mod bullshit and hope there isn't a layered cake of more bullshit
	if not IsPlayer(entity_who_picked) then return end

	local data = ShopItems.get_ap_item_from_entity(entity_item)

	-- Queue location for unlock
	GameAddFlagRun("ap" .. data.location_id)
	Globals.LocationUnlockQueue:append(data.location_id)

	-- Remove archipelago components
	local components = EntityGetAllComponents(entity_item)
	for _, comp in ipairs(components) do
		if ComponentHasTag(comp, "archipelago") then
			EntityRemoveComponent(entity_item, comp)
		end
	end
end
