local Globals = dofile("data/archipelago/scripts/globals.lua") --- @type Globals

RegisterSpawnFunction(0xff342069, "spawn_archipelago_pedestal")

--local world_x = (x * chunk_size) - ((biome_map_w * chunk_size) / 2)
--local world_y = y * chunk_size - (14 * chunk_size)

--
--

---@param x integer
---@param y integer
function spawn_archipelago_pedestal(x, y)
	Globals.NumMinesAreas:increment()
	local chunk_x = math.floor(x / 512 + 35)
	local chunk_y = math.floor(y / 512 + 14)
	print_error(string.format("#%d in chunk %d, %d", Globals.NumMinesAreas:get(), chunk_x, chunk_y))
end
