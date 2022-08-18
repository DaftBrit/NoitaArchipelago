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

function archipelago()
	if not sock then
		local url = get_ws_host_url() -- comes from data/ws/host.lua
		--dofile_once("data/scripts/lib/coroutines.lua")
		if not url then return false end
		GamePrint("trying to connect to " .. url)
		sock = pollnet.open_ws(url)
		local PLAYERNAME = ModSettingGet("archipelago.slot_name")
		local PASSWD = ModSettingGet("archipelago.passwd") or ""
		sock:send("[{\"cmd\":\"Connect\",\"password\":\""..PASSWD.."\",\"game\":\"Noita\",\"name\":\""..PLAYERNAME.."\",\"uuid\":\"NoitaClient\",\"tags\":[\"AP\",\"WebHost\"],\"version\":{\"major\":0,\"minor\":3,\"build\":4,\"class\":\"Version\"},\"items_handling\":1}]")
		async( function ()
			while sock:poll() do
				local raw_msg = sock:last_message()
				if raw_msg then
					print(raw_msg)
					raw_msg = raw_msg:sub(2)
					raw_msg = raw_msg:sub(1,-2)
					local msg = JSON:decode(raw_msg)
					--print(raw_msg)
					if msg["cmd"] == "Connected" then
						GamePrint("Connected to Archipelago server")
						check_list = msg["missing_locations"]
					end
					if check_list[1] then
						next_item = check_list[1]
					end
				else
					wait(1)
				end
			end
		end)
	end
end
function item_check()
	async( function()
		while sock:poll() do
			if next_item then
				local x, y = EntityGetTransform(global_player)
				local radius = 15
				--print(x.." "..y)
				local pickup = EntityGetInRadiusWithTag( x, y, radius, "archipelago")
				if pickup[1] then
					sock:send("[{\"cmd\":\"LocationChecks\",\"locations\":["..next_item.."]}]")
					EntityKill( pickup[1] )
					table.remove(check_list,1)
					next_item = nil
				else
					wait(1)
				end
			else
				wait(1)
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
	item_check()
end
