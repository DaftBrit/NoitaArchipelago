local entity_id = GetUpdatedEntityID()

if not GameHasFlagRun("ap_version_2") or GameHasFlagRun("ap_perk_reroll_available") then
	local all_perks = EntityGetWithTag("perk")
	if #all_perks > 0 then
		EntitySetComponentsWithTagEnabled(entity_id, "perk_reroll_disable", true)
	end
	EntitySetComponentsWithTagEnabled(entity_id, "locked_by_archipelago", false)
	EntityRemoveComponent(entity_id, GetUpdatedComponentID())
else
	EntitySetComponentsWithTagEnabled(entity_id, "perk_reroll_disable", false)
end
