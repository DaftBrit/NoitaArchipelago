-- This file exists so that mods can conveniently override it to 
-- change the URL that ws-api attempts to connect to
HOST = ModSettingGet("archipelago.server_address")
PORT = ModSettingGet("archipelago.server_port")

WS_HOST_URL = "ws://"..HOST..":"..PORT

function get_ws_host_url()
  return WS_HOST_URL
end