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
		dofile_once("data/scripts/lib/coroutines.lua")
		if not url then return false end
		GamePrint("trying to connect to " .. url)
		local sock = pollnet.open_ws(url)
		local PLAYERNAME = ModSettingGet("archipelago.slot_name")
		sock:send("[{\"cmd\":\"Connect\",\"password\":\"\",\"game\":\"Noita\",\"name\":\""..PLAYERNAME.."\",\"uuid\":\"NoitaClient\",\"tags\":[\"AP\",\"WebHost\"],\"version\":{\"major\":0,\"minor\":3,\"build\":4,\"class\":\"Version\"},\"items_handling\":1}]")
		async( function ()
			while sock:poll() do
				local msg = sock:last_message()
				if msg then
					print(msg)
				else
					wait(1)
				end
				if not _G.item_check == 0 then
					sock:send("[{\"cmd\":\"LocationChecks\",\"locations\":[".._G.item_check.."]}]")
					_G.item_check = 0
				end
			end
		end)
	end
end

function OnWorldPostUpdate()
	wake_up_waiting_threads(1)
end

function OnPlayerSpawned(player)
	local x, y = EntityGetTransform(player)
	EntityLoad( "data/entities/items/pickup/chest_random.xml", x + 20, y ) -- for testing
	archipelago()
end
