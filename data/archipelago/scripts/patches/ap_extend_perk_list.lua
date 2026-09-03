dofile_once("data/scripts/lib/utilities.lua") -- component_readwrite
dofile_once("data/scripts/perks/perk_utilities.lua")

local ARCHIPELAGO_REMOVE_FROM_POOL = {
	-- Original perk list
	PROTECTION_ELECTRICITY = 1,
	PROTECTION_MELEE = 1,
	PROTECTION_RADIOACTIVITY = 1,
	PROTECTION_FIRE = 1,
	PROTECTION_EXPLOSION = 1,
	EDIT_WANDS_EVERYWHERE = 1,
	REMOVE_FOG_OF_WAR = 1,
	RESPAWN = 1,
	MEGA_BEAM_STONE = 1,

	-- V2 perk list (re-added later if still running v1 apworld)
	EXTRA_PERK = 1,
	SAVING_GRACE = 1,
	TRICK_BLOOD_MONEY = 1,
	NO_MORE_KNOCKBACK = 1,
	MANA_FROM_KILLS = 1,
	RADAR_ENEMY = 1,
	IRON_STOMACH = 1,
	WAND_RADAR = 1,
	ITEM_RADAR = 1,
	ADVENTURER = 1,
	ABILITY_ACTIONS_MATERIALIZED = 1,
	UNLIMITED_SPELLS = 1,
}

local perk_extensions = {
	{
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
	},
	{
		id = "AP_PERK_REROLL",
		ui_name="$item_perk_reroll",
		ui_description="$ap_perk_reroll_desc",
		ui_icon = "data/archipelago/ui_gfx/perk_icons/perk_reroll.png",
		perk_icon = "data/archipelago/items_gfx/perks/perk_reroll.png",
		stackable = STACKABLE_NO,
		not_in_default_perk_pool = true,
		func = function()
			GameAddFlagRun("ap_perk_reroll_available")
		end
	},
	{
		id = "AP_PERK_REROLL_DISCOUNT",
		ui_name="$ap_perk_reroll_discount",
		ui_description="$ap_perk_reroll_discount_desc",
		ui_icon = "data/archipelago/ui_gfx/perk_icons/perk_reroll_discount.png",
		perk_icon = "data/archipelago/items_gfx/perks/perk_reroll_discount.png",
		stackable = STACKABLE_YES,
		not_in_default_perk_pool = true,
		func = function()
			local num = tonumber( GlobalsGetValue( "AP_PERK_REROLL_DISCOUNTS", "0" ) )
			num = num + 1
			GlobalsSetValue( "AP_PERK_REROLL_DISCOUNTS", tostring(num) )
		end,
		func_remove = function()
			local num = tonumber( GlobalsGetValue( "AP_PERK_REROLL_DISCOUNTS", "0" ) )
			num = num - 1
			GlobalsSetValue( "AP_PERK_REROLL_DISCOUNTS", tostring(num) )
		end
	},
	{
		id = "AP_CHEST_RADAR",
		ui_name = "$perk_ap_chest_radar",
		ui_description = "$perkdesc_ap_chest_radar",
		ui_icon = "data/archipelago/ui_gfx/perk_icons/perk_ap_radar.png",
		perk_icon = "data/archipelago/items_gfx/perks/perk_ap_radar.png",
		stackable = STACKABLE_NO,
		usable_by_enemies = false,
		not_in_default_perk_pool = true,
		func = function( entity_perk_item, entity_who_picked, item_name, pickup_count )
			EntityAddComponent2( entity_who_picked, "LuaComponent",
			{
				_tags = "perk_component",
				script_source_file = "data/archipelago/scripts/items/ap_radar.lua",
				execute_every_n_frame = 1,
			})
		end,
	}
}

for _, perk in ipairs(perk_extensions) do
	table.insert(perk_list, perk)
end

for _, perk in ipairs(perk_list) do
	if perk.id == "EXTRA_PERK" then
		-- previously set it to 3, but the base number might be different in AP
		perk.func_remove = function()
			local perk_count = tonumber( GlobalsGetValue( "TEMPLE_PERK_COUNT", "3" ) )
			perk_count = perk_count - 1
			GlobalsSetValue( "TEMPLE_PERK_COUNT", tostring(perk_count) )
		end
	end

	if ARCHIPELAGO_REMOVE_FROM_POOL[perk.id] ~= nil then
		perk.not_in_default_perk_pool = true
	end
end
