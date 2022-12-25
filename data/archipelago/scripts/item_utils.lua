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
    [110021] = false, -- this is the respawn perk, whether to redeliver or not is still up for discussion
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
    print("Badtimes")
  elseif item.shop.perk ~= nil then
    give_perk(item.shop.perk)
    print("Perk spawned")
  elseif #item.shop > 0 then
    EntityLoadAtPlayer(item.shop[Random(1, #item.shop)])
    print("Item spawned")
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

function CheckBossLocations()
	if GameHasFlagRun("kolmi_is_dead") then
		SendCmd("LocationChecks", { locations = {110600,}})
		GameRemoveFlagRun("kolmi_is_dead")
	end
	if GameHasFlagRun("maggot_is_dead") then
		SendCmd("LocationChecks", { locations = {110610,}})
		GameRemoveFlagRun("maggot_is_dead")
	end
	if GameHasFlagRun("dragon_is_dead") then
		SendCmd("LocationChecks", { locations = {110620,}})
		GameRemoveFlagRun("dragon_is_dead")
	end
	if GameHasFlagRun("koipi_is_dead") then
		SendCmd("LocationChecks", { locations = {110630,}})
		GameRemoveFlagRun("koipi_is_dead")
	end
	if GameHasFlagRun("squidward_is_dead") then
		SendCmd("LocationChecks", { locations = {110640,}})
		GameRemoveFlagRun("squidward_is_dead")
	end
	if GameHasFlagRun("leviathan_is_dead") then
		SendCmd("LocationChecks", { locations = {110650,}})
		GameRemoveFlagRun("leviathan_is_dead")
	end
	if GameHasFlagRun("triangle_is_dead") then
		SendCmd("LocationChecks", { locations = {110660,}})
		GameRemoveFlagRun("triangle_is_dead")
	end
	if GameHasFlagRun("skull_is_dead") then
		SendCmd("LocationChecks", { locations = {110670,}})
		GameRemoveFlagRun("skull_is_dead")
	end
	if GameHasFlagRun("friend_is_dead") then
		SendCmd("LocationChecks", { locations = {110680,}})
		GameRemoveFlagRun("friend_is_dead")
	end
	if GameHasFlagRun("mestari_is_dead") then
		SendCmd("LocationChecks", { locations = {110690,}})
		GameRemoveFlagRun("mestari_is_dead")
	end
	if GameHasFlagRun("alchemist_is_dead") then
		SendCmd("LocationChecks", { locations = {110700,}})
		GameRemoveFlagRun("alchemist_is_dead")
	end
	if GameHasFlagRun("mecha_is_dead") then
		SendCmd("LocationChecks", { locations = {110710,}})
		GameRemoveFlagRun("mecha_is_dead")
	end
end