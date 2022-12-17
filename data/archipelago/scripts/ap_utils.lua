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


function give_debug_items()
	give_perk("PROTECTION_EXPLOSION")
	give_perk("PROTECTION_FIRE")
	add_items_to_inventory({"data/entities/items/wand_level_10.xml"})
	EntityLoadAtPlayer( "data/entities/items/pickup/chest_random.xml", 20 ) -- for testing
	EntityLoadAtPlayer( "data/entities/items/pickup/chest_random.xml", 40 ) -- for testing
	EntityLoadAtPlayer( "data/entities/items/pickup/chest_random.xml", 60 ) -- for testing
	EntityLoadAtPlayer( "data/entities/items/pickup/chest_random.xml", 80 ) -- for testing
	EntityLoadAtPlayer( "data/entities/items/pickup/chest_random.xml", 100 ) -- for testing
	give_perk("MOVEMENT_FASTER") -- for testing gotta go fast
	give_perk("MOVEMENT_FASTER") -- for testing
	give_perk("HOVER_BOOST") -- for testing
	give_perk("FASTER_LEVITATION") -- for testing
	EntityLoadAtPlayer("data/entities/items/pickup/goldnugget_200000.xml") -- for testing we're rich we're rich
	EntityLoadAtPlayer("data/entities/items/pickup/goldnugget_200000.xml") -- for testing
	EntityLoadAtPlayer("data/entities/items/pickup/goldnugget_200000.xml") -- for testing
	EntityLoadAtPlayer("data/entities/items/pickup/goldnugget_200000.xml") -- for testing
	EntityLoadAtPlayer("data/entities/items/pickup/goldnugget_200000.xml") -- for testing
	EntityLoadAtPlayer("data/entities/items/pickup/heart_better.xml")
	EntityLoadAtPlayer("data/entities/items/pickup/heart_better.xml")
	EntityLoadAtPlayer("data/entities/items/pickup/heart_better.xml")
	EntityLoadAtPlayer("data/entities/items/pickup/heart_better.xml")
	EntityLoadAtPlayer("data/entities/items/pickup/heart_better.xml")
	EntityLoadAtPlayer("data/entities/items/pickup/heart_better.xml")
	EntityLoadAtPlayer("data/entities/items/pickup/heart_better.xml")
end
