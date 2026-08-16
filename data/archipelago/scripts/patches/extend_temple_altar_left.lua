RegisterSpawnFunction(0xffa65683, "archipelago_spawn_gift_interface")
RegisterSpawnFunction(0xffa65684, "archipelago_spawn_mailbox_interface")
RegisterSpawnFunction(0xff784dd2, "spawn_worm_deflector")

function archipelago_spawn_gift_interface(x, y)
	--EntityLoad("data/archipelago/entities/buildings/ap_gift_interface.xml", x, y)
end

function archipelago_spawn_mailbox_interface(x, y)
	--EntityLoad("data/archipelago/entities/buildings/ap_mailbox_interface.xml", x, y)
end

function spawn_worm_deflector( x, y )
	-- EntityLoad( "data/entities/buildings/physics_worm_deflector.xml", x, y )
	EntityLoad( "data/entities/buildings/physics_worm_deflector_crystal.xml", x, y + 5 )
	EntityLoad( "data/entities/buildings/physics_worm_deflector_base.xml", x, y + 5 )
end
