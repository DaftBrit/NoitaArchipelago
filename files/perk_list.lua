function remove_from_pool(perk_name)
	local key_to_perk = nil
	for key,perk in pairs(perk_list) do
		if (perk.id == perk_name) then
--			key_to_perk = key
			perk.not_in_default_perk_pool = true
		end
	end
end

remove_from_pool("PROTECTION_ELECTRICITY")
remove_from_pool("PROTECTION_MELEE")
remove_from_pool("PROTECTION_RADIOACTIVITY")
remove_from_pool("PROTECTION_FIRE")
remove_from_pool("PROTECTION_EXPLOSION")