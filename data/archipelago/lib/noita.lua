--- Pure Noita specific functions, usable by other mods.
dofile_once("data/archipelago/lib/extensions.lua")

---@class Noita
local Noita = {
	---@type {[string]:table}?
	PerkMap = nil,
}

---@type any
local ZERO = 0

NULL_ENTITY = ZERO ---@type entity_id
NULL_COMPONENT = ZERO ---@type component_id


--- @return entity_id|nil
function Noita.GetPlayer()
	return EntityGetWithTag("player_unit")[1]
end

--- Retrieves the player entity even if it is polymorphed
--- @return entity_id|nil
function Noita.GetPlayerAlways()
	return Noita.GetPlayer() or EntityGetWithTag("polymorphed_player")[1] or EntityGetWithTag("polymorphed_cessation")[1]
end

--- Gets a position for spawning items. Should always succeed.
--- Checks positions in this order:
---   1. Entity tagged with `player_unit`
---   2. Entity tagged with `polymorphed_player`
---   3. Entity tagged with `polymorphed_cessation`
---   4. Camera position
---@return number x
---@return number y
function Noita.GetSpawnPosition()
	local x = 0
	local y = 0
	local player_entity = Noita.GetPlayerAlways()
	if player_entity ~= nil then
		x, y = EntityGetTransform(player_entity)
	else
		x, y = GameGetCameraPos()
	end
	return x, y
end

--- Stolen from Fair Mod
---@param entity entity_id
---@param item_entity entity_id
function Noita.EntityDropItem(entity, item_entity)
	EntityRemoveFromParent(item_entity)
	EntitySetComponentsWithTagEnabled(item_entity, "enabled_in_hand", false)
	EntitySetComponentsWithTagEnabled(item_entity, "enabled_in_world", true)

	local inventory_comp = EntityGetFirstComponentIncludingDisabled(entity, "Inventory2Component")
	if inventory_comp ~= nil then
		ComponentSetValue2(inventory_comp, "mActiveItem", 0)
		ComponentSetValue2(inventory_comp, "mActualActiveItem", 0)
		ComponentSetValue2(inventory_comp, "mForceRefresh", true)
	end
end

---@param entity_file string
---@param x number
---@param y number
---@param vel_x number? default 0
---@param vel_y number? default 0
---@return entity_id
function Noita.ShootProjectileOwnerless(entity_file, x, y, vel_x, vel_y)
	local entity_id = EntityLoad( entity_file, x, y )
	vel_x = vel_x or 0
	vel_y = vel_y or 0

	GameShootProjectile(NULL_ENTITY, x, y, x + vel_x, y + vel_y, entity_id)

	local velocity_comp = EntityGetFirstComponent(entity_id, "VelocityComponent")
	if velocity_comp ~= nil then
		ComponentSetValue2(velocity_comp, "mVelocity", vel_x, vel_y)
	end
	return entity_id
end

-- Modified from @Priskip in Noita Discord (https://github.com/Priskip)
-- Removes an Extra Life perk and returns true if one exists
---@param entity_id entity_id
---@return boolean
function Noita.DecreaseExtraLife(entity_id)
	if entity_id == nil then return false end

	local children = EntityGetAllChildren(entity_id)
	for _, child in ipairs(children or {}) do
		local effect_component = EntityGetFirstComponentIncludingDisabled(child, "GameEffectComponent")
		local effect_value = effect_component and ComponentGetValue2(effect_component, "effect")

		if effect_value == "RESPAWN" and effect_component and ComponentGetValue2(effect_component, "mCounter") == 0 then
			--Remove extra life child
			EntityKill(child)

			--Remove UI component
			for _, child2 in ipairs(children or {}) do
				local child_ui_icon_component = EntityGetFirstComponentIncludingDisabled(child2, "UIIconComponent")
				local name_value = child_ui_icon_component and ComponentGetValue2(child_ui_icon_component, "name")

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


-- health and money functions from the cheatgui mod
---@return number current HP
---@return number max HP
function Noita.GetHealth()
	local plyr = Noita.GetPlayer()
	if plyr == nil then return 0, 0 end
	local dm = EntityGetComponent(plyr, "DamageModelComponent")[1]
	return ComponentGetValue2(dm, "hp"), ComponentGetValue2(dm, "max_hp")
end


-- Note that these hp values get mulitplied by 25 by the game. Setting it to 80 means 2,000 health
---@param cur_hp number
---@param max_hp number
function Noita.SetHealth(cur_hp, max_hp)
	local plyr = Noita.GetPlayer()
	if plyr == nil then return end
	local damagemodels = EntityGetComponent(plyr, "DamageModelComponent")
	for _, damagemodel in ipairs(damagemodels or {}) do
		ComponentSetValue2(damagemodel, "max_hp", max_hp)
		ComponentSetValue2(damagemodel, "hp", cur_hp)
	end
end


--- Previously add_cur_and_max_health
---@param health_increase number
function Noita.AddHealthUp(health_increase)
	local cur_hp, max_hp = Noita.GetHealth()
	Noita.SetHealth(cur_hp + health_increase, max_hp + health_increase)
end


---@param amt number
function Noita.AddMoney(amt)
	local player_id = Noita.GetPlayer()
	if player_id == nil then return end

	local x, y = EntityGetTransform(player_id)
	local wallet = EntityGetFirstComponent(player_id, "WalletComponent")
	if wallet == nil then return end

	local current_money = ComponentGetValue2(wallet, "money")
	ComponentSetValue2(wallet, "money", current_money + amt)
	Noita.ShootProjectileOwnerless("data/entities/particles/gold_pickup_huge.xml", x, y)
end

local function InitPerkMap()
	if Noita.PerkMap ~= nil then return end

	dofile_once("data/scripts/perks/perk_list.lua")

	Noita.PerkMap = {}
	for _, perk in ipairs(perk_list) do
		Noita.PerkMap[perk.id] = perk
	end
end

---@param perk_id string
---@return table?
function Noita.GetPerkWithID(perk_id)
	InitPerkMap()
	return Noita.PerkMap[perk_id]
end

---@param entity_who_picked entity_id
---@param perk_id string
---@param do_cosmetic_fx boolean?
function Noita.GivePerk(entity_who_picked, perk_id, do_cosmetic_fx)
	local pos_x, pos_y = EntityGetTransform( entity_who_picked )

	local perk_name = "PERK_NAME_NOT_DEFINED"
	local perk_desc = "PERK_DESCRIPTION_NOT_DEFINED"

	local perk_data = Noita.GetPerkWithID(perk_id)
	if perk_data == nil then
		return
	end

	-- Is this needed? Probably not?
	-- vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
	local flag_name = "PERK_PICKED_" .. perk_id
	local pickup_count = tonumber(GlobalsGetValue(flag_name .. "_PICKUP_COUNT", "0"))
	pickup_count = pickup_count + 1
	GlobalsSetValue(flag_name .. "_PICKUP_COUNT", tostring(pickup_count))

	local add_progress_flags = not GameHasFlagRun("no_progress_flags_perk")

	if add_progress_flags then
		local flag_name_persistent = string.lower(flag_name)
		if not HasFlagPersistent(flag_name_persistent) then
			GameAddFlagRun( "new_" .. flag_name_persistent )
		end
		AddFlagPersistent( flag_name_persistent )
	end
	GameAddFlagRun( flag_name )
	-- ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

	local no_remove = perk_data.do_not_remove or false

	-- add a game effect or two
	if perk_data.game_effect ~= nil then
		local game_effect_comp,game_effect_entity = GetGameEffectLoadTo(entity_who_picked, perk_data.game_effect, true)
		if game_effect_comp ~= nil then
			ComponentSetValue2(game_effect_comp, "frames", -1)

			if ( no_remove == false ) then
				ComponentAddTag(game_effect_comp, "perk_component")
				EntityAddTag(game_effect_entity, "perk_entity")
			end
		end
	end

	if perk_data.game_effect2 ~= nil then
		local game_effect_comp,game_effect_entity = GetGameEffectLoadTo(entity_who_picked, perk_data.game_effect2, true)
		if game_effect_comp ~= nil then
			ComponentSetValue2(game_effect_comp, "frames", -1)

			if ( no_remove == false ) then
				ComponentAddTag(game_effect_comp, "perk_component")
				EntityAddTag(game_effect_entity, "perk_entity")
			end
		end
	end

	-- particle effect only applied once
	if perk_data.particle_effect ~= nil and ( pickup_count <= 1 ) then
		local particle_id = EntityLoad("data/entities/particles/perks/" .. perk_data.particle_effect .. ".xml")

		if no_remove == false then
			EntityAddTag( particle_id, "perk_entity" )
		end
		EntityAddChild( entity_who_picked, particle_id )
	end

	-- certain other perks may be marked as picked-up
	if perk_data.remove_other_perks ~= nil then
		for _, v in ipairs(perk_data.remove_other_perks) do
			local f = "PERK_PICKED_" .. v
			GameAddFlagRun( f )

			-- NOTE( Petri ): 8.8.2023 - Thank you to Noita community for this fix.
			-- this should remove the related perks from the perk pool. 4realz.
			local remove_perk_pickup_count = tonumber(GlobalsGetValue(f .. "_PICKUP_COUNT", "0"))
			remove_perk_pickup_count = remove_perk_pickup_count + 1
			GlobalsSetValue(f .. "_PICKUP_COUNT", tostring(remove_perk_pickup_count))
		end
	end

	if perk_data.func ~= nil then
		perk_data.func(NULL_ENTITY, entity_who_picked, perk_id, pickup_count)
	end

	perk_name = GameTextGetTranslatedOrNot(perk_data.ui_name)
	perk_desc = GameTextGetTranslatedOrNot(perk_data.ui_description)

	-- add ui icon etc
	local entity_ui = EntityCreateNew("")
	EntityAddComponent2( entity_ui, "UIIconComponent",
	{
		name = perk_data.ui_name,
		description = perk_data.ui_description,
		icon_sprite_file = perk_data.ui_icon
	})

	if no_remove == false then
		EntityAddTag(entity_ui, "perk_entity")
	end

	EntityAddChild(entity_who_picked, entity_ui)

	-- cosmetic fx -------------------------------------------------------
	if do_cosmetic_fx then
		local enemies_killed = tonumber(StatsBiomeGetValue("enemies_killed"))

		if enemies_killed ~= 0 then
			EntityLoad("data/entities/particles/image_emitters/perk_effect.xml", pos_x, pos_y)
		else
			EntityLoad("data/entities/particles/image_emitters/perk_effect_pacifist.xml", pos_x, pos_y)
		end
		GamePrintImportant(GameTextGet( "$log_pickedup_perk", GameTextGetTranslatedOrNot(perk_name)), perk_desc)
	end
end

---@param x number
---@param y number
---@param perk_id string
---@return entity_id?
function Noita.SpawnPerk(x, y, perk_id)
	local perk_data = Noita.GetPerkWithID(perk_id)
	if perk_data == nil then
		print_error( "SpawnPerk called with'" .. perk_id .. "' - no perk with such id exists." )
		return nil
	end
	print(string.format("SpawnPerk %s @ %d,%d", perk_id, x, y))

	local entity_id = EntityLoad( "data/entities/items/pickup/perk.xml", x, y )
	if entity_id == nil then return nil end

	EntityAddComponent2(entity_id, "SpriteComponent",
	{
		image_file = perk_data.perk_icon or "data/items_gfx/perk.xml",
		offset_x = 8,
		offset_y = 8,
		update_transform = 1,
		update_transform_rotation = 0,
	})

	EntityAddComponent2(entity_id, "UIInfoComponent",
	{
		name = perk_data.ui_name,
	})

	EntityAddComponent2(entity_id, "ItemComponent",
	{
		item_name = perk_data.ui_name,
		ui_description = perk_data.ui_description,
		ui_display_description_on_pick_up_hint = 1,
		play_spinning_animation = 0,
		play_hover_animation = 0,
		play_pick_sound = 0,
	})

	EntityAddComponent2(entity_id, "SpriteOffsetAnimatorComponent",
	{
      sprite_id=-1,
      x_amount=0,
      x_phase=0,
      x_phase_offset=0,
      x_speed=0,
      y_amount=2,
      y_speed=3,
	})

	EntityAddComponent2(entity_id, "VariableStorageComponent",
	{
		name = "perk_id",
		value_string = perk_data.id,
	})

	EntityAddComponent2(entity_id, "VariableStorageComponent",
	{
		name = "perk_dont_remove_others",
		value_bool = true,
	})

	return entity_id
end

---@param origin string
---@param cause string
---@return string
function Noita.ParseCauseOfDeath(origin, cause)
	local result = 'Noita'
	if string.not_empty(origin) and string.not_empty(cause) then
		if origin:sub(-1) == 's' then
			result = GameTextGet("$menugameover_causeofdeath_killer_cause_name_ends_in_s", origin, cause)
		else
			result = GameTextGet("$menugameover_causeofdeath_killer_cause", origin, cause)
		end
	elseif string.not_empty(origin) then
		result = origin
	elseif string.not_empty(cause) then
		result = cause
	end
	return result
end

---@return string
function Noita.GetCauseOfDeath()
	local raw_death_msg = StatsGetValue("killed_by")
	local origin, cause = string.match(raw_death_msg or " | ", "(.*) | (.*)")

	if string.not_empty(origin) then
		origin = GameTextGetTranslatedOrNot(origin)
	end

	return Noita.ParseCauseOfDeath(origin, cause) .. (StatsGetValue("killed_by_extra") or "")
end

---Gets the currently selected item in the quickbar inventory.
---@return entity_id?
function Noita.SelectedItem()
	local player = Noita.GetPlayer()
	if player == nil then return nil end

	local inventory_comp = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
	if inventory_comp == nil then return nil end

	return ComponentGetValue2(inventory_comp, "mActiveItem")
end

---@param tbl any[]
---@param itm any
---@return integer
local function find_item_index(tbl, itm)
	for i,v in ipairs(tbl) do
		if v == itm then return i end
	end
	return 1
end

---Sets the currently selected quickbar item to the given entity.
---@param item_entity entity_id
function Noita.SelectItem(item_entity)
	local player = Noita.GetPlayer()
	if player == nil then return end

	local inventory_comp = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
	if inventory_comp == nil then return end

	local active_item = ComponentGetValue2(inventory_comp, "mActiveItem")
	local actual_active_item = ComponentGetValue2(inventory_comp, "mActualActiveItem")

	EntitySetComponentsWithTagEnabled(active_item, "enabled_in_hand", false)
	EntitySetComponentsWithTagEnabled(actual_active_item, "enabled_in_hand", false)
	EntitySetComponentsWithTagEnabled(item_entity, "enabled_in_world", false)
	EntitySetComponentsWithTagEnabled(item_entity, "enabled_in_inventory", true)
	EntitySetComponentsWithTagEnabled(item_entity, "enabled_in_hand", true)
	ComponentSetValue2(inventory_comp, "mActiveItem", item_entity)
	ComponentSetValue2(inventory_comp, "mActualActiveItem", 0)
	ComponentSetValue2(inventory_comp, "mForceRefresh", true)
	GamePlaySound("data/audio/Desktop/ui.bank", "ui/item_equipped", EntityGetTransform(player))
end

---Switches the inventory item in the given direction
---@param direction integer 1 = one forward, -1 = one backwards, etc
function Noita.SwitchInventoryItem(direction)
	local player = Noita.GetPlayer()
	if player == nil then return nil end

	local active_item = Noita.SelectedItem()

	local children = GameGetAllInventoryItems(player) or {}
	local inventory_list = {}
	for _,child in ipairs(children) do
		if EntityGetName(EntityGetParent(child)) == "inventory_quick" then
			table.insert(inventory_list, child)
		end
	end
	if #inventory_list == 0 then return end

	local idx = find_item_index(inventory_list, active_item) - 1
	local next_item = inventory_list[math.floor((#inventory_list + idx + direction) % #inventory_list) + 1]

	Noita.SelectItem(next_item)
end

function Noita.ChangeEntityName(entity_id, new_name, new_description)
	if entity_id == nil then return end

	for _, comp in ipairs(EntityGetComponentIncludingDisabled(entity_id, "UIInfoComponent") or {}) do
		if new_name ~= nil then
			ComponentSetValue2(comp, "name", new_name)
		end
	end

	for _, comp in ipairs(EntityGetComponentIncludingDisabled(entity_id, "UIIconComponent") or {}) do
		if new_name ~= nil then
			ComponentSetValue2(comp, "name", new_name)
		end

		if new_description ~= nil then
			ComponentSetValue2(comp, "description", new_description)
		end
	end

	for _, comp in ipairs(EntityGetComponentIncludingDisabled(entity_id, "ItemComponent") or {}) do
		if new_name ~= nil then
			ComponentSetValue2(comp, "item_name", new_name)
		end

		if new_description ~= nil then
			ComponentSetValue2(comp, "ui_description", new_description)
		end
	end

	for _, comp in ipairs(EntityGetComponentIncludingDisabled(entity_id, "AbilityComponent") or {}) do
		if new_name ~= nil then
			ComponentSetValue2(comp, "ui_name", new_name)
		end
	end
end

---Gets the items in the 4 quickbar slots on the right (potions, tablets, etc).
---@return entity_id[]
function Noita.GetQuickbarNonWandItems()
	local result = {}

	local player = Noita.GetPlayer()
	if player ~= nil then
		for _,item in ipairs(GameGetAllInventoryItems(player) or {}) do
			local item_comp = EntityGetFirstComponentIncludingDisabled(item, "AbilityComponent")
			if item_comp ~= nil then
				if not ComponentGetValue2(item_comp, "use_gun_script") then
					table.insert(result, item)
				end
			end
		end
	end
	return result
end

local total_random_calls = 0
--- For maximum random
function Noita.InitRandomSeed()
	local x, y = Noita.GetSpawnPosition()
	SetRandomSeed(x + GameGetFrameNum(), y * total_random_calls)
	total_random_calls = total_random_calls + 1
end

return Noita
