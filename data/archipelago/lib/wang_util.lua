local Object = dofile("data/archipelago/lib/classic/classic.lua")

---@class WangUtil : Object
---@field filename string
---@field id integer
---@field width integer
---@field height integer
local WangUtil = Object:extend()

---@class Frame
---@field x integer
---@field y integer
---@field width integer
---@field height integer
---@field valid boolean

---@param wang_filename string
function WangUtil:new(wang_filename)
	self.filename = wang_filename
	if not ModImageDoesExist(wang_filename) then
		self.invalid = true
		return
	end

	local id, w, h = ModImageMakeEditable(wang_filename, 1, 1)
	self.id = id
	self.width = w
	self.height = h
end

---@param x integer
---@param y integer
---@return unsigned_integer
function WangUtil:GetPixel(x, y)
	return ModImageGetPixel(self.id, x, y)
end

---comment
---@param x integer
---@param y integer
---@param color unsigned_integer
function WangUtil:SetPixel(x, y, color)
	ModImageSetPixel(self.id, x, y, bit.tobit(color))
end

---@param x integer
---@param y integer
---@return boolean
function WangUtil:IsAir(x, y)
	if x >= self.width or y >= self.height then return false end
	return self:GetPixel(x, y) == 0
end

---@param x integer
---@param y integer
---@return boolean
function WangUtil:IsTerrain(x, y)
	if x >= self.width or y >= self.height then return false end
	return self:GetPixel(x, y) == bit.tobit(0xFFFFFFFF)
end

---If the pixel is neither air nor common terrain (a material, spawn marker, etc)
---@param x integer
---@param y integer
---@return boolean
function WangUtil:IsMarker(x, y)
	if x >= self.width or y >= self.height then return false end
	local px = self:GetPixel(x, y)
	return px ~= 0 and px ~= bit.tobit(0xFFFFFFFF)
end

---@param x integer
---@param y integer
---@return integer
---@return integer
function WangUtil:FrameSize(x, y)
	local width = 1
	local height = 1
	while x + width < self.width and not self:IsTerrain(x + width, y) do
		width = width + 1
	end
	while y + height < self.height and not self:IsTerrain(x, y + height) do
		height = height + 1
	end
	return width, height
end

---@return Frame
function WangUtil:FirstFrame()
	local frame = { x = 0, y = 0, width = 0, height = 0 }
	return self:NextFrame(frame)
end

---@param frame Frame
---@return Frame
function WangUtil:NextFrame(frame)
	local x = frame.x
	local y = frame.y
	local valid = self:IsMarker(x, y)
	if valid then
		x = frame.x + frame.width
		while x < self.width and not self:IsMarker(x, y) do
			x = x + 1
		end
		if x >= self.width then valid = false end
	end

	if not valid then
		valid = true
		x = 0
		y = frame.y + frame.height
		while y < self.height and not self:IsMarker(x, y) do
			y = y + 1
		end
		if y >= self.width then valid = false end
	end

	local width, height = self:FrameSize(x, y)
	return { x = x, y = y, width = width, height = height, valid = valid }
end

local SPIRAL_ITER = {
	{ x = 1, y = 0, add = 0 },
	{ x = 0, y = -1, add = 1 },
	{ x = -1, y = 0, add = 0 },
	{ x = 0, y = 1, add = 1 },
}

--- Finds an open spot to place something using a spiral search from the center of the given frame
---@param frame Frame
---@return integer x
---@return integer y
function WangUtil:FindOpenPosition(frame)
	local rad_x = math.floor((frame.width - 2) / 2)
	local rad_y = math.floor((frame.height - 2) / 2)
	local start_x = frame.x + 1 + rad_x
	local start_y = frame.y + 1 + rad_y

	local total_iterations = math.min(rad_x, rad_y) - 1

	local x = start_x
	local y = start_y

	local iter = 1
	for _ = 1, total_iterations do
		for step = 1,4 do
			for _i = 1,iter do
				if self:IsAir(x + frame.x, y + frame.y) then
					return x, y
				end

				x = x + SPIRAL_ITER[step].x
				y = y + SPIRAL_ITER[step].y
			end

			iter = iter + SPIRAL_ITER[step].add
		end
	end
	return start_x, start_y
end

---Searches downwards for a floor and returns its position.
---@param x integer
---@param y integer
---@param frame Frame
---@return integer x
---@return integer y
function WangUtil:FindFloor(x, y, frame)
	while y - frame.y < frame.height - 1 and not self:IsTerrain(x, y) do
		y = y + 1
	end
	while y - frame.y > 1 and not self:IsAir(x, y) do
		y = y - 1
	end
	return x, y
end

--- Injects a fixed pixel into an open space in every room.
---@param color unsigned_integer
function WangUtil:InjectOpenPixel(color)
	local frame = self:FirstFrame()
	print_error(string.format("Frame: %d, %d (%d, %d)", frame.x, frame.y, frame.width, frame.height))
	while frame.valid do
		local open_x, open_y = self:FindOpenPosition(frame)
		local x, y = self:FindFloor(open_x, open_y, frame)

		print_error(string.format("Frame: %d, %d (%d, %d) open at %d, %d (originally %d, %d)", frame.x, frame.y, frame.width, frame.height, open_x, open_y, x, y))

		self:SetPixel(x, y, color)

		frame = self:NextFrame(frame)
	end
end

return WangUtil
