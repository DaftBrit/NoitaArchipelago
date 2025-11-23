dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/gun/procedural/gun_action_utils.lua")

local function get_random_from( target )
	local rnd = Random(1, #target)
	return tostring(target[rnd])
end

local function get_random_between_range( target )
	local minval = target[1]
	local maxval = target[2]

	return Random(minval, maxval)
end

local entity_id = GetUpdatedEntityID()
local x, y = EntityGetTransform( entity_id )
SetRandomSeed( x, y )

local ability_comp = EntityGetFirstComponent( entity_id, "AbilityComponent" )

local wand = { }
wand.name = {"thunder_wand"}
wand.deck_capacity = { 30, 30 }
wand.actions_per_round = 1
wand.reload_time = {0,0}
wand.shuffle_deck_when_empty = 0
wand.fire_rate_wait = {1,1}
wand.spread_degrees = {3,3}
wand.speed_multiplier = 1
wand.mana_charge_speed = {9000,9000}
wand.mana_max = {2000,2000}
wand.actions = { "LIGHTNING", "THUNDERBALL" }

local mana_max = get_random_between_range( wand.mana_max )
local deck_capacity = get_random_between_range( wand.deck_capacity )

if ability_comp ~= nil then
	ComponentSetValue2( ability_comp, "ui_name", get_random_from( wand.name ) )

	ComponentObjectSetValue2( ability_comp, "gun_config", "reload_time", get_random_between_range( wand.reload_time ) )
	ComponentObjectSetValue2( ability_comp, "gunaction_config", "fire_rate_wait", get_random_between_range( wand.fire_rate_wait ) )
	ComponentSetValue2( ability_comp, "mana_charge_speed", get_random_between_range( wand.mana_charge_speed ) )

	ComponentObjectSetValue2( ability_comp, "gun_config", "actions_per_round", wand.actions_per_round )
	ComponentObjectSetValue2( ability_comp, "gun_config", "deck_capacity", deck_capacity )
	ComponentObjectSetValue2( ability_comp, "gun_config", "shuffle_deck_when_empty", wand.shuffle_deck_when_empty )
	ComponentObjectSetValue2( ability_comp, "gunaction_config", "spread_degrees", get_random_between_range( wand.spread_degrees ) )
	ComponentObjectSetValue2( ability_comp, "gunaction_config", "speed_multiplier", wand.speed_multiplier )

	ComponentSetValue2( ability_comp, "mana_max", mana_max )
	ComponentSetValue2( ability_comp, "mana", mana_max )
end

AddGunAction( entity_id, "BURST_4" )
AddGunAction( entity_id, "DIVIDE_10" )
AddGunAction( entity_id, "DIVIDE_4" )
AddGunAction( entity_id, "DIVIDE_3" )
AddGunAction( entity_id, "ADD_TRIGGER" )
AddGunAction( entity_id, "DIVIDE_3" )
AddGunAction( entity_id, "DIVIDE_2" )
AddGunAction( entity_id, "ADD_TRIGGER" )
AddGunAction( entity_id, "ADD_TRIGGER" )
AddGunAction( entity_id, "PHASING_ARC" )
AddGunAction( entity_id, "PHASING_ARC" )
AddGunAction( entity_id, "LINE_ARC" )
AddGunAction( entity_id, "BLOOD_MAGIC" )
AddGunAction( entity_id, "ADD_DEATH_TRIGGER" )
AddGunAction( entity_id, "HOMING_SHOOTER" )
AddGunAction( entity_id, "X_RAY" )
AddGunAction( entity_id, "BURST_2" )
AddGunAction( entity_id, "DAMAGE" )
AddGunAction( entity_id, "SWAPPER_PROJECTILE" )
AddGunAction( entity_id, "EXPLODING_DEER" )
