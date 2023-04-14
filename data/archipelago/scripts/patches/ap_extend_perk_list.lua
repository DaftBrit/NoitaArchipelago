local function ap_extend_perk_list()
	local function remove_from_pool(perk_name)
		for _, perk in pairs(perk_list) do
			if (perk.id == perk_name) then
				perk.not_in_default_perk_pool = true
			end
		end
	end

	remove_from_pool("PROTECTION_ELECTRICITY")
	remove_from_pool("PROTECTION_MELEE")
	remove_from_pool("PROTECTION_RADIOACTIVITY")
	remove_from_pool("PROTECTION_FIRE")
	remove_from_pool("PROTECTION_EXPLOSION")
	remove_from_pool("EDIT_WANDS_EVERYWHERE")
	remove_from_pool("REMOVE_FOG_OF_WAR")
end

ap_extend_perk_list()
