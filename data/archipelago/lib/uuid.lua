---@class UUID
local UUID = {}

-- https://gist.github.com/jrus/3197011
---@return string
function UUID.generate()
	local year, month, day, hour, minute, second = GameGetDateAndTimeUTC()
	local rng = year * 100000 + month * 10000 + day * 1000 + hour * 100 + minute * 10 + second
	math.randomseed(rng)

    local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    local result = template:gsub('[xy]', function (c)
        local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
        return string.format('%x', v)
    end)
	return result
end

return UUID
