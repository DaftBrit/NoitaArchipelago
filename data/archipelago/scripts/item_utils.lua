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
	[110023] = false,
	[110024] = false,
	[110025] = true,
	[110026] = true,
	[110027] = true,
	[110028] = true,
	[110029] = true,
	[110030] = true,
	[110031] = true,
	[110032] = true,
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


function ResetOrbID()
	GlobalsSetValue("ap_orb_id", 20)
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


local BossLocations = {
	[110600] = "kolmi_is_dead",
	[110610] = "maggot_is_dead",
	[110620] = "dragon_is_dead",
	[110630] = "koipi_is_dead",
	[110640] = "squidward_is_dead",
	[110650] = "leviathan_is_dead",
	[110660] = "triangle_is_dead",
	[110670] = "skull_is_dead",
	[110680] = "friend_is_dead",
	[110690] = "mestari_is_dead",
	[110700] = "alchemist_is_dead",
	[110710] = "mecha_is_dead",
}


function CheckBossLocations()
	for num, boss in pairs(BossLocations) do
		if GameHasFlagRun(boss) then
			SendCmd("LocationChecks", { locations = {num,}})
			GameRemoveFlagRun(boss)
		end
	end
end