---@meta

--
-- lua-apclientpp API definition file.
-- Do NOT load/require this file.
-- Read README.md for instructions.
--

---@class APClient
APClient = {}

---Version string (ma.mi.re) of the apclientpp version used to build this lua-apclientpp.
---@type string
APClient._VERSION = "0.6.4"


-- Functions --

---Instantiate APClient and connect to server.
---@param uuid string a string identifying connection or `""`
---@param game string name of the game this client will connect for
---@param host string URL or `host:port` to connect to
---@return APClient
function APClient.__call(uuid, game, host) end


-- Methods --

---Call this repeatedly (e.g. once per frame) to handle network communication.
---This will call registered callbacks/handlers.
function APClient:poll() end

---Clear state and reconnect on next Poll().
function APClient:reset() end

---Get display name for player number.
---@param slot integer player number
---@return string player name or alias
function APClient:get_player_alias(slot) end

---Get game name for player number.
---@param slot integer player number
---@return string game
function APClient:get_player_game(slot) end

---Get currently played game.
---@return string game
function APClient:get_game() end

---Get name of location from ID.
---@param code integer ID of the location
---@param game string? game the location ID is from; use nil for own location
---@return string name of the location
function APClient:get_location_name(code, game) end

---Get ID of location from name (local player's game only).
---@param name string location name
---@return integer ID of the location
function APClient:get_location_id(name) end

---Get name of item from ID.
---@param code integer ID of the item
---@param game string? game the item ID is from; use nil for own item
---@return string name of the item
function APClient:get_item_name(code, game) end

---Get name of item from ID (local player's game only).
---@param name string item name
---@return integer ID of the item
function APClient:get_item_id(name) end

---Convert PrintJson json structure to readable string.
---@param json table message data as passed into print_json handler
---@param format renderformat
---@return string text representation of the message
function APClient:render_json(json, format) end

---Get current (connection) state of client.
---@return state state
function APClient:get_state() end

---Get seed of currently connected game
---@return string seed name or "" if not connected
function APClient:get_seed() end

---Get currently connected slot name.
---@return string slot name
function APClient:get_slot() end

---Get (player) number of connected slot.
---@return integer slot number or -1 if not connected
function APClient:get_player_number() end

---Get team number of connected slot.
---@return integer team number or -1 if not connected
function APClient:get_team_number() end

---Get hint points of connected slot.
---@return integer hint points currently available
function APClient:get_hint_points() end

---Get cost for a single hint in points.
---@return integer hint cost or 0 if not connected
function APClient:get_hint_cost_points() end

---Get cost for a single hint in percent of locations.
---@return integer hint cost or 0 if not connected
function APClient:get_hint_cost_percent() end

---Get status of data package. Before data package is valid, some operations (ID to name) may not work.
---@return boolean true if the data package is complete.
function APClient:is_data_package_valid() end

---Get estimated floating point unix timestamp of server. May be used for bounce.
---@return number timestamp
function APClient:get_server_time() end

---Get list of players of connected game.
---@return NetworkPlayer[]
function APClient:get_players() end

---Get map of permissions.
---@return {[string]: permission}
function APClient:get_permissions() end

---Get value of a permission or nil if unknown.
---@param key string
---@return permission?
function APClient:get_permission(key) end


-- Member variables --

---List of already checked location IDs.
---@type integer[]
APClient.checked_locations = {}

---Get list of missing (not yet checked) location IDs.
---@type integer[]
APClient.missing_locations = {}


-- Handlers --

---Callback will be called when the network connection was established.
---@param callback fun():nil
function APClient:set_socket_connected_handler(callback) end

---Callback will be called when connecting resulted in an error on network level.
---Sometimes errors are expected and APClient will automatically retry.
---Only use this for debugging and use timeout logic to detect actual connect errors.
---@param callback fun(reason:string):nil
function APClient:set_socket_error_handler(callback) end

---Callback will be called when the network connection was closed.
---@param callback fun():nil
function APClient:set_socket_disconnected_handler(callback) end

---Callback will be called when RoomInfo was received. Also use this to cancel any connect timeouts.
---@param callback fun():nil
function APClient:set_room_info_handler(callback) end

---Callback will be called when ConnectSlot succeeded.
---@param callback fun(slot_data:{[string]: any}):nil
function APClient:set_slot_connected_handler(callback) end

---Callback will be called when ConnectSlot failed.
---@param callback fun(reasons:string[]):nil
function APClient:set_slot_refused_handler(callback) end

---Callback will be called when items were received. Use item.index to see which are new.
---@param callback fun(items:NetworkItem[]):nil
function APClient:set_items_received_handler(callback) end

---Callback will be called when locations were scouted.
---@param callback fun(items:NetworkItem[]):nil
function APClient:set_location_info_handler(callback) end

---Callback will be called when locations were checked (e.g. a different player connected to the same slot).
---@param callback fun(locations:integer[]):nil
function APClient:set_location_checked_handler(callback) end

---Callback will be called when data package changed (was updated). Use is_data_package_valid to see if this was the final update.
---@param callback fun(data_package:{[string]: any}):nil
function APClient:set_data_package_changed_handler(callback) end

---Callback will be called when a legacy print message was received. This should not happen anymore.
---@param callback fun(message:string):nil
function APClient:set_print_handler(callback) end

---Callback will be called when a PrintJSON message was received.
---Use `render_json(data)` to get a human readable version.
---`command` is the complete command and can be used to filter messages.
---@param callback fun(data:{[string]: any}, command:{[string]: any}):nil
function APClient:set_print_json_handler(callback) end

---Callback will be called when a Bounced message was received.
---@param callback fun(command:{[string]: any}):nil
function APClient:set_bounced_handler(callback) end

---Callback will be called as response to Get.
---`data` is a key-value table for the requested keys.
---`keys` is the list of the requested keys. This is required because keys will not be existent in data for `nil` values.
---`command` is the raw command including `extra`.
---@param callback fun(data:{[string]: any}, keys:string[], command:{[string]: any})
function APClient:set_retrieved_handler(callback) end

---Callback will be called as response to Set.
---@param callback fun(command:{[string]:any}):nil
function APClient:set_set_reply_handler(callback) end


-- Commands --

---Send chat message.
---@param text string
---@return boolean true if message was queued
function APClient:Say(text) end

---Connect to a slot.
---@param name string name of the slot to connect
---@param password string
---@param items_handling ItemsHandling describes which items to receive from the server
---@param tags string[]? optional list of tags to use, e.g. `{"DeathLink"}`
---@param version integer[]? optional client version in the format of `{major, minor, build}`, e.g. `{0, 5, 0}`
---@return boolean true if connect was queued, false if state was invalid
function APClient:ConnectSlot(name, password, items_handling, tags, version) end

---Update a connection.
---@param items_handling? ItemsHandling Unchanged if `nil`. See ConnectSlot.
---@param tags string[]? Unchanged if `nil`. See ConnectSlot.
---@return boolean true if update was queued, false if state was invalid
---@see APClient.ConnectSlot
function APClient:ConnectUpdate(items_handling, tags) end

---Ask server for all items again, resulting in ReceivedItems starting at 0.
---@return boolean true if message was queued
function APClient:Sync() end

---Send Bounce message to games, slots or tags. Will result in Bounced.
---@param data {[string]: any} data to be sent
---@param games string[]? optional list of games to send to
---@param slots integer[]? optional list of slots to send to
---@param tags string[]? optional list of tags to send to
---@return boolean true if message was queued
function APClient:Bounce(data, games, slots, tags) end

---Send status update to the server. Use this to report goal completion to the server.
---@param status clientstatus
---@return boolean true if message was queued
function APClient:StatusUpdate(status) end

---Report locations as checked/looted to the server.
---@param locations integer[] location IDs that were checked.
---@return boolean true if message was queued
function APClient:LocationChecks(locations) end

---Query the server for location details. Server will send LocationInfo asynchronously. 
---@param locations integer[] location IDs to be scouted
---@param create_as_hint CreateAsHint?
---@return boolean true if message was queued
function APClient:LocationScouts(locations, create_as_hint) end

---Sends UpdateHint to the server to update hint status/priority.
---@param player integer owner of the location
---@param location integer location ID to be hinted
---@param status hintstatus status/priority of the hint
---@return boolean true if message was queued
function APClient:UpdateHint(player, location, status) end

---Sends CreateHints to the server, if supported, to create hints with optional status/priority.
---@param locations integer[] location IDs to be hinted
---@param target_player integer? owner of the locations, or nil or -1 for current player
---@param status hintstatus? status/priority of the hints, or nil for default (HINT_UNSPECIFIED)
---@return boolean true if message was queued, false if unsupported
function APClient:CreateHints(locations, target_player, status) end

---Query the server for keys in data storage. Server will asynchronously reply with Retrieved.
---@param keys string[] keys to query
---@param extra {[string]: any}? Additional data to send in the command. Will be included in Retrieved. 
---@return boolean true if message was queued
function APClient:Get(keys, extra) end

---Listen to changes of keys in data storage. Server will send SetReply when they change.
---@param keys string[] keys to watch
---@return boolean true if message was queued
function APClient:SetNotify(keys) end

---Set a value in data storage. Server will send SetReply to all connections listening for changes.
---@param key string key to change the value for
---@param default any default value if not set yet
---@param want_reply boolean true to receive SetReply without SetNotify
---@param operations {[string]: any}[] operations to change value
---@param extra {[string]: any}? Additional data to send in the command. Will be included in SetReply.
---@return boolean true if message was queued
function APClient:Set(key, default, want_reply, operations, extra) end


-- Helper types and enums --

---@enum clientstatus
APClient.ClientStatus = {
    UNKNOWN = 0,
    READY = 10,
    PLAYING = 20,
    GOAL = 30,
}

---@enum renderformat
APClient.RenderFormat = {
    TEXT = 0,
    HTML = 1,
    ANSI = 2,
}

---@enum itemflags
APClient.ItemFlags = {
    FLAG_NONE = 0,
    FLAG_ADVANCEMENT = 1,
    FLAG_NEVER_EXCLUDE = 2,
    FLAG_TRAP = 4,
}

---@enum state
APClient.State = {
    DISCONNECTED = 0,
    SOCKET_CONNECTING = 1,
    SOCKET_CONNECTED = 2,
    ROOM_INFO = 3,
    SLOT_CONNECTED = 4,
}

---@enum permission
APClient.Permission = {
    DISABLED = 0,     -- Completely disables access
    ENABLED = 1,      -- Allows manual use
    GOAL = 2,         -- Allows manual use after goal completion
    FORCED = 4,       -- Forces usage
    AUTO = 6,         -- Forces use after goal completion, only works for release and collect
    AUTO_ENABLED = 7, -- Forces use after goal completion, allows manual use any time
}

---@enum hintstatus
APClient.HintStatus = {
    HINT_UNSPECIFIED = 0,  -- The receiving player has not specified any status
    HINT_NO_PRIORITY = 10, -- The receiving player has specified that the item is unneeded
    HINT_AVOID = 20,       -- The receiving player has specified that the item is detrimental
    HINT_PRIORITY = 30,    -- The receiving player has specified that the item is needed
    HINT_FOUND = 40,       -- The location has been collected. Status cannot be changed once found.
}

---@alias ItemsHandling integer
---| 0 # No ReceivedItems is sent to you, ever.
---| 1 # Indicates you get items sent from other worlds.
---| 3 # Indicates you get items sent from your own world and other worlds.
---| 5 # Indicates you get your starting inventory and items from other worlds sent.
---| 7 # Indicates you get your starting inventory, your own items and items from other worlds sent.

---@alias CreateAsHint boolean|integer
---| 0 # do not create a hint
---| 1 # create a hint for the scouted location(s)
---| 2 # create a hint, but only broadcast new hints
---| false # same as 0
---| true # same as 1

---Special type to represent empty array.
---@class LuaJson_EmptyArray
---@see APClient.EMPTY_ARRAY
LuaJson_EmptyArray = {}

---Special object to represent an empty array/list (since {} is an empty table/dict/object)
---@type LuaJson_EmptyArray
APClient.EMPTY_ARRAY = {}

---@class NetworkPlayer
---@field team integer
---@field slot integer
---@field alias string
---@field name string

---@class NetworkItem
---@field item integer item id of the item
---@field location integer location id of the item inside the world
---@field player integer player slot of the world the item is located in, except for Scout/LocationInfo, where it's the receiver
---@field flags itemflags bit flags for item classification
---@field index integer? for ReceivedItems this can be used to detect new/old items


-- Dirty hack to make __call work as constructor --

APClient = APClient.__call


return APClient
