dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/archipelago/scripts/ap_utils.lua")


GameAddFlagRun("ap_spawned_timer_finished")
GlobalsSetValue("AP_FIRST_LOAD_DONE", "1")
if GlobalsGetValue("ap_timer_first_load_done") ~= "1" then
    GlobalsSetValue("ap_timer_first_load_done", "1")
    fully_heal() -- since on spawn, you get your extra max hp from previous runs but don't get healed for it
end