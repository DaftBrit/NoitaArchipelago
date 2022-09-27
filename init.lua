-- Copyright (c) 2022 DaftBrit
--
-- This software is released under the MIT License.
-- https://opensource.org/licenses/MIT

-- CREDITS:
-- Noita API wrapper (for requires) taken from Dadido3/noita-mapcap
-- pollnet library (for websocket implementation) probable-basilisk/pollnet
-- noita-ws-api (for reference and initial websocket setup) probable-basilisk/noita-ws-api
-- cheatgui (for reference) probable-basilisk/cheatgui
-- sqlite FFI ColonelThirtyTwo/lsqlite3-ffi

-- GLOBAL STUFF
local libPath = "mods/archipelago/files/libraries/"
dofile(libPath .. "noita-api/compatibility.lua")(libPath)
if not async then
	dofile_once("data/scripts/lib/coroutines.lua") -- Loads Noita's coroutines library from `data/scripts/lib/coroutines.lua`.
end
_G.item_check = 0

--LIBS
local pollnet = require("pollnet")
local sqlite = require("sqlite")

--CONF
dofile("mods/archipelago/files/conf/host.lua")

-- SCRIPTS
dofile("mods/archipelago/files/scripts/utils.lua")
dofile("mods/archipelago/files/scripts/json.lua")
dofile_once("data/scripts/lib/utilities.lua")

local chest_counter = 0
local Games = {}
local players = {}
local check_list = {}
local item_id_to_name = {}
local item_table = {
	["110000"] = "Bad Times",

	["110001"] = "data/entities/items/pickup/heart.xml",
	["110002"] = "data/entities/items/pickup/spell_refresh.xml",
	["110003"] = "data/entities/items/pickup/potion.xml",

	["110004"] = "data/entities/items/pickup/goldnugget_10.xml",
	["110005"] = "data/entities/items/pickup/goldnugget_50.xml",
	["110006"] = "data/entities/items/pickup/goldnugget_200.xml",
	["110007"] = "data/entities/items/pickup/goldnugget_1000.xml",

	["110008"] = "data/entities/items/wand_level_01.xml",
	["110009"] = "data/entities/items/wand_level_02.xml",
	["110010"] = "data/entities/items/wand_level_03.xml",
	["110011"] = "data/entities/items/wand_level_04.xml",
	["110012"] = "data/entities/items/wand_level_05.xml",
	["110013"] = "data/entities/items/wand_level_06.xml"
}

local sock = nil

local function BadTimes()
	--Function to spawn "Bad Times" events, uses the noita streaming integration system
	dofile("mods/archipelago/files/scripts/badtimes.lua")
	math.randomseed(os.time())
	local event_id = math.random(1, #streaming_events)
	for i,v in pairs( streaming_events ) do
		if i == event_id then
			local event_desc = v["id"]:gsub("_", " ")
			GamePrintImportant("BAD TIMES!!", event_desc)
			_streaming_run_event(v["id"])
			break
		end
	end
end

local function SendCmd(cmd, data)
	data = data or {}
	data["cmd"] = cmd

	local cmd_str = JSON:encode({data})
	print("SENT" .. cmd_str)
	sock:send(cmd_str)
end

local function InitSocket()
	if not sock then
		local PLAYERNAME = ModSettingGet("archipelago.slot_name")
		local PASSWD = ModSettingGet("archipelago.passwd") or ""
		local url = get_ws_host_url() -- comes from data/ws/host.lua
		if not url then return false end
		sock = pollnet.open_ws(url)
		SendCmd("Connect", {
			password = PASSWD,
			game = "Noita",
			name = PLAYERNAME,
			uuid = "NoitaClient",
			tags = { "AP", "WebHost" },
			version = { major = 0, minor = 3, build = 4, class = "Version" },
			items_handling = 1
		})
	end
end

function JSON:onDecodeError(message, text, location, etc)
	print(message)
end

local function GetNextMessage()
	local raw_msg = sock:last_message()
	if not raw_msg then return nil end

	--print(raw_msg)
	return JSON:decode(raw_msg)[1]
end

local function RecvMsgConnected(msg)
	SendCmd("Sync")
	GamePrint("Connected to Archipelago server")

	check_list = msg["missing_locations"]
	slot_number = msg["slot"]
	for k, plr in pairs(msg["players"]) do
		players[plr["slot"]] = plr["name"]
	end

	for key, val in pairs(msg["slot_info"]) do
		table.insert(Games, val["game"])
	end
	SendCmd("GetDataPackage", { games = Games })
end

local function RecvMsgReceivedItems(msg)
	--Item sync for items already sent
	if ModSettingGet("archipelago.redeliver_items") then
		for key, val in pairs(msg["items"]) do
			for i, p in ipairs(get_players()) do
				local x, y = EntityGetTransform(p)
				local item_id = msg["items"][key]["item"]
				local str_item_id = tostring(item_id)
				--Dont repeat bad events
				if item_table[str_item_id] ~= "Bad Times" then
					EntityLoad( item_table[str_item_id], x, y)
				end
			end
		end
	end
end

local function RecvMsgDataPackage(msg)
	for i, g in pairs(msg["data"]["games"]) do
		for item_name, item_id in pairs(msg["data"]["games"][i]["item_name_to_id"]) do
			item_id_to_name[tostring(item_id)] = item_name
		end
	end
end

local function RecvMsgPrintJSON(msg)
	if msg["type"] == "ItemSend" then
		local player = players[msg["item"]["player"]]
		--print("player "..player)
		local item_string = msg["data"][2]["text"]
		--print("item string"..item_string)
		local item_id = msg["data"][3]["text"]
		--print("item id "..item_id)
		local item_name = item_id_to_name[item_id]
		local player_to = players[msg["receiving"]]
		if item_string == " found their " then
			if item_table[item_id] ~= "Bad Times" then
				if player == PLAYERNAME or player_to == PLAYERNAME then
					--We only want popup messages for our items sent / received
					GamePrintImportant(item_name, player .. item_string .. item_name)
				else
					--Less important messaging in the bottom left
					GamePrint(player .. item_string .. item_name)
				end
			end
		end
		if item_string == " sent " then
			local item_string2 = msg["data"][4]["text"]
			if item_table[item_id] ~= "Bad Times" then
				if player == PLAYERNAME or player_to == PLAYERNAME then
					--We only want popup messages for our items sent / received
					GamePrintImportant(item_name, player .. item_string ..item_name .. item_string2 .. player_to)
				else
					--Less important messaging in the bottom left
					GamePrint(player .. item_string .. item_name .. item_string2 .. player_to)
				end
			end
		end
		-- Item Spawning
		if msg["receiving"] == slot_number then
			for i, p in ipairs(get_players()) do
				local x, y = EntityGetTransform(p)
				if item_table[item_id] == "Bad Times" then
					BadTimes()
				else
					EntityLoad( item_table[item_id], x, y)
				end
			end
		end
	end
end

local recv_msg_table = {
	["Connected"] = RecvMsgConnected,
	["ReceivedItems"] = RecvMsgReceivedItems,
	["DataPackage"] = RecvMsgDataPackage,
	["PrintJSON"] = RecvMsgPrintJSON
}

local function ProcessMsg(msg)
	local cmd = msg["cmd"]

	if recv_msg_table[cmd] then
		recv_msg_table[cmd](msg)
	else
		print("Unsupported command '" .. cmd .. "' received. " .. JSON:encode(msg))
	end
end

local function AsyncThread()
	while sock:poll() do
		-- Message read loop and variable set

		local msg = GetNextMessage()
		if msg then
			ProcessMsg(msg)

			if check_list[1] then
				next_item = check_list[1]
			end
		else
			wait(1)
		end

		-- Item check and message send
		if next_item then
			for i, p in ipairs(get_players()) do
				local x, y = EntityGetTransform(p)
				local radius = 15
				local pickup = EntityGetInRadiusWithTag( x, y, radius, "archipelago")
				if pickup[1] then
					SendCmd("LocationChecks", { locations = { next_item } })
					EntityKill( pickup[1] )
					table.remove(check_list, 1)
				end
			end
		end

		-- Spawn chest on X kills
		if ModSettingGet("archipelago.kill_count") > 0 then
			local kills = StatsGetValue("enemies_killed")
			local per_kill = math.floor(ModSettingGet("archipelago.kill_count"))
			local count = (kills / per_kill) - chest_counter
			for i, p in ipairs(get_players()) do
				local x, y = EntityGetTransform(p)
				if count == 1 then
					EntityLoad( "data/entities/items/pickup/chest_random.xml", x + 20, y )
					GamePrint(kills .. " kills spawned a chest")
					chest_counter = chest_counter + 1
				end
			end
		end
	end
end

function archipelago()
	-- main function wrapper
	InitSocket()
	if sock then
		async(AsyncThread)
	else
		print("Unable to establish Archipelago connection")
	end
end

function OnWorldPostUpdate()
	wake_up_waiting_threads(1)
end

function OnPlayerSpawned(player)
	local x, y = EntityGetTransform(player)
	EntityLoad( "data/entities/items/pickup/chest_random.xml", x + 20, y ) -- for testing
	EntityLoad( "data/entities/items/pickup/chest_random.xml", x + 40, y ) -- for testing
	EntityLoad( "data/entities/items/pickup/chest_random.xml", x + 60, y ) -- for testing
	EntityLoad( "data/entities/items/pickup/chest_random.xml", x + 80, y ) -- for testing
	EntityLoad( "data/entities/items/pickup/chest_random.xml", x + 100, y ) -- for testing
	archipelago()
end
