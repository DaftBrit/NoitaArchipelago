dofile( "data/scripts/game_helpers.lua" )
dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/archipelago/scripts/ap_utils.lua")
local AP = dofile("data/archipelago/scripts/constants.lua")
local Globals = dofile("data/archipelago/scripts/globals.lua")
local Constants = dofile("data/archipelago/scripts/constants.lua")

local entity_id = GetUpdatedEntityID()
local pos_x, pos_y = EntityGetTransform(entity_id)

local orbcomp = EntityGetComponent(entity_id, "OrbComponent")
local spritecomp = EntityGetComponent(entity_id, "SpriteComponent")
local orb_id = -1

for _, comp_id in pairs(orbcomp) do
	orb_id = ComponentGetValueInt(comp_id, "orb_id")
	EntityRemoveComponent(entity_id, comp_id)
end

print("orb_id is " .. orb_id)

local location = Globals.LocationScouts:get_key(orb_id + Constants.FIRST_ORB_LOCATION_ID)
print("location ID shoudl be " .. Constants.FIRST_ORB_LOCATION_ID)
local flags = location.item_flags

-- there's no AP.ITEM_FLAG_JUNK, so the default appearance is junk instead
local orb_file = "ap_orb_junk"

print("ap_locationscouts_data is " .. GlobalsGetValue("AP_LOCATIONSCOUTS_DATA"))

print("ap.item_flags below")
print(location)
print(bit.band(flags, AP.ITEM_FLAG_TRAP))
print(bit.band(flags, AP.ITEM_FLAG_USEFUL))
print(bit.band(flags, AP.ITEM_FLAG_PROGRESSION))

print(GlobalsGetValue("AP_LOCATIONSCOUTS_DATA"))

if bit.band(flags, AP.ITEM_FLAG_TRAP) ~= 0 then
	orb_file = "ap_orb_trap_" .. tostring(Random(1,3))
elseif bit.band(flags, AP.ITEM_FLAG_USEFUL) ~= 0 then
	orb_file = "ap_orb_useful"
elseif bit.band(flags, AP.ITEM_FLAG_PROGRESSION) ~= 0 then
	orb_file = "ap_orb_progression"
end

for _, comp_id in pairs(spritecomp) do
	ComponentSetValue2(comp_id, "image_file", "data/archipelago/entities/items/orbs/" .. orb_file .. ".xml")
end

--this variable just stores the original orb_id elsewhere, not sure if it'll be needed later?
addNewInternalVariable(entity_id, "OriginalID", "value_int", orb_id)
