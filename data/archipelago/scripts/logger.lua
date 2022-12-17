
local function prep_log_msg(msg)
	return os.date("%H:%M:%S") .. " [AP] " .. msg
end

return {
	Info = function(msg)
		print(prep_log_msg(msg))
	end,

	Warn = function(msg)
		print_error(prep_log_msg(msg))
	end,

	Error = function(msg)
		print_error(prep_log_msg(msg))
		GamePrint(msg)	-- TODO red colour
	end,
}
