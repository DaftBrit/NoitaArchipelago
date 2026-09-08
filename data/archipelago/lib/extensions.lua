--- File for pure Lua helpers/extensions

if table ~= nil then
	---@param tbl table
	---@param elem any
	---@return boolean
	function table.contains(tbl, elem)
		for _, v in ipairs(tbl or {}) do
			if v == elem then return true end
		end
		return false
	end
end

if string ~= nil then
	---@param self string?
	---@return boolean
	function string:not_empty()
		return self ~= nil and self ~= ''
	end
end

if os ~= nil then
	---@param dirname string
	---@return boolean?
	local function dir_exists(dirname)
		-- Universal way of checking whether a file or directory exists
		local ok, err = os.rename(dirname, dirname)
		if not ok and err then
			if err:find("[Pp]ermission") then
					-- Permission denied, but it exists
					return true
			end
			error(err)
		end
		return ok
	end

	---@param dirname string
	function os.create_dir(dirname)
		-- Prevent console window from appearing if it already exists
		if dir_exists(dirname) then return end

		local code = os.execute("mkdir " .. dirname)
		if code ~= 0 then
			error("Failed to create cache directory '" .. dirname .. "'. Error code: " .. tostring(code))
		end
	end
end

if math ~= nil then
	---@param x number
	---@param y number
	---@return number
	function math.magnitude2(x, y)
		return x ^ 2 + y ^ 2
	end

	---@param x number
	---@param y number
	---@return number
	function math.magnitude(x, y)
		return math.sqrt(x ^ 2 + y ^ 2)
	end

	---@param x1 number
	---@param y1 number
	---@param x2 number
	---@param y2 number
	---@return number
	function math.distance2(x1, y1, x2, y2)
		return math.magnitude2(x2 - x1, y2 - y1)
	end

	---@param x1 number
	---@param y1 number
	---@param x2 number
	---@param y2 number
	---@return number
	function math.distance(x1, y1, x2, y2)
		return math.magnitude(x2 - x1, y2 - y1)
	end

	function math.map(value, old_min, old_max, new_min, new_max)
		return (value - old_min) * (new_max - new_min) / (old_max - old_min) + new_min;
	end
end
