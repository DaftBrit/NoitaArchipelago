dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/archipelago/scripts/ap_utils.lua")

local LOAD_KEY = "timer_first_load_done"
-- just putting this here for now in case I need it, can remove the flag later if it's not useful
GameAddFlagRun("spawned_timer_finished")
if GlobalsGetValue(LOAD_KEY) ~= "1" then
    GlobalsSetValue(LOAD_KEY, "1")
    fully_heal() -- since on spawn, you get your extra max hp from previous runs but don't get healed for it
end