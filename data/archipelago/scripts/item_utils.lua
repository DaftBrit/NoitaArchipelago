dofile_once("data/archipelago/scripts/ap_utils.lua")

local item_table = dofile("data/archipelago/scripts/item_mappings.lua")
local AP = dofile("data/archipelago/scripts/constants.lua")
local Log = dofile("data/archipelago/scripts/logger.lua")

-- Traps
local function BadTimes()
	--Function to spawn "Bad Times" events, uses the noita streaming integration system
	dofile("data/archipelago/scripts/ap_badtimes.lua")

	local event = streaming_events[Random(1, #streaming_events)]
	GamePrintImportant(event.ui_name, event.ui_description)
	_streaming_run_event(event.id)
end


function ResetOrbID()
	GlobalsSetValue("ap_orb_id", 20)
end


function SpawnItem(item_id, traps)
	Log.Info("item spawning shortly")
	local item = item_table[item_id]
	if item == nil then
		Log.Error("[AP] spawn_item: Item id " .. tostring(item_id) .. " does not exist!")
		return
	end

	SeedRandom()

	if item_id == AP.TRAP_ID then
		if not traps then return end
		BadTimes()
		Log.Info("Badtimes")
	elseif item.perk ~= nil then
		give_perk(item.perk)
		Log.Info("Perk spawned")
	elseif #item.items > 0 then
		local item_to_spawn = item.items[Random(1, #item.items)]
		EntityLoadAtPlayer(item_to_spawn)
		Log.Info("Item spawned" .. item_to_spawn)
	else
		Log.Error("[AP] Item " .. tostring(item_id) .. " not properly configured")
	end
end

local LocationFlags = {
	[110501] = "orb_0",
	[110502] = "orb_1",
	[110503] = "orb_2",
	[110504] = "orb_3",
	[110505] = "orb_4",
	[110506] = "orb_5",
	[110507] = "orb_6",
	[110508] = "orb_7",
	[110509] = "orb_8",
	[110510] = "orb_9",
	[110511] = "orb_10",

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

function CheckLocationFlags()
	local locations_checked = {}
	for location_id, flag in pairs(LocationFlags) do
		if GameHasFlagRun(flag) then
			table.insert(locations_checked, location_id)
			GameRemoveFlagRun(flag)
		end
	end
	if #locations_checked > 0 then
		SendCmd("LocationChecks", { locations = locations_checked })
	end
end
