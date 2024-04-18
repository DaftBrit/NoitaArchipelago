print("kivi function called")

local function APKiviDeath()
    local ap_old_kivi_death = death

    death = function(damage_type_bit_field, damage_message, entity_thats_responsible, drop_items)
        print("kivi dead")
        GameAddFlagRun("ap_kivi_is_dead")
        ap_old_kivi_death(damage_type_bit_field, damage_message, entity_thats_responsible, drop_items)
    end
end

APKiviDeath()
