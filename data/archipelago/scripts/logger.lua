
---Timestamps and tags a log message.
---@param msg string
---@return string
local function prep_log_msg(msg)
	local _, _, _, hour, minute, second = GameGetDateAndTimeLocal()
	return string.format("%02d:%02d:%02d", hour, minute, second) .. " [AP] " .. msg
end

---@class Logger
local Logger = {}

---Info message, won't be printed if log verbosity is off
---@param msg any
function Logger.Info(msg)
	print(prep_log_msg(msg))
end

---Warn message, always printed to logger.txt
---@param msg string
function Logger.Warn(msg)
	print_error(prep_log_msg(msg))
end

---Error message, always printed to logger.txt and in-game messages
---@param msg string
function Logger.Error(msg)
	Logger.Warn(msg)
	GamePrint(msg)	-- TODO red colour
end

return Logger
