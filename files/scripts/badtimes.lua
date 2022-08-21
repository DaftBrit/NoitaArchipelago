-- events list for bad time events (taken from streaming integration with only bad and awful events left)
dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/lib/coroutines.lua")
dofile_once("data/scripts/streaming_integration/event_utilities.lua")
dofile( "data/scripts/perks/perk.lua" )
dofile( "data/scripts/game_helpers.lua" )

streaming_events =
{
    {
        id = "SPEEDY_ENEMIES",
        ui_name = "$streamingevent_speedy_enemies",
        ui_description = "$streamingeventdesc_speedy_enemies",
        ui_icon = "data/ui_gfx/streaming_event_icons/speedy_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 1.0,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            for _,enemy in pairs(get_enemies_in_radius(400)) do
                local game_effect_comp,game_effect_entity = GetGameEffectLoadTo( enemy, "MOVEMENT_FASTER_2X", false )
                if (game_effect_comp ~= nil) and (game_effect_entity ~= nil) then
                    ComponentSetValue( game_effect_comp, "frames", "-1" )
                    add_icon_above_head( game_effect_entity, "data/ui_gfx/status_indicators/movement_faster.png", event )
                end
            end
        end,
    },
    {
        id = "PROTECT_ENEMIES",
        ui_name = "$streamingevent_protect_enemies",
        ui_description = "$streamingeventdesc_protect_enemies",
        ui_icon = "data/ui_gfx/streaming_event_icons/protect_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 0.5,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            for _,enemy in pairs(get_enemies_in_radius(400)) do
                local game_effect_comp,game_effect_entity = GetGameEffectLoadTo( enemy, "PROTECTION_ALL", false )
                if (game_effect_comp ~= nil) and (game_effect_entity ~= nil) then
                    ComponentSetValue2( game_effect_comp, "frames", get_lifetime() )
                    add_icon_above_head( game_effect_entity, "data/ui_gfx/status_indicators/protection_all.png", event )
                end
            end
        end,
    },
    {
        id = "TINY_GHOST_ENEMY",
        ui_name = "$streamingevent_tiny_ghost_enemy",
        ui_description = "$streamingeventdesc_tiny_ghost_enemy",
        ui_icon = "data/ui_gfx/streaming_event_icons/tiny_ghost_enemy.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 2.0,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            for _,enemy in pairs(get_enemies_in_radius(400)) do
                if EntityGetComponent(enemy, "GenomeDataComponent") ~= nil then
                    local entity_id = EntityLoad( "data/scripts/streaming_integration/entities/tiny_ghost.xml" )
                    EntityAddChild( enemy, entity_id )
                    add_text_above_head( entity_id, StreamingGetRandomViewerName() )
                end
            end
        end,
    },
    {
        id = "HOMING_ENEMY_PROJECTILES",
        ui_name = "$streamingevent_homing_enemy_projectiles",
        ui_description = "$streamingeventdesc_homing_enemy_projectiles",
        ui_icon = "data/ui_gfx/streaming_event_icons/homing_enemy_projectiles.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 0.5,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            for _,enemy in pairs(get_enemies_in_radius(400)) do
                local entity_id = EntityLoad( "data/scripts/streaming_integration/entities/effect_homing_enemy_projectiles.xml" )
                EntityAddChild( enemy, entity_id )
                add_icon_above_head( entity_id, "data/ui_gfx/status_indicators/homing.png", event )
            end
        end,
    },
    {
        id = "SHIELD_ENEMIES",
        ui_name = "$streamingevent_shield_enemies",
        ui_description = "$streamingeventdesc_shield_enemies",
        ui_icon = "data/ui_gfx/streaming_event_icons/protect_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 1.0,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            for i,entity_id in pairs( get_enemies_in_radius(400) ) do
                local x, y = EntityGetTransform( entity_id )

                local effect_id = EntityLoad( "data/scripts/streaming_integration/entities/shield.xml", x, y )
                set_lifetime( effect_id )
                EntityAddChild( entity_id, effect_id )
                add_icon_above_head( effect_id, "data/ui_gfx/status_indicators/shield.png", event )
            end
        end,
    },
    {
        id = "SLIMY_PLAYER",
        ui_name = "$streamingevent_slimy_player",
        ui_description = "$streamingeventdesc_slimy_player",
        ui_icon = "data/ui_gfx/streaming_event_icons/protect_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 1.0,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            for i,entity_id in pairs( get_players() ) do
                local x, y = EntityGetTransform( entity_id )

                EntityAddRandomStains( entity_id, CellFactory_GetType("slime"), 400 )
            end

            for i,entity_id in pairs( get_enemies_in_radius(400) ) do
                local x, y = EntityGetTransform( entity_id )

                EntityAddRandomStains( entity_id, CellFactory_GetType("slime"), 400 )
            end
        end,
    },
    {
        id = "OILED_PLAYER",
        ui_name = "$streamingevent_oiled_player",
        ui_description = "$streamingeventdesc_oiled_player",
        ui_icon = "data/ui_gfx/streaming_event_icons/protect_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 1.0,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            for i,entity_id in pairs( get_players() ) do
                local x, y = EntityGetTransform( entity_id )

                local effect_id = EntityLoad( "data/scripts/streaming_integration/entities/cloud_oil.xml", x, y )
                set_lifetime( effect_id )
                EntityAddChild( entity_id, effect_id )

                add_icon_in_hud( effect_id, "data/ui_gfx/status_indicators/cloud_oil.png", event )
            end
        end,
    },
    {
        id = "DRUNK_PLAYER",
        ui_name = "$streamingevent_drunk_player",
        ui_description = "$streamingeventdesc_drunk_player",
        ui_icon = "data/ui_gfx/streaming_event_icons/protect_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 1.0,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            for i,entity_id in pairs( get_players() ) do
                local x, y = EntityGetTransform( entity_id )

                EntityIngestMaterial( entity_id, CellFactory_GetType("alcohol"), 100 )
            end
        end,
    },
    {
        id = "SEA_OF_LAVA",
        ui_name = "$streamingevent_sea_of_lava",
        ui_description = "$streamingeventdesc_sea_of_lava",
        ui_icon = "data/ui_gfx/streaming_event_icons/health_plus.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 1.0,
        kind = STREAMING_EVENT_BAD,
        delay_timer = 420,
        action_delayed = function(event)
            local players = get_players()

            for i,entity_id in ipairs( players ) do
                local x, y = EntityGetTransform( entity_id )

                EntityLoad( "data/scripts/streaming_integration/entities/sea_lava.xml", x, y )
            end
        end,
    },
    {
        id = "SPAWN_WORM",
        ui_name = "$streamingevent_spawn_worm",
        ui_description = "$streamingeventdesc_spawn_worm",
        ui_icon = "data/ui_gfx/streaming_event_icons/health_plus.png",
        weight = 1.0,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            local players = get_players()
            SetRandomSeed( GameGetFrameNum(), GameGetFrameNum() - 253 )

            for i,entity_id in ipairs( players ) do
                local x, y = EntityGetTransform( entity_id )

                local angle = Random( 0, 31415 ) * 0.0001
                local length = 250

                local ex = x + math.cos( angle ) * length
                local ey = y - math.sin( angle ) * length

                EntityLoad( "data/scripts/streaming_integration/entities/worm_big.xml", ex, ey )
            end
        end,
    },
    {
        id = "SPAWN_SHOPKEEPER",
        ui_name = "$streamingevent_spawn_shopkeeper",
        ui_description = "$streamingeventdesc_spawn_shopkeeper",
        ui_icon = "data/ui_gfx/streaming_event_icons/health_plus.png",
        ui_author = "Steve",
        weight = 0.75,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            local players = get_players()
            SetRandomSeed( GameGetFrameNum(), GameGetFrameNum() + 353 )

            for i,entity_id in ipairs( players ) do
                local x, y = EntityGetTransform( entity_id )

                local angle = Random( 0, 31415 ) * 0.0001
                local length = 250

                local ex = x + math.cos( angle ) * length
                local ey = y - math.sin( angle ) * length

                EntityLoad( "data/scripts/streaming_integration/entities/necromancer_shop.xml", ex, ey )
                EntityLoad( "data/scripts/streaming_integration/entities/empty_circle.xml", ex, ey )
            end
        end,
    },
    {
        id = "BOOMERANG_SHOTS",
        ui_name = "$streamingevent_boomerang_shots",
        ui_description = "$streamingeventdesc_boomerang_shots",
        ui_icon = "data/ui_gfx/streaming_event_icons/protect_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 1.0,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            for i,entity_id in pairs( get_players() ) do
                local x, y = EntityGetTransform( entity_id )

                local effect_id = EntityLoad( "data/scripts/streaming_integration/entities/effect_boomerang_shots.xml", x, y )
                set_lifetime( effect_id )
                EntityAddChild( entity_id, effect_id )

                add_icon_in_hud( effect_id, "data/ui_gfx/status_indicators/homing_shooter.png", event )
            end
        end,
    },
    {
        id = "FIZZLE",
        ui_name = "$streamingevent_fizzle",
        ui_description = "$streamingeventdesc_fizzle",
        ui_icon = "data/ui_gfx/streaming_event_icons/protect_enemies.png",
        weight = 1.0,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            for i,entity_id in pairs( get_players() ) do
                local x, y = EntityGetTransform( entity_id )

                local effect_id = EntityLoad( "data/scripts/streaming_integration/entities/effect_fizzle.xml", x, y )
                EntityAddChild( entity_id, effect_id )
            end
        end,
    },
    {
        id = "GIVE_WAND_TO_ENEMY",
        ui_name = "$streamingevent_give_wand_to_enemy",
        ui_description = "$streamingeventdesc_give_wand_to_enemy",
        ui_icon = "data/ui_gfx/streaming_event_icons/protect_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 0.75,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            local enemies = get_enemies_in_radius(600)
            if #enemies == 0 then return end

            -- select a random enemy that can pick up items
            local entity_id, itempickup
            local t = GameGetFrameNum()
            for i=1,20 do
                SetRandomSeed( t, i )
                entity_id = random_from_array( enemies )
                itempickup = EntityGetComponent( entity_id, "ItemPickUpperComponent" )
                if itempickup then break end
            end

            local rnd = Random( 1, 3 )
            local x, y = EntityGetTransform( entity_id )
            EntityLoad( "data/scripts/streaming_integration/entities/wand_level_0" .. tostring(rnd) .. ".xml", x, y )
        end,
    },
    {
        id = "REMOVE_GROUND",
        ui_name = "$streamingevent_remove_ground",
        ui_description = "$streamingeventdesc_remove_ground",
        ui_icon = "data/ui_gfx/streaming_event_icons/protect_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 1.0,
        kind = STREAMING_EVENT_BAD,
        delay_timer = 300,
        action_delayed = function(event)
            for i,entity_id in pairs( get_players() ) do
                local x, y = EntityGetTransform( entity_id )

                EntityLoad( "data/scripts/streaming_integration/entities/remove_ground.xml", x, y )
            end
        end,
    },
    {
        id = "FIREBALL_THROWER_PLAYER",
        ui_name = "$streamingevent_fireball_thrower_player",
        ui_description = "$streamingeventdesc_fireball_thrower_player",
        ui_icon = "data/ui_gfx/streaming_event_icons/protect_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 1.0,
        kind = STREAMING_EVENT_AWFUL,
        delay_timer = 300,
        action_delayed = function(event)
            for i,entity_id in pairs( get_players() ) do
                local x, y = EntityGetTransform( entity_id )

                local effect_id = EntityLoad( "data/scripts/streaming_integration/entities/fireball_ray.xml", x, y )
                EntityAddChild( entity_id, effect_id )

                add_icon_in_hud( effect_id, "data/ui_gfx/status_indicators/fireball_ray.png", event )
            end
        end,
    },
    {
        id = "TRANSFORM_GIGA_DISCS",
        ui_name = "$streamingevent_transform_giga_discs",
        ui_description = "$streamingeventdesc_transform_giga_discs",
        ui_icon = "data/ui_gfx/streaming_event_icons/protect_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 0.5,
        kind = STREAMING_EVENT_BAD,
        delay_timer = 180,
        action_delayed = function(event)
            for i,entity_id in pairs( get_players() ) do
                local x, y = EntityGetTransform( entity_id )

                local effect_id = EntityLoad( "data/scripts/streaming_integration/entities/effect_giga_discs.xml", x, y )
                set_lifetime( effect_id )
                EntityAddChild( entity_id, effect_id )

                add_icon_in_hud( effect_id, "data/ui_gfx/status_indicators/disc_bullet.png", event )
            end
        end,
    },
    {
        id = "TRANSFORM_NUKES",
        ui_name = "$streamingevent_transform_nukes",
        ui_description = "$streamingeventdesc_transform_nukes",
        ui_icon = "data/ui_gfx/streaming_event_icons/protect_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 0.1,
        kind = STREAMING_EVENT_AWFUL,
        delay_timer = 180,
        action_delayed = function(event)
            for i,entity_id in pairs( get_players() ) do
                local x, y = EntityGetTransform( entity_id )

                local effect_id = EntityLoad( "data/scripts/streaming_integration/entities/effect_nukes.xml", x, y )
                EntityAddChild( entity_id, effect_id )

                add_icon_in_hud( effect_id, "data/ui_gfx/status_indicators/nuke.png", event )
            end
        end,
    },
    {
        id = "RAIN_WORM",
        ui_name = "$streamingevent_rain_worm",
        ui_description = "$streamingeventdesc_rain_worm",
        ui_icon = "data/ui_gfx/streaming_event_icons/protect_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 0.5,
        kind = STREAMING_EVENT_BAD,
        delay_timer = 600,
        action_delayed = function(event)
            for i,entity_id in pairs( get_players() ) do
                local x, y = EntityGetTransform( entity_id )

                EntityLoad( "data/scripts/streaming_integration/entities/rain_worm.xml", x, y )
            end
        end,
    },
    {
        id = "RAIN_BOMB",
        ui_name = "$streamingevent_rain_bomb",
        ui_description = "$streamingeventdesc_rain_bomb",
        ui_icon = "data/ui_gfx/streaming_event_icons/protect_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 1.0,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            for i,entity_id in pairs( get_players() ) do
                local x, y = EntityGetTransform( entity_id )

                EntityLoad( "data/scripts/streaming_integration/entities/rain_bomb.xml", x, y )
            end
        end,
    },
    {
        id = "RAIN_BLACKHOLE",
        ui_name = "$streamingevent_rain_blackhole",
        ui_description = "$streamingeventdesc_rain_blackhole",
        ui_icon = "data/ui_gfx/streaming_event_icons/protect_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 0.2,
        kind = STREAMING_EVENT_BAD,
        delay_timer = 180,
        action_delayed = function(event)
            for i,entity_id in pairs( get_players() ) do
                local x, y = EntityGetTransform( entity_id )

                EntityLoad( "data/scripts/streaming_integration/entities/rain_blackhole.xml", x, y )
            end
        end,
    },
    {
        id = "RAIN_HIISI",
        ui_name = "$streamingevent_rain_hiisi",
        ui_description = "$streamingeventdesc_rain_hiisi",
        ui_icon = "data/ui_gfx/streaming_event_icons/protect_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 1.0,
        kind = STREAMING_EVENT_BAD,
        delay_timer = 180,
        action_delayed = function(event)
            for i,entity_id in pairs( get_players() ) do
                local x, y = EntityGetTransform( entity_id )

                EntityLoad( "data/scripts/streaming_integration/entities/rain_hiisi.xml", x, y )
            end
        end,
    },
    {
        id = "RAIN_POTION",
        ui_name = "$streamingevent_rain_potion",
        ui_description = "$streamingeventdesc_rain_potion",
        ui_icon = "data/ui_gfx/streaming_event_icons/protect_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 0.75,
        kind = STREAMING_EVENT_GOOD,
        action = function(event)
            for i,entity_id in pairs( get_players() ) do
                local x, y = EntityGetTransform( entity_id )

                EntityLoad( "data/scripts/streaming_integration/entities/rain_potion.xml", x, y )
            end
        end,
    },
    {
        id = "GRAVITY_PLAYER",
        ui_name = "$streamingevent_gravity_player",
        ui_description = "$streamingeventdesc_gravity_player",
        ui_icon = "data/ui_gfx/streaming_event_icons/protect_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 1.0,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            for i,entity_id in pairs( get_players() ) do
                local x, y = EntityGetTransform( entity_id )

                local effect_id = EntityLoad( "data/scripts/streaming_integration/entities/gravity_field.xml", x, y )
                set_lifetime( effect_id )
                EntityAddChild( entity_id, effect_id )

                add_icon_in_hud( effect_id, "data/ui_gfx/status_indicators/gravity_field.png", event )
            end
        end,
    },
    {
        id = "TRAIL_ACID",
        ui_name = "$streamingevent_trail_acid",
        ui_description = "$streamingeventdesc_trail_acid",
        ui_icon = "data/ui_gfx/streaming_event_icons/protect_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 0.85,
        kind = STREAMING_EVENT_BAD,
        delay_timer = 180,
        action_delayed = function(event)
            for i,entity_id in pairs( get_players() ) do
                local x, y = EntityGetTransform( entity_id )

                local effect_id = EntityLoad( "data/scripts/streaming_integration/entities/effect_trail_acid.xml", x, y )
                set_lifetime( effect_id )
                EntityAddChild( entity_id, effect_id )

                add_icon_in_hud( effect_id, "data/ui_gfx/status_indicators/trail_acid.png", event )
            end
        end,
    },
    {
        id = "TRAIL_LAVA",
        ui_name = "$streamingevent_trail_lava",
        ui_description = "$streamingeventdesc_trail_lava",
        ui_icon = "data/ui_gfx/streaming_event_icons/protect_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 0.85,
        kind = STREAMING_EVENT_BAD,
        delay_timer = 180,
        action_delayed = function(event)
            for i,entity_id in pairs( get_players() ) do
                local x, y = EntityGetTransform( entity_id )

                local effect_id = EntityLoad( "data/scripts/streaming_integration/entities/effect_trail_lava.xml", x, y )
                set_lifetime( effect_id )
                EntityAddChild( entity_id, effect_id )

                add_icon_in_hud( effect_id, "data/ui_gfx/status_indicators/trail_lava.png", event )
            end
        end,
    },
    {
        id = "PLAYER_TRIP",
        ui_name = "$streamingevent_player_trip",
        ui_description = "$streamingeventdesc_player_trip",
        ui_icon = "data/ui_gfx/streaming_event_icons/protect_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 1.0,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            for i,entity_id in pairs( get_players() ) do
                EntityIngestMaterial( entity_id, CellFactory_GetType("fungi"), 200 )
            end
        end,
    },
    {
        id = "TRANSMUTATION",
        ui_name = "$streamingevent_transmutation",
        ui_description = "$streamingeventdesc_transmutation",
        ui_icon = "data/ui_gfx/streaming_event_icons/protect_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 1.0,
        kind = STREAMING_EVENT_BAD,
        delay_timer = 180,
        action_delayed = function(event)
            for i,entity_id in pairs( get_players() ) do
                local x, y = EntityGetTransform( entity_id )

                local effect_id = EntityLoad( "data/scripts/streaming_integration/entities/transmutation.xml", x, y )
                set_lifetime( effect_id )
                EntityAddChild( entity_id, effect_id )

                add_icon_in_hud( effect_id, "data/ui_gfx/status_indicators/radioactive.png", event )
            end
        end,
    },
    {
        id = "SLOW_BULLETS",
        ui_name = "$streamingevent_slow_bullets",
        ui_description = "$streamingeventdesc_slow_bullets",
        ui_icon = "data/ui_gfx/streaming_event_icons/protect_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 1.0,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            for i,entity_id in pairs( get_players() ) do
                local x, y = EntityGetTransform( entity_id )

                local effect_id = EntityLoad( "data/scripts/streaming_integration/entities/effect_slow_bullets.xml", x, y )
                set_lifetime( effect_id )
                EntityAddChild( entity_id, effect_id )

                add_icon_in_hud( effect_id, "data/ui_gfx/status_indicators/slow_bullets.png", event )
            end
        end,
    },
    {
        id = "SLOW_PLAYER",
        ui_name = "$streamingevent_slow_player",
        ui_description = "$streamingeventdesc_slow_player",
        ui_icon = "data/ui_gfx/streaming_event_icons/speedy_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 1.0,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            for _,enemy in pairs(get_players()) do
                -- stack multiple speed ups that last perpetually
                local game_effect_comp,game_effect_entity = GetGameEffectLoadTo( enemy, "MOVEMENT_SLOWER", false )
                if game_effect_comp ~= nil then
                    ComponentSetValue2( game_effect_comp, "frames", 1800 )
                    add_icon_in_hud( game_effect_entity, "data/ui_gfx/status_indicators/movement_slower.png", event )
                end
            end
        end,
    },
    {
        id = "WEAKEN_WANDS",
        ui_name = "$streamingevent_weaken_wands",
        ui_description = "$streamingeventdesc_weaken_wands",
        ui_icon = "data/ui_gfx/streaming_event_icons/speedy_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 1.0,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            local wands = EntityGetWithTag( "wand" )

            for i,entity_id in ipairs( wands ) do
                local models = EntityGetComponentIncludingDisabled( entity_id, "AbilityComponent" )
                if( models ~= nil ) then
                    for j,model in ipairs(models) do
                        local reload_time = tonumber( ComponentObjectGetValue( model, "gun_config", "reload_time" ) )
                        local actions_per_round = tonumber( ComponentObjectGetValue( model, "gun_config", "actions_per_round" ) )
                        local fire_rate_wait = tonumber( ComponentObjectGetValue( model, "gunaction_config", "fire_rate_wait" ) )
                        local spread_degrees = tonumber( ComponentObjectGetValue( model, "gunaction_config", "spread_degrees" ) )
                        local speed_multiplier = tonumber( ComponentObjectGetValue( model, "gunaction_config", "speed_multiplier" ) )
                        local mana_charge_speed = ComponentGetValue2( model, "mana_charge_speed" )
                        local mana_max = ComponentGetValue2( model, "mana_max" )

                        SetRandomSeed( entity_id + GameGetFrameNum(), GameGetFrameNum() - 453 )

                        --print( tostring(reload_time) .. ", " .. tostring(cast_delay) .. ", " .. tostring(mana_charge_speed) )

                        reload_time = reload_time + Random(0, 200) * 0.1
                        fire_rate_wait = fire_rate_wait + Random(0, 200) * 0.1
                        mana_charge_speed = math.max( 1, mana_charge_speed - Random(0, 40) )
                        spread_degrees = spread_degrees + Random(0, 5)
                        speed_multiplier = math.max( -0.9, speed_multiplier - Random( 0, 5 ) * 0.1 )
                        mana_max = math.max( mana_max - Random( 0, 200 ), 5 )
                        actions_per_round = math.max( actions_per_round - Random( 0, 1 ) * Random( 0, 1 ), 2 )

                        ComponentSetValue2( model, "mana_charge_speed", mana_charge_speed )
                        ComponentSetValue2( model, "mana_max", mana_max )
                        ComponentObjectSetValue( model, "gun_config", "reload_time", tostring(reload_time) )
                        ComponentObjectSetValue( model, "gun_config", "actions_per_round", tostring(actions_per_round) )
                        ComponentObjectSetValue( model, "gunaction_config", "fire_rate_wait", tostring(fire_rate_wait) )
                        ComponentObjectSetValue( model, "gunaction_config", "spread_degrees", tostring(spread_degrees) )
                        ComponentObjectSetValue( model, "gunaction_config", "speed_multiplier", tostring(speed_multiplier) )
                    end
                end
            end
        end,
    },
    {
        id = "PLAYER_GAS",
        ui_name = "$streamingevent_player_gas",
        ui_description = "$streamingeventdesc_player_gas",
        ui_icon = "data/ui_gfx/streaming_event_icons/speedy_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 0.5,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            for i,entity_id in pairs( get_players() ) do
                local x, y = EntityGetTransform( entity_id )

                local effect_id = EntityLoad( "data/scripts/streaming_integration/entities/effect_player_gas.xml", x, y )
                set_lifetime( effect_id, 1.25 )
                EntityAddChild( entity_id, effect_id )

                add_icon_in_hud( effect_id, "data/ui_gfx/status_indicators/farts.png", event )
            end
        end,
    },
    {
        id = "AREADAMAGE_ENEMY",
        ui_name = "$streamingevent_areadamage_enemy",
        ui_description = "$streamingeventdesc_areadamage_enemy",
        ui_icon = "data/ui_gfx/streaming_event_icons/tiny_ghost_enemy.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 0.6,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            for _,enemy in pairs(get_enemies_in_radius(400)) do
                local entity_id = EntityLoad( "data/scripts/streaming_integration/entities/contact_damage_enemy.xml" )
                set_lifetime( entity_id, 0.8 )
                EntityAddChild( enemy, entity_id )
            end
        end,
    },
    {
        id = "TWITCHY",
        ui_name = "$streamingevent_twitchy",
        ui_description = "$streamingeventdesc_twitchy",
        ui_icon = "data/ui_gfx/streaming_event_icons/speedy_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 1.0,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            local players = get_players()

            for i,entity_id in ipairs( players ) do
                local x, y = EntityGetTransform( entity_id )

                local effect_id = EntityLoad( "data/entities/misc/effect_twitchy.xml", x, y )
                set_lifetime( effect_id )
                EntityAddChild( entity_id, effect_id )

                add_icon_in_hud( effect_id, "data/ui_gfx/status_indicators/twitchy.png", event )
            end
        end,
    },
    {
        id = "HIGH_SPREAD",
        ui_name = "$streamingevent_high_spread",
        ui_description = "$streamingeventdesc_high_spread",
        ui_icon = "data/ui_gfx/streaming_event_icons/speedy_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 1.0,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            for i,entity_id in pairs( get_players() ) do
                local x, y = EntityGetTransform( entity_id )

                local effect_id = EntityLoad( "data/scripts/streaming_integration/entities/effect_high_spread.xml", x, y )
                set_lifetime( effect_id, 0.75 )
                EntityAddChild( entity_id, effect_id )

                add_icon_in_hud( effect_id, "data/ui_gfx/status_indicators/high_spread.png", event )
            end
        end,
    },
    {
        id = "SPAWN_PERK_ENEMY",
        ui_name = "$streamingevent_spawn_perk_enemy",
        ui_description = "$streamingeventdesc_spawn_perk_enemy",
        ui_icon = "data/ui_gfx/streaming_event_icons/speedy_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 0.5,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            for i,entity_id in pairs( get_enemies_in_radius(500) ) do
                local x, y = EntityGetTransform( entity_id )

                SetRandomSeed( x, y * entity_id )

                if ( Random( 1, 3 ) == 1 ) then
                    give_random_perk_to_enemy( entity_id )
                end
            end
        end,
    },
    {
        id = "ALL_ACCESS_TELEPORT",
        ui_name = "$streamingevent_all_access_teleport",
        ui_description = "$streamingeventdesc_all_access_teleport",
        ui_icon = "data/ui_gfx/streaming_event_icons/speedy_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 0.5,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            for i,entity_id in pairs( get_enemies_in_radius(500) ) do
                EntityRemoveTag( entity_id, "teleportable_NOT" )
                EntityAddTag( entity_id, "teleportable" )
            end
        end,
    },
    {
        id = "FIREWORKS",
        ui_name = "$streamingevent_fireworks",
        ui_description = "$streamingeventdesc_fireworks",
        ui_icon = "data/ui_gfx/streaming_event_icons/speedy_enemies.png",
        ui_author = STREAMING_EVENT_AUTHOR_NOLLAGAMES,
        weight = 0.01,
        kind = STREAMING_EVENT_BAD,
        action = function(event)
            for i,entity_id in pairs( get_players() ) do
                local x, y = EntityGetTransform( entity_id )

                EntityLoad( "data/scripts/streaming_integration/entities/fireworks.xml", x, y )
            end
        end,
    },
}