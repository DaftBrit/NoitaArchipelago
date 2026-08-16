---@class ImageUtil
local ImageUtil = {}

local WHITE_PX = 0xFFFFFFFF
local TRANSPARENT_PX = 0

---Checks if the given pixel is entirely transparent.
---@param px unsigned_integer
---@return boolean
function ImageUtil.IsTransparentPixel(px)
	return bit.band(px, 0xFF000000) == 0
end

---Checks if all passed in args exist as image files. True if they all exist.
---@param ... string
---@return boolean
function ImageUtil.Exists(...)
	local items = { ... }
	for _, item in ipairs(items) do
		if not ModImageDoesExist(item) then
			return false
		end
	end
	return true
end

---Overwrite a target image, replacing only non-transparent pixels. White gets replaced with transparent pixels.
---@param original string
---@param new string
function ImageUtil.OverwriteImagePartial(original, new)
	local orig_id, width, height = ModImageMakeEditable(original, 1, 1)
	local new_id, new_width, new_height = ModImageMakeEditable(new, 1, 1)

	if new_id == 0 then
		print_error("Failed to make our overwrite editable: " .. new)
		return
	end

	if width ~= new_width or height ~= new_height then
		print_error("UNEXPECTED IMAGE SIZE - another mod has altered the dimensions of " .. original)
		print_error("Offending mod: " .. ModImageWhoSetContent(original))
	end

	for y = 0, height-1 do
		for x = 0, width-1 do
			local px = ModImageGetPixel(new_id, x, y)
			if px == WHITE_PX then
				ModImageSetPixel(orig_id, x, y, TRANSPARENT_PX)
			elseif not ImageUtil.IsTransparentPixel(px) then
				ModImageSetPixel(orig_id, x, y, px)
			end
		end
	end
end

---Overwrites biome implementation, pass in material filename without extension and it automatically checks for and
---overwrites _visual and _background files.
---@param path string
---@param new_path string
function ImageUtil.OverwriteBiomeImplPartial(path, new_path)
	if ImageUtil.Exists(path .. ".png", new_path .. ".png") then
		ImageUtil.OverwriteImagePartial(path .. ".png", new_path .. ".png")
	end

	if ImageUtil.Exists(path .. "_visual.png", new_path .. "_visual.png") then
		ImageUtil.OverwriteImagePartial(path .. "_visual.png", new_path .. "_visual.png")
	end

	if ImageUtil.Exists(path .. "_background.png", new_path .. "_background.png") then
		ImageUtil.OverwriteImagePartial(path .. "_background.png", new_path .. "_background.png")
	end
end

return ImageUtil
