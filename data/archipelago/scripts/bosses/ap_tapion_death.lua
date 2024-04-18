print("tapion function called")
local ap_old_tapion_death = death

death = function(damage_type_bit_field, damage_message, entity_thats_responsible, drop_items)
    print("tapion death worked")
    GameAddFlagRun("ap_tapion_is_dead")
    ap_old_tapion_death(damage_type_bit_field, damage_message, entity_thats_responsible, drop_items)
end
