
local player = EntityGetRootEntity(GetUpdatedEntityID())

local controls = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")
if controls == nil then return end

ComponentSetValue2(controls, "input_latency_frames", 0)
