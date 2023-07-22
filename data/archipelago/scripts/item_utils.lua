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


function GivePlayerOrbsOnSpawn(orb_count)
	if orb_count > 0 then
		local fake_orb_entity = EntityLoadAtPlayer("data/archipelago/entities/items/orbs/fake_orb.xml")
		if GameHasFlagRun("ap_peaceful_goal") and orb_count > 33 then
			orb_count = 33
		elseif GameHasFlagRun("ap_pure_goal") and orb_count > 11 then
			orb_count = 11
		end
		if fake_orb_entity ~= nil then
			for i = 1, orb_count do
				EntityAddComponent2(fake_orb_entity, "OrbComponent", {orb_id = i + 20})
			end
		end
	end
end


function SpawnItem(item_id, traps)
	Log.Info("item spawning shortly")
	local item = item_table[item_id]
	if item == nil then
		Log.Error("[AP] spawn_item: Item id " .. tostring(item_id) .. " does not exist!")
		return
	end
	-- setting the random seed using arbitrary offsets that get modified on each spawn
	local rand_x = GlobalsGetValue("ap_random_hax")
	local rand_y = rand_x * 2
	SeedRandom(rand_x, rand_y)

	if item_id == AP.TRAP_ID then
		if not traps then return end
		BadTimes()
		GlobalsSetValue("ap_random_hax", rand_x + 2)
		Log.Info("Badtimes")
	elseif item.perk ~= nil then
		give_perk(item.perk)
		Log.Info("Perk spawned")
	elseif item.gold_amount ~= nil then
		add_money(item.gold_amount)
	elseif item.potion ~= nil then
		spawn_potion(item.items[1])
		GlobalsSetValue("ap_random_hax", rand_x + 2)
	elseif item.orb ~= nil then
		local orb_count = GameGetOrbCountThisRun()
		if GameHasFlagRun("ap_peaceful_goal") and orb_count >= 33 or GameHasFlagRun("ap_pure_goal") and orb_count >= 11 then
			EntityLoadAtPlayer("data/entities/items/pickup/heart.xml")
		else
			EntityLoadAtPlayer(item.items[1])
		end
	elseif #item.items > 0 then
		local item_to_spawn = item.items[Random(1, #item.items)]
		EntityLoadAtPlayer(item_to_spawn, random_offset())
		GlobalsSetValue("ap_random_hax", rand_x + 2)
		Log.Info("Item spawned" .. item_to_spawn)
	else
		Log.Error("[AP] Item " .. tostring(item_id) .. " not properly configured")
	end
end

local ng_spawn_check
function NGSpawnItems(item_counts)
	if ng_spawn_check ~= true then
		ng_spawn_check = true
		print("spawning items in mountain using NGSpawnItems")
	end
	local itemx = 595
	local itemy = -90
	local wandx = 600
	local wandy = -120
	-- check how many hearts and orbs are on the list, increase your health, then remove them from the list
	-- note that health increases are in increments of 25
	if item_counts[AP.HEART_ITEM_ID] ~= nil or item_counts[AP.ORB_ITEM_ID] ~= nil then
		local heart_amt = item_counts[AP.HEART_ITEM_ID] or 0
		local orb_amt = item_counts[AP.ORB_ITEM_ID] or 0
		GivePlayerOrbsOnSpawn(orb_amt)
		add_cur_and_max_health(heart_amt + orb_amt)
		item_counts[AP.HEART_ITEM_ID] = nil
		item_counts[AP.ORB_ITEM_ID] = nil
	end

	for item, quantity in pairs(item_counts) do
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
			item_counts[item] = nil
		
		elseif item == AP.MAP_PERK_ID then
			-- spawn the map perk on the ground, in case you find it distracting
			perk_spawn(813, -96, item_table[item].perk)
			item_counts[item] = nil
			
		elseif item_table[item].perk ~= nil then
			-- give the player their perks
			for _ = 1, quantity do
				give_perk(item_table[item].perk)
			end
			item_table[item] = nil
		elseif item ~= AP.TRAP_ID then
			-- spawn the rest of the items on the cave floor
			for _ = 1, quantity do
				if #item_table[item].items > 0 then
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
			item_counts[item] = nil
		end
	end
end


local LocationFlags = {
	[110658] = "ap_orb_0", -- Floating Island
	[110659] = "ap_orb_1", -- Pyramid
	[110660] = "ap_orb_2", -- Frozen Vault
	[110661] = "ap_orb_3", -- Lava Lake
	[110662] = "ap_orb_4", -- Sandcave
	[110663] = "ap_orb_5", -- Magical Temple
	[110664] = "ap_orb_6", -- Lukki Lair
	[110665] = "ap_orb_7", -- Abyss
	[110666] = "ap_orb_8", -- Hell
	[110667] = "ap_orb_9", -- Snow Chasm
	[110668] = "ap_orb_10", -- Wizard's Den

	[111327] = "ap_orb_128", -- West Floating Island
	[111328] = "ap_orb_129", -- West Pyramid
	[111329] = "ap_orb_130", -- West Frozen Vault
	-- no lava lake orb in PWs
	[111331] = "ap_orb_132", -- West Sandcave
	[111332] = "ap_orb_133", -- West Magical Temple
	[111333] = "ap_orb_134", -- West Lukki Lair
	[111334] = "ap_orb_135", -- West Abyss
	[111335] = "ap_orb_136", -- West Hell
	[111336] = "ap_orb_137", -- West Snow Chasm
	[111337] = "ap_orb_138", -- West Wizard's Den

	[111996] = "ap_orb_256", -- East Floating Island
	[111997] = "ap_orb_257", -- East Pyramid
	[111998] = "ap_orb_258", -- East Frozen Vault
	-- no lava lake orb in PWs
	[112000] = "ap_orb_260", -- East Sandcave
	[112001] = "ap_orb_261", -- East Magical Temple
	[112002] = "ap_orb_262", -- East Lukki Lair
	[112003] = "ap_orb_263", -- East Abyss
	[112004] = "ap_orb_264", -- East Hell
	[112005] = "ap_orb_265", -- East Snow Chasm
	[112006] = "ap_orb_266", -- East Wizard's Den

	[110646] = "ap_kolmi_is_dead",
	[110647] = "ap_maggot_is_dead",
	[110648] = "ap_dragon_is_dead",
	[110649] = "ap_koipi_is_dead",
	[110650] = "ap_squidward_is_dead",
	[110651] = "ap_leviathan_is_dead",
	[110652] = "ap_triangle_is_dead",
	[110653] = "ap_skull_is_dead",
	[110654] = "ap_friend_is_dead",
	[110655] = "ap_mestari_is_dead",
	[110656] = "ap_alchemist_is_dead",
	[110657] = "ap_mecha_is_dead",
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
