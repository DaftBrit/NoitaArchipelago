local SeedCache = dofile("data/archipelago/scripts/seeded_cache.lua")

return {
	ItemDelivery = SeedCache("delivered"),
	ItemNames = SeedCache("data_package_item_ids_to_name"),
	LocationNames = SeedCache("data_package_location_ids_to_name"),
	LocationInfo = SeedCache("location_scouts_info"),

	make_key = SeedCache.make_key,
}
