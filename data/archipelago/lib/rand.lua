-- Random lib ported from Starcraft/Diablo
-- Hash algo ported from Stormlib
local Object = dofile("data/archipelago/lib/classic/classic.lua") ---@type Object

--- @class Rand : Object
--- @field seed integer
local Rand = Object:extend()

local BASE_SEED = 0x7FED7FED
local ADJUST = 0xEEEEEEEE
local MULTIPLIER = 0x015a4e35

local HASH_TABLE = {
    0x486E26EE, 0xDCAA16B3, 0xE1918EEF, 0x202DAFDB,
    0x341C7DC7, 0x1C365303, 0x40EF2D37, 0x65FD5E49,
    0xD6057177, 0x904ECE93, 0x1C38024F, 0x98FD323B,
    0xE3061AE7, 0xA39B0FA1, 0x9797F25F, 0xE4444563,
}

function Rand:new()
	self.seed = 0
end

---@param seed string|number?
function Rand:set_fixed_seed(seed)
	seed = seed or ""
	if type(seed) == "string" then
		local result = BASE_SEED
		local adjust = ADJUST
		for _, c in ipairs({seed:byte(1, #seed)}) do
			result = (HASH_TABLE[math.floor(c / 16) % 16] - HASH_TABLE[c % 16]) ^ (adjust + result)
			adjust = 33 * adjust + result + c + 3
		end
		if result == 0 then result = 1 end
		self.seed = result
	elseif type(seed) == "number" then
		self.seed = math.floor(seed)
	end
end

---@return integer
function Rand:rand()
	self.seed = MULTIPLIER * self.seed + 1
	return bit.band(bit.rshift(self.seed, 16), 0xFFFF)
end

---@param low integer
---@param high integer
---@return integer
function Rand:randbetween(low, high)
	return low + self:rand() % (high - low + 1)
end

---@param tbl any[]
---@return integer
function Rand:randindex(tbl)
	return 1 + self:rand() % (#tbl)
end

return Rand
