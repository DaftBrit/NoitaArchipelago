---@class UUID
local UUID = {
	num_gens = 0
}

-- Modified from https://gist.github.com/jrus/3197011
---@return string
function UUID.generate()
	local year, month, day, hour, minute, second = GameGetDateAndTimeUTC()
	local rng = year * 10000000 + month * 1000000 + day * 100000 + hour * 10000 + minute * 1000 + second * 100
	rng = rng + GameGetRealWorldTimeSinceStarted() * 100 + GameGetFrameNum() * 10 + UUID.num_gens
	math.randomseed(math.floor(rng))
	UUID.num_gens = UUID.num_gens + 1

    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    local result = template:gsub('[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
	return result
end

return UUID
