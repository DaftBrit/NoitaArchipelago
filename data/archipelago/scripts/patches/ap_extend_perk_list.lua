dofile_once("data/scripts/lib/utilities.lua") -- component_readwrite
dofile_once("data/scripts/perks/perk_utilities.lua")

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
remove_from_pool("RESPAWN")
remove_from_pool("MEGA_BEAM_STONE")

--[[ For future use
remove_from_pool("EXTRA_PERK")
remove_from_pool("SAVING_GRACE")
remove_from_pool("TRICK_BLOOD_MONEY")
remove_from_pool("NO_MORE_KNOCKBACK")
remove_from_pool("MANA_FROM_KILLS")
remove_from_pool("RADAR_ENEMY")
remove_from_pool("IRON_STOMACH")
remove_from_pool("WAND_RADAR")
remove_from_pool("ITEM_RADAR")
remove_from_pool("ADVENTURER")
remove_from_pool("ABILITY_ACTIONS_MATERIALIZED")
remove_from_pool("UNLIMITED_SPELLS")
]]

table.insert(perk_list, {
	id = "AP_LEGGY_FEET",
	ui_name = "$perk_ap_leggy_feet",
	ui_description = "$perkdesc_ap_leggy_feet",
	ui_icon = "data/archipelago/entities/items/icons/ap_leggy_feet_perk_ui_icon.png",
	perk_icon = "data/archipelago/entities/items/icons/ap_leggy_feet_perk_icon.png",
	stackable = STACKABLE_YES,
	stackable_is_rare = true,
	usable_by_enemies = true,
	not_in_default_perk_pool = true,
	func = function( entity_perk_item, entity_who_picked, item_name, pickup_count )
		local x, y = EntityGetTransform( entity_who_picked )
		local child_id
		local is_stacking = GameHasFlagRun( "AP_ATTACK_FOOT_CLIMBER" )

		local function add_leg(identifier)
			local leg_child_id = EntityLoad("data/archipelago/entities/animals/legs/chest_limb_" .. identifier .. ".xml", x, y)
			EntityAddComponent2(leg_child_id, "InheritTransformComponent")
			local walker_id = EntityGetFirstComponent(leg_child_id, "IKLimbWalkerComponent")
			ComponentSetValue2(walker_id, "affect_flying", true)
			EntityAddTag(leg_child_id, "perk_entity")
			EntityAddTag(leg_child_id, "ap_leggy_foot_walker")
			EntityAddChild(entity_who_picked, leg_child_id)
		end

		child_id = EntityLoad( "data/entities/misc/perks/attack_leggy/leggy_limb_attacker.xml", x, y )
		EntityAddTag(child_id, "perk_entity")
		EntityAddChild( entity_who_picked, child_id )

		local num_legs = #EntityGetInRadiusWithTag(x, y, 40, "ap_leggy_foot_walker")

		if num_legs ~= 0 then
			if num_legs%3 == 0 then
				add_leg("left_red")
				add_leg("right_orange")
			elseif num_legs%3 == 1 then
				add_leg("left_yellow")
				add_leg("right_green")
			elseif num_legs%3 == 2 then
				add_leg("left_blue")
				add_leg("right_pink")
			end
		end

		if not is_stacking then
			add_leg("left_red")
			add_leg("left_yellow")
			add_leg("left_blue")
			add_leg("right_green")
			add_leg("right_pink")
			add_leg("right_orange")
			child_id = EntityLoad( "data/entities/misc/perks/attack_foot/limb_climb.xml", x, y )
			EntityAddTag( child_id, "perk_entity" )
			EntityAddChild( entity_who_picked, child_id )
			GameAddFlagRun( "AP_ATTACK_FOOT_CLIMBER" )
		else
			-- add length to limbs
			for _,v in ipairs(EntityGetAllChildren(entity_who_picked)) do
				if EntityHasTag(v, "ap_leggy_foot_walker") then
					component_readwrite(EntityGetFirstComponent(v, "IKLimbComponent"), { length = 50 }, function(comp)
						comp.length = comp.length * 1.5
					end)
				end
			end
		end

		local platformingcomponents = EntityGetComponent( entity_who_picked, "CharacterPlatformingComponent" )
		if platformingcomponents ~= nil then
			for _, component in ipairs(platformingcomponents) do
				local run_speed = tonumber(ComponentGetValue2(component, "run_velocity")) * 1.25
				local vel_x = math.abs(tonumber(ComponentGetValue2(component, "velocity_max_x"))) * 1.25

				local vel_x_min = 0 - vel_x
				local vel_x_max = vel_x

				ComponentSetValue2( component, "run_velocity", run_speed )
				ComponentSetValue2( component, "velocity_min_x", vel_x_min )
				ComponentSetValue2( component, "velocity_max_x", vel_x_max )
			end
		end

		perk_pickup_event("LUKKI")

		if pickup_count <= 2 then
			add_lukkiness_level(entity_who_picked)
		end
	end,
	func_remove = function( entity_who_picked )
		reset_perk_pickup_event("LUKKI")
		GameRemoveFlagRun( "AP_ATTACK_FOOT_CLIMBER" )
		local platformingcomponents = EntityGetComponent( entity_who_picked, "CharacterPlatformingComponent" )
		if platformingcomponents ~= nil then
			for _, component in ipairs(platformingcomponents) do
				ComponentSetValue2( component, "run_velocity", 154 )
				ComponentSetValue2( component, "velocity_min_x", -57 )
				ComponentSetValue2( component, "velocity_max_x", 57 )
			end
		end
	end,
})

for _, perk in ipairs(perk_list) do
	if perk.id == "EXTRA_PERK" then
		-- previously set it to 3, but the base number might be different in AP
		perk.func_remove = function()
			local perk_count = tonumber( GlobalsGetValue( "TEMPLE_PERK_COUNT", "3" ) )
			perk_count = perk_count - 1
			GlobalsSetValue( "TEMPLE_PERK_COUNT", tostring(perk_count) )
		end
	end
end
