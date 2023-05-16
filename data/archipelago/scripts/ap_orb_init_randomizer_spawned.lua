dofile( "data/scripts/game_helpers.lua" )
dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/lib/mod_settings.lua")

local entity_id = GetUpdatedEntityID()
local pos_x, pos_y = EntityGetTransform( entity_id )


local orbcomp = EntityGetComponent( entity_id, "OrbComponent" )
local orb_id = tonumber(GlobalsGetValue("ap_orb_id"))

if orb_id == nil then
	orb_id = 53
end

for _, comp_id in pairs(orbcomp) do
	ComponentSetValue( comp_id, "orb_id", orb_id + 33)
end

orb_id = orb_id + 1

GlobalsSetValue("ap_orb_id", tostring(orb_id))


local spritecomp = EntityGetFirstComponent(entity_id, "SpriteComponent")
local sprite_image = "ap_orb"

local orb_art_setting = ModSettingGet("archipelago.orb_art")


if orb_art_setting == "Vanilla" then
	sprite_image = "vanilla_orb"
elseif orb_art_setting == "spinny_logo" then
	sprite_image = "ap_orb_woah"
elseif orb_art_setting == "porb" then
	sprite_image = "porb"
end

ComponentSetValue2(spritecomp, "image_file", "data/archipelago/entities/items/orbs/" .. sprite_image .. ".xml")
