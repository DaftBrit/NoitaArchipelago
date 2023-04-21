local SeedCache = dofile("data/archipelago/scripts/seeded_cache.lua")
local ItemCache = dofile("data/archipelago/scripts/item_delivery_cache.lua")

return {
	ItemDelivery = ItemCache("delivered"),
	ItemNames = SeedCache("data_package_item_ids_to_name"),
	LocationNames = SeedCache("data_package_location_ids_to_name"),
	LocationInfo = SeedCache("location_scouts_info"),
	ChecksumVersions = SeedCache("checksum_versions"),
}
