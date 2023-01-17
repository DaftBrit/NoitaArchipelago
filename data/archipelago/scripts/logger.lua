
local function prep_log_msg(msg)
	return os.date("%H:%M:%S") .. " [AP] " .. msg
end

local Logger = {}

function Logger.Info(msg)
	print(prep_log_msg(msg))
end

function Logger.Warn(msg)
	print_error(prep_log_msg(msg))
end

function Logger.Error(msg)
	Logger.Warn(msg)
	GamePrint(msg)	-- TODO red colour
end

return Logger
