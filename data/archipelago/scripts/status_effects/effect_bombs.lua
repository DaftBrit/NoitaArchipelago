-- Original by Evaisa, modified with permission
local projectiles = EntityGetWithTag("projectile") or {}

for _, projectile_id in ipairs(projectiles) do
	if not EntityHasTag(projectile_id, "donotrepeat") then
		local px, py = EntityGetTransform(projectile_id)
		local vel_x, vel_y = GameGetVelocityCompVelocity(projectile_id)

		-- Pull out props to kill projectile before spawning new one
		local comps = EntityGetComponentIncludingDisabled(projectile_id, "ProjectileComponent") or {}
		local mWhoShot = 0
		local mShooterHerdId = 0
		for _,comp_id in ipairs(comps) do
			ComponentSetValue2(comp_id, "on_death_explode", false)
			ComponentSetValue2(comp_id, "on_lifetime_out_explode", false)
			mWhoShot = ComponentGetValue2(comp_id, "mWhoShot")
			mShooterHerdId = ComponentGetValue2(comp_id, "mShooterHerdId")
		end

		local friendly_fire_enabled = EntityHasTag(projectile_id, "friendly_fire_enabled")

		-- RIP
		EntityKill(projectile_id)

		-- Create our new replacement
		local new_entity = EntityLoad("data/entities/projectiles/bomb_small.xml", px, py)
		GameShootProjectile(mWhoShot, px, py, px + vel_x, py + vel_y, new_entity, true, mWhoShot)
		EntityAddTag(new_entity, "donotrepeat")

		-- Inherit velocity
		local new_velocs = EntityGetComponentIncludingDisabled(projectile_id, "VelocityComponent") or {}
		for _,comp_id in ipairs(new_velocs) do
			ComponentSetValue2(comp_id, "mVelocity", vel_x, vel_y)
		end

		-- Copy over some properties
		local new_comps = EntityGetComponentIncludingDisabled(projectile_id, "ProjectileComponent") or {}
		for _,comp_id in ipairs(new_comps) do
			ComponentSetValue2(comp_id, "mWhoShot", mWhoShot)
			ComponentSetValue2(comp_id, "mShooterHerdId", mShooterHerdId)

			if friendly_fire_enabled then
				ComponentSetValue2(comp_id, "friendly_fire", true)
				ComponentSetValue2(comp_id, "collide_with_shooter_frames", 6)
			end
		end

	end
end
