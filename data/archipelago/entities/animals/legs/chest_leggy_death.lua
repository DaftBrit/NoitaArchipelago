local Noita = dofile_once("data/archipelago/lib/noita.lua")

function death( damage_type_bit_field, damage_message, entity_thats_responsible, drop_items )
	local entity_id    = GetUpdatedEntityID()
	local pos_x, pos_y = EntityGetTransform( entity_id )

	Noita.SpawnPerk(pos_x, pos_y, "AP_LEGGY_FEET")
end
