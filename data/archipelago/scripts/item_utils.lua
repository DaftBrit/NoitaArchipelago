dofile_once("data/archipelago/scripts/ap_utils.lua")

local item_table = dofile("data/archipelago/scripts/item_mappings.lua")
local AP = dofile("data/archipelago/scripts/constants.lua")

is_redeliverable_item = {
    [110001] = true,
    [110002] = true,
    [110003] = false, -- don't redeliver potions
    [110004] = true,
    [110005] = true,
    [110006] = true,
    [110007] = true,
    [110008] = true,
    [110009] = true,
    [110010] = true,
    [110011] = true,
    [110012] = true,
    [110013] = true,
    [110014] = true,
    [110015] = true,
    [110016] = true,
    [110017] = true,
    [110018] = true,
    [110019] = true,
    [110020] = true,
    [110021] = true, -- this is the respawn perk, whether to redeliver or not is still up for discussion
    [110022] = true,
}

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
  print("item spawning shortly")
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

function UpdateDeliveredItems(sender_location_pair)
	delivered_items[sender_location_pair] = true
	local f = io.open("mods/archipelago/cache/delivered_" .. ap_seed, "w")
	f:write(JSON:encode(delivered_items))
	f:close()
end