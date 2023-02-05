dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/archipelago/scripts/ap_utils.lua")

-- just putting this here for now in case I need it, can remove the flag later if it's not useful
GameAddFlagRun("spawned_timer_finished")
print("spawned timer finish script started")
if GlobalsGetValue("timer_first_load_done") ~= "1" then
    GlobalsSetValue("timer_first_load_done", "1")
    fully_heal() -- since on spawn, you get your extra max hp from previous runs but don't get healed for it
    print("spawned timer did it's job I think")
end