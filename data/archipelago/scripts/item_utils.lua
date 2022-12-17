dofile_once("data/archipelago/scripts/ap_utils.lua")

local item_table = dofile("data/archipelago/scripts/item_mappings.lua")
local AP = dofile("data/archipelago/scripts/constants.lua")

-- Traps
local function BadTimes()
	--Function to spawn "Bad Times" events, uses the noita streaming integration system
	dofile("data/archipelago/scripts/ap_badtimes.lua")

	local event = streaming_events[Random(1, #streaming_events)]
	local event_description = event.id:gsub("_", " ")
	GamePrintImportant("$ap_bad_times", event_description)
	_streaming_run_event(event.id)
end


function SpawnItem(item_id, traps)
  local item = item_table[item_id]
	if item == nil then
		print_error("[AP] spawn_item: Item id " .. tostring(item_id) .. " does not exist!")
		return
	end

  SeedRandom()

  if item_id == AP.TRAP_ID then
    if not traps then return end
    BadTimes()
  elseif item.shop.perk ~= nil then
    give_perk(item.shop.perk)
  elseif #item.shop > 0 then
    EntityLoadAtPlayer(item.shop[Random(1, #item.shop)])
  else
    print_error("[AP] Item " .. tostring(item_id) .. " not properly configured")
  end
end

