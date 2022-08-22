-- Copyright (c) 2022 DaftBrit
--
-- This software is released under the MIT License.
-- https://opensource.org/licenses/MIT

-- CREDITS:
-- Noita API wrapper (for requires) taken from Dadido3/noita-mapcap
-- pollnet library (for websocket implementation) probable-basilisk/pollnet
-- noita-ws-api (for reference and initial websocket setup) probable-basilisk/noita-ws-api
-- cheatgui (for reference) probable-basilisk/cheatgui

-- GLOBAL STUFF
local libPath = "mods/archipelago/files/libraries/"
dofile(libPath .. "noita-api/compatibility.lua")(libPath)
if not async then
	dofile_once("data/scripts/lib/coroutines.lua") -- Loads Noita's coroutines library from `data/scripts/lib/coroutines.lua`.
end
_G.item_check = 0

--LIBS
pollnet = require("pollnet")

--CONF
dofile("mods/archipelago/files/conf/host.lua")

-- SCRIPTS
dofile("mods/archipelago/files/scripts/utils.lua")
dofile("mods/archipelago/files/scripts/json.lua")

Games = {}
players = {}
check_list = {}
item_id_to_name = {}
item_table = {}
item_table["110000"] = "Bad Times"
item_table["110001"] = "data/entities/items/pickup/heart.xml"
item_table["110002"] = "data/entities/items/pickup/spell_refresh.xml"
item_table["110003"] = "data/entities/items/pickup/goldnugget_50.xml"
item_table["110004"] = "data/entities/items/wand_level_01.xml"
item_table["110005"] = "data/entities/items/pickup/potion.xml"

local function BadTimes()
	--Function to spawn "Bad Times" events, uses the noita streaming integration system
	dofile("mods/archipelago/files/scripts/badtimes.lua")
	math.randomseed(os.time())
	local event_id = math.random(1, #streaming_events)
	print (event_id)
	for i,v in pairs( streaming_events ) do
		if i == event_id then
			print(v["id"])
			local event_desc = v["id"]:gsub("_", " ")
			GamePrintImportant("BAD TIMES!!", event_desc)
			_streaming_run_event(v["id"])
			break
		end
	end
end

function archipelago()
	-- main function wrapper
	if not sock then
		local PLAYERNAME = ModSettingGet("archipelago.slot_name")
		local PASSWD = ModSettingGet("archipelago.passwd") or ""
		local url = get_ws_host_url() -- comes from data/ws/host.lua
		if not url then return false end
		sock = pollnet.open_ws(url)
		conn = sock:send("[{\"cmd\":\"Connect\",\"password\":\""..PASSWD.."\",\"game\":\"Noita\",\"name\":\""..PLAYERNAME.."\",\"uuid\":\"NoitaClient\",\"tags\":[\"AP\",\"WebHost\"],\"version\":{\"major\":0,\"minor\":3,\"build\":4,\"class\":\"Version\"},\"items_handling\":1}]")
	end
	async( function ()
		while sock:poll() do
			-- Message read loop and variable set
			raw_msg = sock:last_message()
			if raw_msg then
				--print(raw_msg)
				msg = JSON:decode(raw_msg)
				function JSON:onDecodeError(message, text, location, etc)
					print(message)
				end
				if msg[1]["cmd"] == "Connected" then
					GamePrint("Connected to Archipelago server")
					check_list = msg[1]["missing_locations"]
					slot_number = msg[1]["slot"]
					for k, v in pairs(msg[1]["players"]) do
						players[v["slot"]] = v["name"]
					end
					for key, val in pairs(msg[1]["slot_info"]) do
						table.insert(Games,val["game"])
					end
					local games_json = JSON:encode(Games)
					print(games_json)
					sock:send("[{\"cmd\":\"GetDataPackage\",\"games\":"..games_json.."}]")
				end
				if msg[2] then
					if msg[2]["cmd"] == "ReceivedItems" then
						print("This is where we can deliver already collected items")
					end
				end
				-- Map dataset
				if msg[1]["cmd"] == "DataPackage" then
					for i, g in pairs(msg[1]["data"]["games"]) do
						for item_name, item_id in pairs(msg[1]["data"]["games"][i]["item_name_to_id"]) do
							item_id_to_name[tostring(item_id)] = item_name
						end
					end
				end
				-- Player messaging
				if msg[1]["cmd"] == "PrintJSON" and msg[1]["type"] == "ItemSend" then
					local player = players[msg[1]["item"]["player"]]
					--print("player "..player)
					local item_string = msg[1]["data"][2]["text"]
					--print("item string"..item_string)
					local item_id = msg[1]["data"][3]["text"]
					--print("item id "..item_id)
					local item_name = item_id_to_name[item_id]
					local player_to = players[msg[1]["receiving"]]
					if item_string == " found their " then
						GamePrint(player..item_string..item_name)
					end
					if item_string == " sent " then
						local item_string2 = msg[1]["data"][4]["text"]
						GamePrint(player..item_string..item_name..item_string2..player_to)
					end
					-- Item Spawning
					if msg[1]["receiving"] == slot_number then
						local x, y = EntityGetTransform(global_player)
						if item_table[item_id] == "Bad Times" then
							BadTimes()
						else
							EntityLoad( item_table[item_id], x + 10, y - 10 )
						end
					end
				end
				if check_list[1] then
					next_item = check_list[1]
				end
			else
				wait(1)
			end
			-- Item check and message send
			if next_item then
				local x, y = EntityGetTransform(global_player)
				local radius = 15
				local pickup = EntityGetInRadiusWithTag( x, y, radius, "archipelago")
				if pickup[1] then
					sock:send("[{\"cmd\":\"LocationChecks\",\"locations\":["..next_item.."]}]")
					EntityKill( pickup[1] )
					table.remove(check_list,1)
				end
			end
		end
	end)
end
function OnWorldPostUpdate()
	wake_up_waiting_threads(1)
end
function OnPlayerSpawned(player)
	global_player = player
	local x, y = EntityGetTransform(player)
	EntityLoad( "data/entities/items/pickup/chest_random.xml", x + 20, y ) -- for testing
	EntityLoad( "data/entities/items/pickup/chest_random.xml", x + 40, y ) -- for testing
	EntityLoad( "data/entities/items/pickup/chest_random.xml", x + 60, y ) -- for testing
	EntityLoad( "data/entities/items/pickup/chest_random.xml", x + 80, y ) -- for testing
	EntityLoad( "data/entities/items/pickup/chest_random.xml", x + 100, y ) -- for testing
	archipelago()
end
