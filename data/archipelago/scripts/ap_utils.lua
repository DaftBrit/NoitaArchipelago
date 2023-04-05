dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/perks/perk.lua")
local AP = dofile("data/archipelago/scripts/constants.lua")


function contains_element(tbl, elem)
	for _, v in ipairs(tbl) do
		if v == elem then return true end
	end
	return false
end


function not_empty(s)
	return s ~= nil and s ~= ''
end


--Function to spawn a perk at the player and then have the player automatically pick it up
function give_perk(perk_name)
	for i, p in ipairs(get_players()) do
		local x, y = EntityGetTransform(p)
		local perk = perk_spawn(x, y, perk_name)
		perk_pickup(perk, p, EntityGetName(perk), false, false)
	end
end


function add_items_to_inventory(items)
	local player = get_players()[1]
	for _, path in ipairs(items) do
		local item = EntityLoad(path)
		if item then
			GamePickUpInventoryItem(player, item)
		else
			print_error("Error: Couldn't load the item [" .. path .. "]!")
		end
	end
end


-- Uses the player's position to initialize the random seed
function SeedRandom()
	for _, p in ipairs(get_players()) do
		local x, y = EntityGetTransform(p)
		SetRandomSeed(x, y)
	end
end


function EntityLoadAtPlayer(filename, xoff, yoff)
	for _, p in ipairs(get_players()) do
		local x, y = EntityGetTransform(p)
		return EntityLoad(filename, x + (xoff or 0), y + (yoff or 0))
	end
end


function GetCauseOfDeath()
	local raw_death_msg = StatsGetValue("killed_by")
	local origin, cause = string.match(raw_death_msg, "(.*) | (.*)")

	if origin then
		origin = GameTextGetTranslatedOrNot(origin)
	end

	local result = 'Noita'
	if not_empty(origin) and not_empty(cause) then
		if origin:sub(-1) == 's' then
			result = GameTextGet("$menugameover_causeofdeath_killer_cause_name_ends_in_s", origin, cause)
		else
			result = GameTextGet("$menugameover_causeofdeath_killer_cause", origin, cause)
		end
	elseif not_empty(origin) then
		result = origin
	elseif not_empty(cause) then
		result = cause
	end

	return result .. StatsGetValue("killed_by_extra")
end


-- Modified from @Priskip in Noita Discord (https://github.com/Priskip)
-- Removes an Extra Life perk and returns true if one exists
function DecreaseExtraLife(entity_id)
	local children = EntityGetAllChildren(entity_id)
	for _, child in ipairs(children) do
		local effect_component = EntityGetFirstComponentIncludingDisabled(child, "GameEffectComponent")
		local effect_value = ComponentGetValue2(effect_component, "effect")

		if effect_value == "RESPAWN" and ComponentGetValue2(effect_component, "mCounter") == 0 then
			--Remove extra life child
			EntityKill(child)

			--Remove UI component
			for _2, child2 in ipairs(children) do
				local child_ui_icon_component = EntityGetFirstComponentIncludingDisabled(child2, "UIIconComponent")
				local name_value = ComponentGetValue2(child_ui_icon_component, "name")

				if name_value == "$perk_respawn" then
					EntityKill(child2)
					break
				end
			end

			GamePrintImportant("$log_gamefx_respawn", "$logdesc_gamefx_respawn")
			return true
		end
	end
	return false
end


local function get_player()
	return EntityGetWithTag("player_unit")[1]
end


function isMovingRight()
	local control = EntityGetFirstComponent(get_player(), "ControlsComponent")
	return ComponentGetValue2(control, "mButtonDownRight")
end


-- health and money functions from the cheatgui mod
function get_health()
	local dm = EntityGetComponent(get_player(), "DamageModelComponent")[1]
	return ComponentGetValue(dm, "hp"), ComponentGetValue(dm, "max_hp")
end


-- Note that these hp values get mulitplied by 25 by the game. Setting it to 80 means 2,000 health
function set_health(cur_hp, max_hp)
	local damagemodels = EntityGetComponent(get_player(), "DamageModelComponent")
	for _, damagemodel in ipairs(damagemodels or {}) do
		ComponentSetValue(damagemodel, "max_hp", max_hp)
		ComponentSetValue(damagemodel, "hp", cur_hp)
	end
end


function add_cur_and_max_health(health_increase)
	local cur_hp, max_hp = get_health()
	set_health(cur_hp + health_increase, max_hp + health_increase)
end


function fully_heal()
	local _, max_hp = get_health()
	set_health(max_hp, max_hp)
end


local function set_money(amt)
	local wallet = EntityGetFirstComponent(get_player(), "WalletComponent")
	ComponentSetValue2(wallet, "money", amt)
end


function add_money(amt)
	local wallet = EntityGetFirstComponent(get_player(), "WalletComponent")
	local current_money = ComponentGetValue2(wallet, "money")
	ComponentSetValue2(wallet, "money", current_money + amt)
end


-- from the wiki
function addNewInternalVariable(entity_id, variable_name, variable_type, initial_value)
	if(variable_type == "value_int") then
		EntityAddComponent2(entity_id, "VariableStorageComponent", {
			name=variable_name,
			value_int=initial_value
		})
	elseif(variable_type == "value_string") then
		EntityAddComponent2(entity_id, "VariableStorageComponent", {
			name=variable_name,
			value_string=initial_value
		})
	elseif(variable_type == "value_float") then
		EntityAddComponent2(entity_id, "VariableStorageComponent", {
			name=variable_name,
			value_float=initial_value
		})
	elseif(variable_type == "value_bool") then
		EntityAddComponent2(entity_id, "VariableStorageComponent", {
			name=variable_name,
			value_bool=initial_value
		})
	end
end


-- from the wiki
function getInternalVariableValue(entity_id, variable_name, variable_type)
	local value = nil
	local components = EntityGetComponent( entity_id, "VariableStorageComponent" )
	if ( components ~= nil ) then
		for key,comp_id in pairs(components) do
			local var_name = ComponentGetValue2( comp_id, "name" )
			if(var_name == variable_name) then
				value = ComponentGetValue2(comp_id, variable_type)
			end
		end
	end
	return value
end


function create_ap_entity_from_flags(location, x, y)
  	local flags = location.item_flags

  	local item_filename = "ap_junk_shopitem.xml"
  	local item_description = "$ap_shopdescription_junk"
	if flags == nil then
		print("flags == nil")
	elseif bit.band(flags, AP.ITEM_FLAG_USEFUL) ~= 0 then
	    item_filename = "ap_useful_shopitem.xml"
	    item_description = "$ap_shopdescription_useful"
  	elseif bit.band(flags, AP.ITEM_FLAG_PROGRESSION) ~= 0 then
	    item_filename = "ap_progression_shopitem.xml"
	    item_description = "$ap_shopdescription_progression"
  	elseif bit.band(flags, AP.ITEM_FLAG_TRAP) ~= 0 then
    	item_filename = "ap_trap_item.xml"
    	item_description = "$ap_shopdescription_trap" .. tostring(Random(1, 8))
  	end

  	local item_entity = EntityLoad("data/archipelago/entities/items/" .. item_filename, x, y)
	if bit.band(flags, AP.ITEM_FLAG_TRAP) ~= 0 and location.is_our_item then
		 EntityAddComponent(item_entity, "LuaComponent", {
			 _tags="archipelago",
             script_item_picked_up="data/archipelago/scripts/items/ap_trap.lua",
             })
	end
  	return item_entity, item_description
end


function create_our_item_entity(item, x, y)
  	if item.perk ~= nil then
    	return perk_spawn(x, y, item.perk, true)
  	elseif item.items ~= nil and #item.items > 0 then
    	-- our item is something else (random choice)
		local entity_id = EntityLoad(item.items[Random(1, #item.items)], x, y)
		local life_comp = EntityGetFirstComponent(entity_id, "LifetimeComponent", "enabled_in_world")
		if life_comp ~= nil then
			EntityRemoveComponent(entity_id, life_comp)
		end
		return entity_id
  	else
    	Log.Error("Failed to load our own item!")
  	end
end


-- Spawns in an AP item (our own entity to represent items that don't exist in this game)
function create_foreign_item_entity(location, x, y)
  local entity_id, description = create_ap_entity_from_flags(location, x, y)
  local name = location.item_name

  -- Change item name
  change_entity_ingame_name(entity_id, name, description)
  return entity_id
end


function give_debug_items()
	give_perk("PROTECTION_EXPLOSION")
	give_perk("PROTECTION_FIRE")
	give_perk("PROTECTION_RADIOACTIVITY")
	add_items_to_inventory({"data/entities/items/wand_level_10.xml", "data/entities/items/wands/custom/digger_01.xml"})
	give_perk("MOVEMENT_FASTER")
	give_perk("MOVEMENT_FASTER")
	give_perk("HOVER_BOOST")
	give_perk("FASTER_LEVITATION")
	give_perk("UNLIMITED_SPELLS")
	give_perk("REMOVE_FOG_OF_WAR")
	for _ = 1, 10 do
		give_perk("GENOME_MORE_LOVE")
	end
	set_money(100000000)
	set_health(80, 80)
	EntityLoadAtPlayer("mods/archipelago/data/archipelago/entities/items/pw_teleporter.xml", 60)
	-- above teleports you between parallel worlds, off the wiki. aim left to go right one world
	-- don't aim other directions. the linear arc means it snaps to 8 directions
end
