dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/perks/perk.lua")


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
	for _2, path in ipairs(items) do
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
	for i, p in ipairs(get_players()) do
    local x, y = EntityGetTransform(p)
		SetRandomSeed(x, y)
  end
end

function EntityLoadAtPlayer(filename, xoff, yoff)
  for i, p in ipairs(get_players()) do
    local x, y = EntityGetTransform(p)
    EntityLoad(filename, x + (xoff or 0), y + (yoff or 0))
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

-- health and money functions from the cheatgui mod
local function get_health()
	local dm = EntityGetComponent(get_player(), "DamageModelComponent")[1]
	return ComponentGetValue(dm, "hp"), ComponentGetValue(dm, "max_hp")
end

-- Note that these hp values get mulitplied by 25 by the game. Setting it to 80 means 2,000 health
local function set_health(cur_hp, max_hp)
	local damagemodels = EntityGetComponent(get_player(), "DamageModelComponent")
	for _, damagemodel in ipairs(damagemodels or {}) do
		ComponentSetValue(damagemodel, "max_hp", max_hp)
		ComponentSetValue(damagemodel, "hp", cur_hp)
	end
end

function fully_heal()
	local _, max_hp = get_health()
	set_health(max_hp, max_hp)
end

local function set_money(amt)
	local wallet = EntityGetFirstComponent(get_player(), "WalletComponent")
	ComponentSetValue2(wallet, "money", amt)
end

function give_debug_items()
	give_perk("PROTECTION_EXPLOSION")
	give_perk("PROTECTION_FIRE")
	add_items_to_inventory({"data/entities/items/wand_level_10.xml"})
	EntityLoadAtPlayer( "data/entities/items/pickup/chest_random.xml", 20 )
	EntityLoadAtPlayer( "data/entities/items/pickup/chest_random.xml", 40 )
	EntityLoadAtPlayer( "data/entities/items/pickup/chest_random.xml", 60 )
	EntityLoadAtPlayer( "data/entities/items/pickup/chest_random.xml", 80 )
	EntityLoadAtPlayer( "data/entities/items/pickup/chest_random.xml", 100 )
	give_perk("MOVEMENT_FASTER")
	give_perk("MOVEMENT_FASTER")
	give_perk("HOVER_BOOST")
	give_perk("FASTER_LEVITATION")
	give_perk("UNLIMITED_SPELLS")
	set_money(100000000)
	set_health(80, 80)
	EntityLoadAtPlayer("data/entities/items/wands/custom/digger_01.xml", -20) -- good for digging
	EntityLoadAtPlayer("mods/archipelago/data/archipelago/entities/items/pw_teleporter.xml", -40)
	-- above teleports you between parallel worlds, off the wiki. aim left to go right one world and vice versa
	-- don't aim other directions. the linear arc means it snaps to 8 directions
end
