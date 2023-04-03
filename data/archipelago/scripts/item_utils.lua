dofile_once("data/archipelago/scripts/ap_utils.lua")

local item_table = dofile("data/archipelago/scripts/item_mappings.lua")
local AP = dofile("data/archipelago/scripts/constants.lua")
local Log = dofile("data/archipelago/scripts/logger.lua")

-- Traps
function BadTimes()
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
	elseif item.gold_amount ~= nil then
		add_money(item.gold_amount)
	elseif #item.items > 0 then
		local item_to_spawn = item.items[Random(1, #item.items)]
		EntityLoadAtPlayer(item_to_spawn)
		Log.Info("Item spawned" .. item_to_spawn)
	else
		Log.Error("[AP] Item " .. tostring(item_id) .. " not properly configured")
	end
end


function NGSpawnItems(item_list)
	local itemx = 595
	local itemy = -90
	local wandx = 600
	local wandy = -120
	local item_count = 0
	for _, v in pairs(item_list) do
		item_count = item_count + v
	end
	-- check how many hearts are on the list, increase your health based on them, then remove them from the list
	if item_list[110001] ~= nil then
		local cur_hp, max_hp = get_health()
		cur_hp = cur_hp + item_list[110001]
		max_hp = max_hp + item_list[110001]
		set_health(cur_hp, max_hp)
		item_list[110001] = nil
	end

	for item, quantity in pairs(item_list) do
		if item_table[item].wand ~= nil then
			-- spawn the wands in an array inside the cave
			for _ = 1, quantity do
				local item_to_spawn = item_table[item].items[Random(1, #item_table[item].items)]
				EntityLoad(item_to_spawn, wandx, wandy)
				wandx = wandx + 20
				if wandx >= 800 then
					wandx = 600
					wandy = wandy -10
				end
			end
			item_list[item] = nil
		
		elseif item == 110032 then
			-- spawn the map perk on the ground, in case it really distracts you
			perk_spawn(813, -90, item_table[item].perk)
			item_list[item] = nil
			
		elseif item_table[item].perk ~= nil then
			-- give the player their perks
			for _ = 1, quantity do
				give_perk(item_table[item].perk)
			end
			item_table[item] = nil
		else
			-- spawn the rest of the items on the cave floor
			for _ = 1, quantity do
				if #item_table[item].items > 0 then
					print("spawning" .. item .. "at" .. itemx .. itemy)
					local item_to_spawn = item_table[item].items[Random(1, #item_table[item].items)]
					EntityLoad(item_to_spawn, itemx, itemy)
					itemx = itemx + 15
					-- skip the minecart
					if itemx > 662 and itemx < 692 then
						itemx = itemx + 30
					end
					-- loop back around, but slightly offset
					if itemx >= 800 then
						itemx = itemx - 205
					end
				end
			end
			item_list[item] = nil
		end
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
