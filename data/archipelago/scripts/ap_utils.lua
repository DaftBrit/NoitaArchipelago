local AP = dofile("data/archipelago/scripts/constants.lua") ---@type Constants
local Log = dofile("data/archipelago/scripts/logger.lua") ---@type Logger
local Globals = dofile("data/archipelago/scripts/globals.lua") --- @type Globals
dofile_once("data/archipelago/lib/extensions.lua")
local Noita = dofile_once("data/archipelago/lib/noita.lua") --- @type Noita


--- Staggers an x,y position randomly
---@param x number|nil
---@param y number|nil
---@return number x
---@return number y
function random_offset(x, y)
	if x == nil then x = 0 end
	if y == nil then y = 0 end
	x = x - 2 + Random(1, 40)/10
	y = y - 2 + Random(1, 40)/10
	return x, y
end


---Function to spawn a perk at the player and then have the player automatically pick it up
---@param perk_name string
function give_perk(perk_name)
	local p = Noita.GetPlayer()
	if p == nil then
		Log.Error("give_perk - player doesn't exist for " .. perk_name)
	end

	if p then
		Noita.GivePerk(p, perk_name)
	else
		local x, y = Noita.GetSpawnPosition()
		Noita.SpawnPerk(x, y, perk_name)
	end
end

---@param x number
---@param y number
---@param perk_id string
---@return entity_id?
function spawn_ap_perk(x, y, perk_id)
	local perk_entity = Noita.SpawnPerk(x, y, perk_id)
	if perk_entity ~= nil then
		EntityRemoveTag(perk_entity, "perk")
		EntityAddTag(perk_entity, "ap_item")
	end
	return perk_entity
end

---@param potion string filename
---@param x number|nil
---@param y number|nil
---@return entity_id
function spawn_potion(potion, x, y)
	-- if a position is not called, spawn it at the player
	if x == nil or y == nil then
		x, y = Noita.GetSpawnPosition()
	end

	local potion_entity = EntityLoad(potion, random_offset(x, y))
	local damage_model_comp = EntityGetFirstComponentIncludingDisabled(potion_entity, "DamageModelComponent")
	if damage_model_comp ~= nil then
		ComponentSetValue2(damage_model_comp, "invincibility_frames", 90)
	end
	EntityConvertToMaterial(potion_entity, "ap_gorilla_glass")

	EntityAddComponent2(potion_entity, "LuaComponent", {
		script_source_file="data/archipelago/scripts/items/potion_saver_remover.lua",
		execute_every_n_frame=90,
		execute_times=0,
		script_enabled_changed="data/archipelago/scripts/items/potion_saver_remover.lua"
	})

	return potion_entity
end

-- Uses the player's position to initialize the random seed
---@param a number|nil
---@param b number|nil
function SeedRandom(a, b)
	if a == nil or b == nil then
		a = 0
		b = 0
	end
	local x, y = Noita.GetSpawnPosition()
	SetRandomSeed(x + a, y + b)
end

---@param filename string
---@param xoff number|nil
---@param yoff number|nil
---@return entity_id
function EntityLoadAtPlayer(filename, xoff, yoff)
	local x, y = Noita.GetSpawnPosition()
	return EntityLoad(filename, x + (xoff or 0), y + (yoff or 0))
end

-- altered from the wiki
function addNewInternalVariable(entity_id, variable_name, variable_type, initial_value)
	if(variable_type == "value_int") then
		return EntityAddComponent2(entity_id, "VariableStorageComponent", {
			_tags="enabled_in_world,enabled_in_hand,enabled_in_inventory",
			name=variable_name,
			value_int=initial_value
		})
	elseif(variable_type == "value_string") then
		return EntityAddComponent2(entity_id, "VariableStorageComponent", {
			_tags="enabled_in_world,enabled_in_hand,enabled_in_inventory",
			name=variable_name,
			value_string=initial_value
		})
	elseif(variable_type == "value_float") then
		return EntityAddComponent2(entity_id, "VariableStorageComponent", {
			_tags="enabled_in_world,enabled_in_hand,enabled_in_inventory",
			name=variable_name,
			value_float=initial_value
		})
	elseif(variable_type == "value_bool") then
		return EntityAddComponent2(entity_id, "VariableStorageComponent", {
			_tags="enabled_in_world,enabled_in_hand,enabled_in_inventory",
			name=variable_name,
			value_bool=initial_value
		})
	end
	return nil
end


-- from the wiki
function getInternalVariableValue(entity_id, variable_name, variable_type)
	local value = nil
	local components = EntityGetComponent(entity_id, "VariableStorageComponent")
	for _, comp_id in ipairs(components or {}) do
		local var_name = ComponentGetValue2(comp_id, "name")
		if var_name == variable_name then
			value = ComponentGetValue2(comp_id, variable_type)
		end
	end
	return value
end


function create_ap_entity_from_flags(location, x, y)
	local flags = location.item_flags

	local enable_prog_icon = false
	local enable_useful_icon = false
	local enable_filler_icon = true

	local item_filename = "ap_standard_shopitem.xml"
	local item_description = "$ap_shopdescription_junk"
	if bit.band(flags, AP.ITEM_FLAG_USEFUL) ~= 0 then
		item_description = "$ap_shopdescription_useful"
		enable_useful_icon = true
		enable_filler_icon = false
	end
	if bit.band(flags, AP.ITEM_FLAG_PROGRESSION) ~= 0 then
		enable_prog_icon = true
		enable_filler_icon = false
		item_description = "$ap_shopdescription_progression"
		if enable_useful_icon then
			item_description = "$ap_shopdescription_proguseful"
		end
	end

	if bit.band(flags, AP.ITEM_FLAG_TRAP) ~= 0 then
		item_filename = "ap_trap_item.xml"
		item_description = "$ap_shopdescription_trap" .. tostring(Random(1, 9))
		if enable_useful_icon then
			item_description = "$ap_shopdescription_usefultrap"
		end
		if enable_prog_icon then
			item_description = "$ap_shopdescription_progtrap"
			if enable_useful_icon then
				item_description = "$ap_shopdescription_progusefultrap"
			end
		end
		if enable_filler_icon then
			local random_number = Random(1, 3)
			if random_number == 1 then
				enable_filler_icon = false
				enable_prog_icon = true
			elseif random_number == 2 then
				enable_filler_icon = false
				enable_useful_icon = true
			end
		end
	end

	local item_entity = EntityLoad("data/archipelago/entities/items/" .. item_filename, x, y)
	if enable_prog_icon == true then
		EntityAddComponent2(item_entity, "SpriteComponent", {
			image_file = "data/archipelago/entities/items/icons/progression_icon_bigger.png",
			offset_x = 0,
			offset_y = 0,
			z_index = 0.7,
			update_transform_rotation = false
		})
	end
	if enable_useful_icon == true then
		EntityAddComponent2(item_entity, "SpriteComponent", {
			image_file = "data/archipelago/entities/items/icons/useful_icon.png",
			offset_x = 9,
			offset_y = 9,
			z_index = 0.7,
			update_transform_rotation = false
		})
	end
	if enable_filler_icon == true then
		EntityAddComponent2(item_entity, "SpriteComponent", {
			image_file = "data/archipelago/entities/items/icons/filler_icon.png",
			offset_x = 0,
			offset_y = 0,
			z_index = 0.7,
			update_transform_rotation = false
		})
	end
	if bit.band(flags, AP.ITEM_FLAG_TRAP) ~= 0 and location.is_our_item then
			 EntityAddComponent2(item_entity, "LuaComponent", {
					 _tags="archipelago",
					 script_item_picked_up="data/archipelago/scripts/items/ap_trap.lua",
					 })
	end
	return item_entity, item_description
end


function create_our_item_entity(item, x, y)
	if item.perk ~= nil then
		return spawn_ap_perk(x, y, item.perk)
	elseif item.items ~= nil and #item.items > 0 then
		-- our item is something else (random choice)
		local entity_id = EntityLoad(item.items[Random(1, #item.items)], x, y)
		EntityAddTag(entity_id, "ap_item")
		local life_comp = EntityGetFirstComponent(entity_id, "LifetimeComponent", "enabled_in_world")
		if life_comp ~= nil then
			EntityRemoveComponent(entity_id, life_comp)
		end
		return entity_id
	else
		EntityLoad("data/archipelago/entities/items/pickup/ap_error_book.xml", x, y)
		Log.Error("Failed to load our own item at x = " .. x .. ", y = " .. y)
		return nil
	end
end


-- Spawns in an AP item (our own entity to represent items that don't exist in this game)
function create_foreign_item_entity(location, x, y)
	local entity_id, description = create_ap_entity_from_flags(location, x, y)
	local name = location.item_name or "problem in create_foreign_item_entity"

	-- Change item name
	Noita.ChangeEntityName(entity_id, name, description)
	return entity_id
end


-- for use with same slot co-op and for collects
---@param location_id integer
function remove_collected_item(location_id)
	local ap_entities = EntityGetWithTag("ap_item")
	for _, entity_id in ipairs(ap_entities) do
		local stored_location_id = getInternalVariableValue(entity_id, "ap_location_id", "value_int")
		if stored_location_id == location_id then
			print("removed entity " .. entity_id .. " because it was collected or your co-op partner grabbed it")
			EntityKill(entity_id)
		end
	end
	Globals.MissingLocationsSet:remove_key(location_id)
end


function countdown_fun()
	local x, y = Noita.GetSpawnPosition()
	for i = 0, 1 do
		local projectile_id = Noita.ShootProjectileOwnerless("data/entities/projectiles/deck/bullet.xml", x - 5 + 10 * i, y, -400 + 800 * i, -400)
		EntityAddComponent2(projectile_id, "ParticleEmitterComponent", {
			emitted_material_name="material_rainbow",
			emit_real_particles=true,
			color_is_based_on_pos=true,
			x_pos_offset_min=-2.236,
			y_pos_offset_min=-2.236,
			x_pos_offset_max=2.236,
			y_pos_offset_max=2.236,
			emission_interval_min_frames=0,
			emission_interval_max_frames=0,
			is_trail=true,
			draw_as_long=true,
		})
	end
end


function give_debug_items()
	give_perk("PROTECTION_EXPLOSION")
	give_perk("PROTECTION_FIRE")
	give_perk("PROTECTION_RADIOACTIVITY")
	EntityLoadAtPlayer("data/entities/items/wand_level_10.xml", -10)
	EntityLoadAtPlayer("data/entities/items/wands/custom/digger_01.xml", 10)
	give_perk("MOVEMENT_FASTER")
	give_perk("MOVEMENT_FASTER")
	give_perk("HOVER_BOOST")
	give_perk("FASTER_LEVITATION")
	give_perk("UNLIMITED_SPELLS")
	give_perk("REMOVE_FOG_OF_WAR")
	for _ = 1, 10 do
		give_perk("GENOME_MORE_LOVE")
		give_perk("RESPAWN")
	end
	Noita.SetHealth(80, 80)
	EntityLoadAtPlayer("data/archipelago/entities/items/pw_teleporter.xml", 60)
	-- above teleports you between parallel worlds, off the wiki. aim left to go right one world
	-- don't aim other directions. the linear arc means it snaps to 8 directions
end
