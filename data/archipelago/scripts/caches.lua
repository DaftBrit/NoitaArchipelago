local SeedCache = dofile("data/archipelago/scripts/seeded_cache.lua")

-- TODO: Add DataPackage and shop scout caches
return {
  ItemDelivery = SeedCache("delivered"),

  make_key = SeedCache.make_key,
}
