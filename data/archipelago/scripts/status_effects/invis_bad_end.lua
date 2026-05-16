-- Modified with permission from Fair Mod, original by Evaisa
local entity = GetUpdatedEntityID()

local function get_all_sprites(entity)
	local result = {}

	for _, sprite in ipairs(EntityGetComponentIncludingDisabled(entity, "SpriteComponent") or {}) do
		table.insert(result, {entity, sprite})
	end

	for _, sprite in ipairs(EntityGetComponentIncludingDisabled(entity, "VerletPhysicsComponent") or {}) do
		table.insert(result, {entity, sprite})
	end

	for _, particle_emitter in ipairs(EntityGetComponentIncludingDisabled(entity, "ParticleEmitterComponent") or {}) do
		table.insert(result, {entity, particle_emitter})
	end

	if EntityHasTag(entity, "player_unit") then
		for _, comp in ipairs(EntityGetComponentIncludingDisabled(entity, "InventoryGuiComponent") or {}) do
			table.insert(result, {entity, comp})
		end

		for _, comp in ipairs(EntityGetComponentIncludingDisabled(entity, "PlatformShooterPlayerComponent") or {}) do
			table.insert(result, {entity, comp})
		end
	end
	local children = EntityGetAllChildren(entity) or {}

	for _, child in ipairs(children) do
		local child_sprites = get_all_sprites(child)

		for _, sprite in ipairs(child_sprites) do
			table.insert(result, sprite)
		end
	end

	return result
end


local sprites = get_all_sprites(EntityGetRootEntity(entity))

for _, sprite in ipairs(sprites) do
	if ComponentHasTag(sprite[2], "bi_invisibility") then
		if ComponentGetTypeName(sprite[2]) == "SpriteComponent" then
			ComponentSetValue2(sprite[2], "visible", true)
		end

		if ComponentGetTypeName(sprite[2]) == "InventoryGuiComponent" then
			EntitySetComponentIsEnabled(sprite[1], sprite[2], true)
		end


		if ComponentGetTypeName(sprite[2]) == "ParticleEmitterComponent" then
			ComponentSetValue2(sprite[2], "emitting", true)
		end

		if ComponentGetTypeName(sprite[2]) == "PlatformShooterPlayerComponent" then
			ComponentSetValue2(sprite[2], "center_camera_on_this_entity", true)
		end

		ComponentRemoveTag(sprite[2], "bi_invisibility")
	end
end

local player_entity = EntityGetRootEntity(entity)
local x, y = EntityGetTransform(player_entity)
local cape = EntityLoad("data/entities/verlet_chains/cape/cape.xml", x, y)
EntityAddChild(player_entity, cape)
EntitySetName(cape, "cape")
