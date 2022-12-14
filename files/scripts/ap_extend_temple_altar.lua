dofile_once("data/scripts/perks/perk.lua")

local function ap_extend_temple_altar()
  local item_table = dofile("data/scripts/ap_item_mappings.lua")
  local TRAP_ID = 110000

  local remaining_ap_items = 0
  local total_remaining_items = 0
  local num_ap_items = 0

  -- Retrieves the shop index based on the y coordinate (depth) to determine which holy mountain it is
  local function get_shop_num(y)
    if y < 1500 then return 1 -- Mines
    elseif y < 3000 then return 2 -- Coal Pits
    elseif y < 5500 then return 3 -- Snowy Depths
    elseif y < 7000 then return 4 -- Hiisi Base
    elseif y < 9500 then return 5 -- Underground Jungle
    elseif y < 11500 then return 6 -- The Vault
    else return 7 -- Temple of the Art
    end
  end

  -- Gets the location id for the shop based on the y coordinate and number of AP items already placed (assuming max 5)
  local function get_shop_location_id_str(y)
    return tostring(111000 + (get_shop_num(y)-1) * 5 + num_ap_items)
  end

  -- Gets the actual name of the item to be put into the shop
  local function get_item_name(y)
    return GlobalsGetValue("AP_SHOPITEM_NAME_" .. get_shop_location_id_str(y))
  end

  -- Gets the flags of the item to be put into the shop
  -- For a list of flags, see
  -- https://github.com/ArchipelagoMW/Archipelago/blob/main/docs/network%20protocol.md#networkitem 
  local function get_item_flags(y)
    return tonumber(GlobalsGetValue("AP_SHOPITEM_FLAGS_" .. get_shop_location_id_str(y), "0"))
  end

  -- Gets the item ID associated with the shop location
  local function get_item_id(y)
    return tonumber(GlobalsGetValue("AP_SHOPITEM_ITEM_ID_" .. get_shop_location_id_str(y)))
  end

  -- Uses vanilla wand price calculation, copied from the actual shop code.
  -- cheap_item is true if it's an on-sale item
  local function generate_item_price(biomeid, cheap_item)
    print("BIOME ID IS " .. biomeid)
    biomeid = (0.5 * biomeid) + ( 0.5 * biomeid * biomeid )
    local price = (50 + biomeid * 210) + (Random(-15, 15) * 10)

    if( cheap_item ) then
      price = 0.5 * price
    end
    return math.floor(price)
  end -- generate_item_price

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

  -- Spawn in an item or perk entity for the shop
  local function create_our_item_entity(item, x, y)
    if item.shop.perk ~= nil then
      -- our item is a perk (dont_remove_other_perks = true)
      return perk_spawn(x, y, item.shop.perk, true)
    elseif #item.shop > 0 then
      -- our item is something else (random choice)
      local eid = EntityLoad(item.shop[Random(1, #item.shop)], x, y)

      EntityAddComponent( eid, "LuaComponent", { 
        script_item_picked_up="data/scripts/items/shop_effect.lua"
      })

      return eid
    else -- error?
      -- TODO
      print_error("Failed to load our own shopitem!")
    end
  end

  -- Creates a trap item
  local function create_trap_item_entity(x, y)
    local entity_name = "mods/archipelago/files/entities/items/ap_trap_item_0" .. tostring(Random(1, 4)) .. ".xml"
    local trap_description = "$ap_shopdescription_trap" .. tostring(Random(1, 8))
    return EntityLoad(entity_name, x, y), trap_description
  end

  local ITEM_FLAG_PROGRESSION = 1
  local ITEM_FLAG_USEFUL = 2
  local ITEM_FLAG_TRAP = 4

  local function create_ap_entity_from_flags(x, y)
    local flags = get_item_flags(y)

    if bit.band(flags, ITEM_FLAG_TRAP) ~= 0 then
      return create_trap_item_entity(x, y)
    end
    
    local item_filename = "ap_junk_shopitem.xml"
    local item_description = "$ap_shopdescription_junk"
    if bit.band(flags, ITEM_FLAG_USEFUL) ~= 0 then
      item_filename = "ap_useful_shopitem.xml"
      item_description = "$ap_shopdescription_useful"
    elseif bit.band(flags, ITEM_FLAG_PROGRESSION) ~= 0 then
      item_filename = "ap_progression_shopitem.xml"
      item_description = "$ap_shopdescription_progression"
    end

    local item_entity = EntityLoad("mods/archipelago/files/entities/items/" .. item_filename, x, y)
    return item_entity, item_description
  end

  -- Spawns in an AP item (our own entity to represent items that don't exist in this game)
  local function create_foreign_item_entity(x, y)
    local eid, description = create_ap_entity_from_flags(x, y)
    local name = get_item_name(y)

    -- Change item name
    for _, component in ipairs(EntityGetAllComponents(eid)) do
      if ComponentGetTypeName(component) == "ItemComponent" then
        ComponentSetValue2(component, "item_name", name)
        ComponentSetValue2(component, "ui_description", description)
      end
    end
    return eid
  end

  -- Generates an items and creates the entity used to make the shop item
  local function generate_ap_shop_item_entity(x, y)
    local item_id = get_item_id(y)
    local item = item_table[item_id]
    local flags = get_item_flags(y)
    local name = get_item_name(y)

    if item and item.shop and item_id ~= TRAP_ID then
      return create_our_item_entity(item, x, y)
    else
      return create_foreign_item_entity(x, y)
    end
  end -- generate_ap_shop_item_entity

  -- The majority of this function is taken from scripts/items/generate_shop_item.lua
  -- Used to create the shop item and attach components to make it interactable, and have unique descriptions etc.
  local function generate_ap_shop_item(x, y, cheap_item)
    local biomeid = get_shop_num(y)
    local price = generate_item_price(biomeid, cheap_item)

    if cheap_item then
      EntityLoad("data/entities/misc/sale_indicator.xml", x, y)
    end

    local eid = generate_ap_shop_item_entity(x, y)

    EntityAddComponent(eid, "SpriteComponent", { 
      _tags="shop_cost,enabled_in_world",
      image_file="data/fonts/font_pixel_white.xml",
      is_text_sprite="1", 
      offset_x=tostring(get_cost_x_offset(price)),
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
      value_string=get_shop_location_id_str(y)
    })
  end -- generate_shop_item

  -- Spawns either an AP item or spell shop item randomly, based on 
  local function spawn_either(x, y, is_sale, is_wand_shop)
    if remaining_ap_items > 0 and Randomf() <= remaining_ap_items / total_remaining_items then
      generate_ap_shop_item(x, y, is_sale)
      remaining_ap_items = remaining_ap_items - 1
      num_ap_items = num_ap_items + 1
    else
      if is_wand_shop then
        generate_shop_wand(x, y, is_sale)
      else
        generate_shop_item(x, y, is_sale, nil, true)
      end
    end
    total_remaining_items = total_remaining_items - 1
  end -- spawn_either

  -- Replacing this function with our own to inject AP items
  spawn_all_shopitems = function(x, y)
    EntityLoad( "data/entities/buildings/shop_hitbox.xml", x, y )

    SetRandomSeed(x, y)
    -- this is the "Extra Item In Holy Mountain" perk
    local count = tonumber( GlobalsGetValue( "TEMPLE_SHOP_ITEM_COUNT", "5" ) )
    local width = 132
    local item_width = width / count
    local sale_item_i = Random( 1, count )

    -- Reset AP values
    remaining_ap_items = 5
    num_ap_items = 0

    if( Random(0, 100) <= 50 ) then
      -- Spell shop
      total_remaining_items = count * 2
      for i=1,count do
        spawn_either(x + (i-1)*item_width, y, i == sale_item_i)
        spawn_either(x + (i-1)*item_width, y - 30, false)
        LoadPixelScene( "data/biome_impl/temple/shop_second_row.png", "data/biome_impl/temple/shop_second_row_visual.png", x + (i-1)*item_width - 8, y-22, "", true )
      end
    else
      -- Wand shop
      total_remaining_items = count
      for i=1,count do
        spawn_either(x + (i-1)*item_width, y, i == sale_item_i, true)
      end
    end

  end -- spawn_all_shopitems

end

ap_extend_temple_altar()
