-- streaming_integration/event_list.lua
dofile_once("data/scripts/streaming_integration/event_utilities.lua")
dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/archipelago/scripts/ap_utils.lua")
dofile_once("data/archipelago/scripts/ap_fungal_utils.lua")

local NULL_ENTITY = 0 --[[@as entity_id]]
local NULL_COMPONENT = 0 --[[@as component_id]]

---@cast NULL_ENTITY -integer,+entity_id
---@cast NULL_COMPONENT -integer,+component_id

--- Replacement for add_icon_above_head with description included.
---@param game_effect_entity entity_id
---@param icon_file string?
---@param event table
local function AddIconAboveHead(game_effect_entity, icon_file, event)
	if game_effect_entity == nil then return end
	EntityAddComponent2( game_effect_entity, "UIIconComponent",
	{
		name = event.ui_name,
		description = event.ui_description,
		icon_sprite_file = icon_file,
		display_above_head = true,
		display_in_hud = false,
		is_perk = false,
	})
end

---@param effect_entity entity_id
---@param icon_file string?
---@param event table
---@param hudonly boolean?
local function AddIcon(effect_entity, icon_file, event, hudonly)
	if hudonly then
		add_icon_in_hud(effect_entity, icon_file, event)
	else
		AddIconAboveHead(effect_entity, icon_file, event)
	end
end

---@param event table
---@param game_effect string
---@param frames integer
---@param hudonly boolean?
---@return entity_id effect entity
local function ApplyStatusEffect(event, game_effect, frames, hudonly)
	local player = get_player()
	if player == nil then return NULL_ENTITY end

	local effect_comp, effect_entity = GetGameEffectLoadTo(player, game_effect, false)
	if effect_comp ~= NULL_COMPONENT and effect_entity ~= NULL_ENTITY then
		ComponentSetValue2(effect_comp, "frames", frames)
		AddIcon(effect_entity, event.ui_icon, event, hudonly)
	end
	return effect_entity
end

---@param event table
---@param game_effect_file string
---@param frames integer
---@param hudonly boolean?
---@return entity_id effect entity
local function ApplyCustomStatusEffect(event, game_effect_file, frames, hudonly)
	local player = get_player()	-- using get_player_always here causes cape problems with INVISIBLE_BAD + POLYMORPH
	if player == nil then return NULL_ENTITY end

	local effect_entity = LoadGameEffectEntityTo(player, game_effect_file)
	if effect_entity ~= NULL_ENTITY then
		local effect_comp = EntityGetFirstComponent(effect_entity, "GameEffectComponent")
		if effect_comp ~= nil then
			ComponentSetValue2(effect_comp, "frames", frames)
		end
		AddIcon(effect_entity, event.ui_icon, event, hudonly)
	end
	return effect_entity
end

---@param distance number maximum distance to search (rectangular)
---@param radius number distance away from wall
---@return number x
---@return number y
local function GetRandomSpawnPosNearby(distance, radius)
	InitRandomSeed()
	local x, y = get_spawn_position()

	local spawn_x = x
	local spawn_y = y
	local best_dist = 0
	for _ = 1,20 do
		local _, hit_x, hit_y = RaytraceSurfacesAndLiquiform(x, y, x + Random(-distance, distance), y + Random(-distance, distance))

		local new_dist = get_distance2(x, y, hit_x, hit_y)
		if new_dist > best_dist then
			spawn_x = hit_x
			spawn_y = hit_y
			best_dist = new_dist
		end
	end

	-- NOTE: FindFreePositionForBody does not work

	local dx = spawn_x - x
	local dy = spawn_y - y
	local dlen = math.sqrt(dx*dx + dy*dy)

	spawn_x = spawn_x - dx / dlen * radius
	spawn_y = spawn_y - dy / dlen * radius
	return spawn_x, spawn_y
end

---Yeets an item in a random direction from the player based on given force.
---@param throw_item entity_id
---@param force number
local function YeetItem(throw_item, force)
	local player_x, player_y = get_spawn_position()
	local targ_x, targ_y = GetRandomSpawnPosNearby(force*2, 0)
	local dir_x = targ_x - player_x
	local dir_y = targ_y - player_y
	local len = math.sqrt(dir_x * dir_x + dir_y * dir_y)
	dir_x = dir_x / len
	dir_y = dir_y / len

	local velocity_comp = EntityGetFirstComponent(throw_item, "VelocityComponent")
	if velocity_comp ~= nil then
		ComponentSetValue2(velocity_comp, "mVelocity", dir_x * force * 2, dir_y * force * 2)
	end
	PhysicsApplyForce(throw_item, dir_x * force, dir_y * force)
end

local archipelago_traps = {
	{
		id = "AP_POLY_SELF",
		ui_name = "$ap_trap_poly_self",
		ui_icon = "data/ui_gfx/status_indicators/polymorph.png",
		action = function(event)
			ApplyStatusEffect(event, "POLYMORPH", 600, true)
		end
	},
	{
		id = "AP_STUN",
		ui_name = "$ap_trap_stun",
		ui_icon = "data/ui_gfx/status_indicators/electrocution.png",
		action = function(event)
			ApplyStatusEffect(event, "ELECTROCUTION", 600)
		end
	},
	{
		id = "AP_CONFUSION",
		ui_name = "$ap_trap_confusion",
		ui_icon = "data/ui_gfx/status_indicators/confusion.png",
		action = function(event)
			ApplyStatusEffect(event, "CONFUSION", 1200)
		end
	},
	{
		id = "AP_ON_FIRE",
		ui_name = "$ap_trap_on_fire",
		ui_icon = "data/ui_gfx/status_indicators/on_fire.png",
		action = function(event)
			ApplyStatusEffect(event, "ON_FIRE", 900)
		end
	},
	{
		id = "AP_TELEPORT",
		ui_name = "$ap_trap_teleport",
		ui_icon = "data/ui_gfx/status_indicators/teleportation.png",
		action = function(event)
			ApplyStatusEffect(event, "UNSTABLE_TELEPORTATION", 120)
		end
	},
	{
		id = "AP_POISON",
		ui_name = "$ap_trap_poison",
		ui_icon = "data/ui_gfx/status_indicators/poisoned.png",
		action = function(event)
			ApplyStatusEffect(event, "POISON", 1200)
		end
	},
	{
		id = "AP_FREEZE",
		ui_name = "$ap_trap_freeze",
		ui_icon = "data/ui_gfx/status_indicators/frozen.png",
		action = function(event)
			ApplyStatusEffect(event, "FROZEN", 360)
		end
	},
	{
		id = "AP_CHILLED",
		ui_name = "$ap_trap_chilled",
		ui_icon = "data/ui_gfx/status_indicators/ingestion_freezing.png",
		action = function(event)
			ApplyStatusEffect(event, "INTERNAL_ICE", 1200)
		end
	},
	{
		id = "AP_CHAOS_FUNGAL_SHIFT",
		ui_name = "$ap_trap_chaos_fungal_shift",
		ui_icon = "data/ui_gfx/status_indicators/trip.png",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/entities/misc/effect_trip_02.xml", 300, true)
			ChaosFungalShift()
			ChaosFungalShift()
			ChaosFungalShift()
		end
	},
	{
		id = "AP_TNT",
		ui_name = "$ap_trap_tnt",
		action = function(event)
			local x, y = GetRandomSpawnPosNearby(20, 8)
			EntityLoad("data/archipelago/entities/props/minecraft_tnt.xml", x, y - 10)
		end
	},
	{
		id = "AP_TNT_BARREL",
		ui_name = "$ap_trap_tnt_barrel",
		action = function(event)
			local x, y = GetRandomSpawnPosNearby(20, 8)
			EntityLoad("data/archipelago/entities/props/barrel_tnt.xml", x, y - 10)
		end
	},
	{
		id = "AP_BEES",
		ui_name = "$ap_trap_bees",
		action = function(event)
			local spawn_x, spawn_y = GetRandomSpawnPosNearby(200, 20)
			for _ = 1,15 do
				local _, hit_x, hit_y = RaytraceSurfacesAndLiquiform(spawn_x, spawn_y, spawn_x + Random(-30, 30), spawn_y + Random(-30, 30))
				EntityLoad("data/archipelago/entities/animals/bee.xml", (spawn_x + hit_x) / 2, (spawn_y + hit_y) / 2)
			end
		end
	},
	{
		id = "AP_144P",
		ui_name = "$ap_trap_144p",
		ui_icon = "data/ui_gfx/status_indicators/confusion.png",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_144p.xml", 1200, true)
		end
	},
	{
		id = "AP_FLIP_VER",
		ui_name = "$ap_trap_flip_vertical",
		ui_icon = "data/ui_gfx/status_indicators/confusion.png",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_flip_ver.xml", 1200, true)
		end
	},
	{
		id = "AP_FLIP_HOR",
		ui_name = "$ap_trap_flip_horizontal",
		ui_icon = "data/ui_gfx/gun_actions/horizontal_arc.png",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_flip_hor.xml", 1200, true)
		end
	},
	{
		id = "AP_ZOOM_IN",
		ui_name = "$ap_trap_zoom_in",
		ui_icon = "data/ui_gfx/status_indicators/confusion.png",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_zoom_in.xml", 1200, true)
		end
	},
	{
		id = "AP_ZOOM_OUT",
		ui_name = "$ap_trap_zoom_out",
		ui_icon = "data/ui_gfx/status_indicators/confusion.png",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_zoom_out.xml", 1200, true)
		end
	},
	{
		id = "AP_FISH_EYE",
		ui_name = "$ap_trap_fisheye",
		ui_icon = "data/ui_gfx/status_indicators/confusion.png",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_fisheye.xml", 1200, true)
		end
	},
	{
		id = "AP_INVERT_COLOUR",
		ui_name = "$ap_trap_invert_colour",
		ui_icon = "data/ui_gfx/status_indicators/confusion.png",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_invert_colours.xml", 1800, true)
		end
	},
	{
		id = "AP_RANDOM_STATUS",
		ui_name = "$ap_trap_random_status",
		action = function(event)
			InitRandomSeed()
			local bad_status_traps = {
				"AP_STUN", "AP_CONFUSION", "AP_ON_FIRE", "AP_POISON", "AP_FREEZE", "AP_CHILLED", "SLIMY_PLAYER", "OILED_PLAYER", "DRUNK_PLAYER", "SLOW_PLAYER", "PLAYER_GAS", "TWITCHY",
			}
			local next_trap_id = bad_status_traps[Random(1, #bad_status_traps)]
			for _, trap in ipairs(streaming_events) do
				if trap.id == next_trap_id then
					trap.action(trap)
					break
				end
			end
		end
	},
	{
		id = "AP_INSTANT_DAMAGE",
		ui_name = "$ap_trap_instant_damage",
		action = function(event)
			local player = get_player()
			if player == nil then return end
			EntityInflictDamage(player, 0.5, "DAMAGE_CURSE", "$ap_trap_instant_damage", "NONE", 0, 0)
		end
	},
	{
		id = "AP_INSTANT_DEATH",
		ui_name = "$ap_trap_instant_death",
		kind = STREAMING_EVENT_AWFUL,
		action = function(event)
			local player = get_player()
			if player == nil then return end
			EntityInflictDamage(player, 999999999, "DAMAGE_CURSE", "$ap_trap_instant_death", "NONE", 0, 0)
		end
	},
	{
		id = "AP_ONE_HP",
		ui_name = "$ap_trap_one_hp",
		kind = STREAMING_EVENT_AWFUL,
		action = function(event)
			local player = get_player()
			if player == nil then return end

			local damage_comps = EntityGetComponent(player, "DamageModelComponent") or {}
			for _, comp in ipairs(damage_comps) do
				-- Play the damage sound effect
				EntityInflictDamage(player, -0.0000001, "DAMAGE_CURSE", "$ap_trap_one_hp", "NONE", 0, 0)
				ComponentSetValue2(comp, "hp", 1.0 / 25)
			end
		end
	},
	{
		id = "AP_INVISIBLE_BAD",
		ui_name = "$ap_trap_invisible_bad",
		ui_icon = "data/ui_gfx/status_indicators/invisibility.png",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_invisible_bad.xml", 1200, true)
		end
	},
	{
		id = "AP_MANA_DRAIN",
		ui_name = "$ap_trap_mana_drain",
		ui_icon = "data/ui_gfx/status_indicators/mana_regeneration.png",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_mana_drain.xml", 2700, true)
		end
	},
	{
		id = "AP_POLY_FROG",
		ui_name = "$ap_trap_poly_frog",
		ui_icon = "data/ui_gfx/status_indicators/polymorph_random.png",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_poly_frog.xml", 1200, true)
		end
	},
	{
		id = "AP_EXTREME_CHAOS",
		ui_name = "$ap_trap_extreme_chaos",
		ui_icon = "data/ui_gfx/status_indicators/trip.png",
		kind = STREAMING_EVENT_AWFUL,
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_extreme_chaos.xml", 601, true)
		end
	},
	{
		id = "AP_RADIOACTIVE",
		ui_name = "$ap_trap_radioactive",
		ui_icon = "data/ui_gfx/status_indicators/radioactive.png",
		action = function(event)
			ApplyStatusEffect(event, "RADIOACTIVE", 1800)
		end
	},
	{
		-- WORK IN PROGRESS --
		id = "AP_TARR_TRAP",
		ui_name = "$ap_trap_tarr",
		action = function(event)
			InitRandomSeed()
			local num_spawns = Random(1, 5)

			local spawn_x, spawn_y = GetRandomSpawnPosNearby(50, 25)
			for _ = 1,num_spawns do
				local _, hit_x, hit_y = RaytraceSurfacesAndLiquiform(spawn_x, spawn_y, spawn_x + Random(-20, 20), spawn_y + Random(-20, 20))
				EntityLoad("data/archipelago/entities/animals/tarr.xml", (spawn_x + hit_x) / 2, (spawn_y + hit_y) / 2)
			end
		end
	},
	{
		id = "AP_WHOOPS_TRAP",
		ui_name = "$ap_trap_throw_selected",
		action = function(event)
			local player = get_player()
			if player == nil then return end

			local inventory = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
			if inventory == nil then return end

			local throw_item = ComponentGetValue2(inventory, "mActiveItem")
			if throw_item ~= nil then
				EntityDropItem(player, throw_item)
			end

			YeetItem(throw_item, 600)
		end
	},
	{
		id = "AP_EMPTY_ITEM_BOX",
		ui_name = "$ap_trap_empty_item_box",
		action = function(event)
			local player = get_player()
			if player == nil then return end

			local children = EntityGetAllChildren(player) or {}
			for _,child in ipairs(children) do
				if EntityGetName(child) == "inventory_quick" then
					local inventory = EntityGetAllChildren(child) or {}
					for _,item in ipairs(inventory) do
						EntityDropItem(player, item)
						YeetItem(item, 40)
					end
				end
			end
		end
	},
	{
		id = "AP_EJECT_ABILITY",
		ui_name = "$ap_trap_eject_ability",
		action = function(event)
			InitRandomSeed()
			local player = get_player()
			if player == nil then return end
			local x, y = EntityGetTransform(player)

			local children = EntityGetAllChildren(player) or {}
			for _,child in ipairs(children) do
				if EntityGetName(child) == "inventory_quick" then
					local inventory = EntityGetAllChildren(child, "wand") or {}
					for _,wand in ipairs(inventory) do
						local spells = EntityGetAllChildren(wand, "card_action") or {}
						if #spells > 0 then
							local spell = spells[Random(1, #spells)]
							EntityDropItem(player, spell)
							EntitySetTransform(spell, x, y)
							YeetItem(spell, 40)
						end
					end
				end
			end
		end
	},
	{
		id = "AP_DOUBLE_DAMAGE",
		ui_name = "$ap_trap_double_damage",
		ui_icon = "data/ui_gfx/status_indicators/wither.png",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_double_damage.xml", 2700, true)
		end
	},
	{
		id = "AP_DRYSPELL",
		ui_name = "$ap_trap_dryspell",
		ui_description = "$ap_trap_dryspell_desc",
		ui_icon = "data/archipelago/ui_gfx/status_effects/dryspell2.png",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_dryspell.xml", 3600, true)
		end
	},
	{
		id = "AP_CAMERA_ROTATE",
		ui_name = "$ap_trap_camera_rotate",
		ui_icon = "data/ui_gfx/status_indicators/confusion.png",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_camera_rotate.xml", 1800, true)
		end
	},
	{
		id = "AP_SHEEP_SFX",
		ui_name = "$ap_trap_sheep_sfx",
		ui_icon = "data/ui_gfx/status_indicators/polymorph.png",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_sheep_sfx.xml", 1800, true)
		end
	},
	{
		id = "AP_BECOME_SPEED",
		ui_name = "$ap_trap_become_speed",
		ui_description = "$ap_trap_become_speed_desc",
		ui_icon = "data/archipelago/ui_gfx/status_effects/become_speed.png",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_speed.xml", 1800, true)
		end
	},
	{
		id = "AP_SPELL_SHUFFLE",
		ui_name = "$ap_trap_spell_shuffle",
		ui_description = "$ap_trap_spell_shuffle_desc",
		action = function(event)
			InitRandomSeed()
			local player = get_player()
			if player == nil then return end
			local x, y = EntityGetTransform(player)

			local shuffle_spells = {}
			local children = EntityGetAllChildren(player) or {}
			local inventories = {}
			for _,child in ipairs(children) do
				if EntityGetName(child) ~= "inventory_quick" then goto next_child end
				table.insert(inventories, child)

				local inventory = EntityGetAllChildren(child, "wand") or {}
				for _,wand in ipairs(inventory) do
					local slots_used = {}

					local spells = EntityGetAllChildren(wand, "card_action") or {}
					for _,spell in ipairs(spells) do
						local item_comp = EntityGetFirstComponentIncludingDisabled(spell, "ItemComponent")
						if item_comp == nil then goto continue end
						if ComponentGetValue2(item_comp, "permanently_attached") == true then goto continue end

						local slot_x, slot_y = ComponentGetValue2(item_comp, "inventory_slot")
						if slot_y ~= 0 then goto continue end

						slots_used[slot_x] = true
						table.insert(shuffle_spells, {
							wand = wand,
							spell = spell,
							slot = slot_x,
						})
						::continue::
					end

					for i = 0,EntityGetWandCapacity(wand)-1 do
						if not slots_used[i] then
							table.insert(shuffle_spells, {
								wand = wand,
								spell = nil,
								slot = i,
							})
						end
					end
				end
				::next_child::
			end

			for i = 1, #shuffle_spells do
				local j = Random(1, #shuffle_spells)
				shuffle_spells[i].spell, shuffle_spells[j].spell = shuffle_spells[j].spell, shuffle_spells[i].spell
			end

			for _,spelldef in ipairs(shuffle_spells) do
				local spell = spelldef.spell
				if spell ~= nil then
					EntityRemoveFromParent(spell)
					EntitySetTransform(spell, x, y)
					EntityAddChild(spelldef.wand, spell)

					local item_comp = EntityGetComponent(spell, "ItemComponent")
					if item_comp then
						ComponentSetValue2(item_comp, "inventory_slot", spelldef.slot, 0)
					end
				end
			end

			local inv = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
			if inv ~= nil then
				ComponentSetValue2(inv, "mForceRefresh", true)
				ComponentSetValue2(inv, "mActualActiveItem", 0)
			end
		end
	},
	{
		id = "AP_STICKY_GROUND",
		ui_name = "$ap_trap_sticky_ground",
		ui_icon = "data/ui_gfx/gun_actions/glue_shot.png",
		action = function(event)
			for _ = 1,4 do
				local x, y = GetRandomSpawnPosNearby(20, 0)
				shoot_projectile_ownerless("data/archipelago/entities/projectiles/super_glue.xml", x, y, 0, 0)
			end
		end
	},
}

for _, trap in ipairs(archipelago_traps) do
	trap.ui_description = trap.ui_description or trap.ui_name or trap.id
	trap.ui_author = trap.ui_author or "Archipelago"
	trap.ui_icon = trap.ui_icon or ""
	trap.weight = trap.weight or 1.0
	trap.kind = trap.kind or STREAMING_EVENT_BAD

	table.insert(streaming_events, trap)
end
