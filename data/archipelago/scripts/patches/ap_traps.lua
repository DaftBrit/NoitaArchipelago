-- streaming_integration/event_list.lua
dofile_once("data/scripts/streaming_integration/event_utilities.lua")
dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/archipelago/scripts/ap_utils.lua")
dofile_once("data/archipelago/scripts/ap_fungal_utils.lua")

local NULL_ENTITY = 0
local NULL_COMPONENT = 0

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
---@param icon string
---@param hudonly boolean?
---@return entity_id effect entity
local function ApplyStatusEffect(event, game_effect, frames, icon, hudonly)
	local player = get_player_always()
	if player == nil then return NULL_ENTITY end

	local effect_comp, effect_entity = GetGameEffectLoadTo(player, game_effect, false)
	if effect_comp ~= NULL_COMPONENT and effect_entity ~= NULL_ENTITY then
		ComponentSetValue2(effect_comp, "frames", frames)
		AddIcon(effect_entity, icon, event, hudonly)
	end
	return effect_entity
end

---@param event table
---@param game_effect_file string
---@param frames integer
---@param icon string
---@param hudonly boolean?
---@return entity_id effect entity
local function ApplyCustomStatusEffect(event, game_effect_file, frames, icon, hudonly)
	local player = get_player_always()
	if player == nil then return NULL_ENTITY end

	local effect_entity = LoadGameEffectEntityTo(player, game_effect_file)
	if effect_entity ~= NULL_ENTITY then
		local effect_comp = EntityGetFirstComponent(effect_entity, "GameEffectComponent")
		if effect_comp ~= nil then
			ComponentSetValue2(effect_comp, "frames", frames)
		end
		AddIcon(effect_entity, icon, event, hudonly)
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
	for _ = 1,10 do
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

local archipelago_traps = {
	{
		id = "AP_POLY_SELF",
		ui_name = "$ap_trap_poly_self",
		action = function(event)
			ApplyStatusEffect(event, "POLYMORPH", 600, "data/ui_gfx/status_indicators/polymorph.png", true)
		end
	},
	{
		id = "AP_STUN",
		ui_name = "$ap_trap_stun",
		action = function(event)
			ApplyStatusEffect(event, "ELECTROCUTION", 600, "data/ui_gfx/status_indicators/electrocution.png")
		end
	},
	{
		id = "AP_CONFUSION",
		ui_name = "$ap_trap_confusion",
		action = function(event)
			ApplyStatusEffect(event, "CONFUSION", 1200, "data/ui_gfx/status_indicators/confusion.png")
		end
	},
	{
		id = "AP_ON_FIRE",
		ui_name = "$ap_trap_on_fire",
		action = function(event)
			ApplyStatusEffect(event, "ON_FIRE", 900, "data/ui_gfx/status_indicators/on_fire.png")
		end
	},
	{
		id = "AP_TELEPORT",
		ui_name = "$ap_trap_teleport",
		action = function(event)
			ApplyStatusEffect(event, "UNSTABLE_TELEPORTATION", 120, "data/ui_gfx/status_indicators/teleportation.png")
		end
	},
	{
		id = "AP_POISON",
		ui_name = "$ap_trap_poison",
		action = function(event)
			ApplyStatusEffect(event, "POISON", 1200, "data/ui_gfx/status_indicators/poisoned.png")
		end
	},
	{
		id = "AP_FREEZE",
		ui_name = "$ap_trap_freeze",
		action = function(event)
			ApplyStatusEffect(event, "FROZEN", 360, "data/ui_gfx/status_indicators/frozen.png")
		end
	},
	{
		id = "AP_CHILLED",
		ui_name = "$ap_trap_chilled",
		action = function(event)
			ApplyStatusEffect(event, "INTERNAL_ICE", 1200, "data/ui_gfx/status_indicators/ingestion_freezing.png")
		end
	},
	{
		id = "AP_CHAOS_FUNGAL_SHIFT",
		ui_name = "$ap_trap_chaos_fungal_shift",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/entities/misc/effect_trip_02.xml", 300, "data/ui_gfx/status_indicators/trip.png", true)
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
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_144p.xml", 1200, "data/ui_gfx/status_indicators/confusion.png", true)
		end
	},
	{
		id = "AP_FLIP_VER",
		ui_name = "$ap_trap_flip_vertical",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_flip_ver.xml", 1200, "data/ui_gfx/status_indicators/confusion.png", true)
		end
	},
	{
		id = "AP_FLIP_HOR",
		ui_name = "$ap_trap_flip_horizontal",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_flip_hor.xml", 1200, "data/ui_gfx/gun_actions/horizontal_arc.png", true)
		end
	},
	{
		id = "AP_ZOOM_IN",
		ui_name = "$ap_trap_zoom_in",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_zoom_in.xml", 1200, "data/ui_gfx/status_indicators/confusion.png", true)
		end
	},
	{
		id = "AP_ZOOM_OUT",
		ui_name = "$ap_trap_zoom_out",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_zoom_out.xml", 1200, "data/ui_gfx/status_indicators/confusion.png", true)
		end
	},
	{
		id = "AP_FISH_EYE",
		ui_name = "$ap_trap_fisheye",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_fisheye.xml", 1200, "data/ui_gfx/status_indicators/confusion.png", true)
		end
	},
	{
		id = "AP_INVERT_COLOUR",
		ui_name = "$ap_trap_invert_colour",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_invert_colours.xml", 1800, "data/ui_gfx/status_indicators/confusion.png", true)
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
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_invisible_bad.xml", 1200, "data/ui_gfx/status_indicators/invisibility.png", true)
		end
	},
	{
		id = "AP_MANA_DRAIN",
		ui_name = "$ap_trap_mana_drain",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_mana_drain.xml", 2700, "data/ui_gfx/status_indicators/mana_regeneration.png", true)
		end
	},
	{
		id = "AP_POLY_FROG",
		ui_name = "$ap_trap_poly_frog",
		action = function(event)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_poly_frog.xml", 1200, "data/ui_gfx/status_indicators/polymorph_random.png", true)
		end
	},
	{
		id = "AP_EXTREME_CHAOS",
		ui_name = "$ap_trap_extreme_chaos",
		kind = STREAMING_EVENT_AWFUL,
		action = function(event)
			ApplyCustomStatusEffect(event, "data/entities/misc/effect_trip_02.xml", 600, "data/ui_gfx/status_indicators/trip.png", true)
			ApplyCustomStatusEffect(event, "data/archipelago/entities/misc/effect_extreme_chaos.xml", 601, "data/ui_gfx/status_indicators/trip.png", true)
		end
	},
	{
		id = "AP_RADIOACTIVE",
		ui_name = "$ap_trap_radioactive",
		action = function(event)
			ApplyStatusEffect(event, "RADIOACTIVE", 1800, "data/ui_gfx/status_indicators/radioactive.png")
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
}

for _, trap in ipairs(archipelago_traps) do
	trap.ui_description = trap.ui_description or trap.ui_name or trap.id
	trap.ui_author = trap.ui_author or "Archipelago"
	trap.ui_icon = trap.ui_icon or ""
	trap.weight = trap.weight or 1.0
	trap.kind = trap.kind or STREAMING_EVENT_BAD

	table.insert(streaming_events, trap)
end
