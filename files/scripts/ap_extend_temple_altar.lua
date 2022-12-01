
local ap_remaining_ap_items = 0
local ap_remaining_items = 0
local ap_num_ap_items = 0

local function ap_get_shop_num(y)
  if y < 1500 then return 1 -- Mines
  elseif y < 3000 then return 2 -- Coal Pits
  elseif y < 5500 then return 3 -- Snowy Depths
  elseif y < 7000 then return 4 -- Hiisi Base
  elseif y < 9500 then return 5 -- Underground Jungle
  elseif y < 11500 then return 6 -- The Vault
  else return 7 -- Temple of the Art
  end
end

local function ap_get_item_id_str(y)
  return tostring(111000 + (ap_get_shop_num(y)-1) * 5 + ap_num_ap_items)
end

local function ap_get_item_name(y)
  return GlobalsGetValue("AP_SHOPITEM_NAME_" .. ap_get_item_id_str(y))
end

local function ap_get_item_flags(y)
  return tonumber(GlobalsGetValue("AP_SHOPITEM_FLAGS_" .. ap_get_item_id_str(y), "0"))
end

local function ap_get_item_override(y)
  return GlobalsGetValue("AP_SHOPITEM_OVERRIDE_" .. ap_get_item_id_str(y))
end

-- Uses vanilla wand price calculation
local function ap_generate_item_price(biomeid, cheap_item)
  print("BIOME ID IS " .. biomeid)
  biomeid = (0.5 * biomeid) + ( 0.5 * biomeid * biomeid )
  local price = (50 + biomeid * 210) + (Random(-15, 15) * 10)

  if( cheap_item ) then
    price = 0.5 * price
  end
  return math.floor(price)
end

local function ap_get_cost_x_offset(price)
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
end

local function ap_generate_shop_item_entity(x, y)
  local entity_file = ap_get_item_override(y)
  local flags = ap_get_item_flags(y)
  local name = ap_get_item_name(y)

  if entity_file == nil or entity_file == "" then
    if bit.band(flags, 4) ~= 0 then -- trap
      -- TODO: jank this up
      entity_file = "mods/archipelago/files/entities/items/ap_useful_shopitem.xml"
    elseif bit.band(flags, 2) ~= 0 then -- useful
      entity_file = "mods/archipelago/files/entities/items/ap_useful_shopitem.xml"
    elseif bit.band(flags, 1) ~= 0 then -- progression
      entity_file = "mods/archipelago/files/entities/items/ap_progression_shopitem.xml"
    else  -- junk
      entity_file = "mods/archipelago/files/entities/items/ap_junk_shopitem.xml"
    end
  end

  local eid = EntityLoad(entity_file, x, y)
  for _, component in ipairs(EntityGetAllComponents(eid)) do
    if ComponentGetTypeName(component) == "ItemComponent" then
      ComponentSetValue2(component, "item_name", name)
    end
  end
  return eid
end

-- The majority of this function is taken from scripts/items/generate_shop_item.lua
local function ap_generate_shop_item(x, y, cheap_item)
  local biomeid = ap_get_shop_num(y)
  local price = ap_generate_item_price(biomeid, cheap_item)

  if cheap_item then
    EntityLoad("data/entities/misc/sale_indicator.xml", x, y)
  end

  local eid = ap_generate_shop_item_entity(x, y)

  EntityAddComponent(eid, "SpriteComponent", { 
    _tags="shop_cost,enabled_in_world",
    image_file="data/fonts/font_pixel_white.xml",
    is_text_sprite="1", 
    offset_x=tostring(ap_get_cost_x_offset(price)),
    offset_y="20",
    update_transform="1",
    update_transform_rotation="0",
    text=tostring(price),
    z_index="-1",
  })

  EntityAddComponent(eid, "ItemCostComponent", { 
    _tags="shop_cost,enabled_in_world", 
    cost=price,
    stealable="1"
  })

  -- We add a custom component to store the id that we are unlocking when the item is purchased
  EntityAddComponent(eid, "VariableStorageComponent", {
    _tags="archipelago,enabled_in_world",
    name="ap_location_id",
    value_string=ap_get_item_id_str(y)
  })
end

local function ap_spawn_either(x, y, is_sale)
  if ap_remaining_ap_items > 0 and Randomf() <= ap_remaining_ap_items / ap_remaining_items then
    ap_generate_shop_item(x, y, is_sale)
    ap_remaining_ap_items = ap_remaining_ap_items - 1
    ap_num_ap_items = ap_num_ap_items + 1
  else
    generate_shop_item(x, y, is_sale, nil, true )
  end
  ap_remaining_items = ap_remaining_items - 1
end

-- Replacing this function with our own to inject AP items
spawn_all_shopitems = function(x, y)
  EntityLoad( "data/entities/buildings/shop_hitbox.xml", x, y )
  
  SetRandomSeed(x, y)
  -- this is the "Extra Item In Holy Mountain" perk
  local count = tonumber( GlobalsGetValue( "TEMPLE_SHOP_ITEM_COUNT", "5" ) )
  local width = 132
  local item_width = width / count
  local sale_item_i = Random( 1, count )

  if( Random(0, 100) <= 50 ) then
    ap_remaining_ap_items = 5
    ap_remaining_items = count * 2
    for i=1,count do
      ap_spawn_either(x + (i-1)*item_width, y, i == sale_item_i)
      ap_spawn_either(x + (i-1)*item_width, y - 30, false)
      LoadPixelScene( "data/biome_impl/temple/shop_second_row.png", "data/biome_impl/temple/shop_second_row_visual.png", x + (i-1)*item_width - 8, y-22, "", true )
    end
  else
    for i=1,count do
      if i <= 5 then
        ap_generate_shop_item(x + (i-1)*item_width, y, i == sale_item_i)
      else
        generate_shop_wand(x + (i-1)*item_width, y, i == sale_item_i)
      end
    end
  end
end
