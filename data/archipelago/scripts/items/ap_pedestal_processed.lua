dofile_once("data/scripts/lib/utilities.lua")
local Globals = dofile("data/archipelago/scripts/globals.lua")
dofile_once("data/archipelago/scripts/ap_utils.lua")


-- Called when the entity is picked up
function item_pickup(entity_item, entity_who_picked, name)
	-- Don't trigger for enemies who picked this wand up
	if not IsPlayer(entity_who_picked) then return end

	local location_id = getInternalVariableValue(entity_item, "ap_location_id", "value_int")
	assert(location_id ~= nil)

	-- Queue location for unlock
	GameAddFlagRun("ap" .. location_id)
	Globals.LocationUnlockQueue:append(location_id)

	-- Remove archipelago components
	local components = EntityGetAllComponents(entity_item)
	for _, comp in ipairs(components) do
		if ComponentHasTag(comp, "archipelago") then
			EntityRemoveComponent(entity_item, comp)
		end
	end
end
