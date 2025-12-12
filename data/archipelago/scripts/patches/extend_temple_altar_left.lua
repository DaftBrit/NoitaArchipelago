RegisterSpawnFunction(0xffa65683, "archipelago_spawn_gift_interface")
RegisterSpawnFunction(0xffa65684, "archipelago_spawn_mailbox_interface")

function archipelago_spawn_gift_interface(x, y)
	EntityLoad("data/archipelago/entities/buildings/ap_gift_interface.xml", x, y)
end

function archipelago_spawn_mailbox_interface(x, y)
	EntityLoad("data/archipelago/entities/buildings/ap_mailbox_interface.xml", x, y)
end
