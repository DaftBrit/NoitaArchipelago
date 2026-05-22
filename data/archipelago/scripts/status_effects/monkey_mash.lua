dofile_once("data/archipelago/scripts/ap_utils.lua")

local player = EntityGetRootEntity(GetUpdatedEntityID())
local player_x, player_y = EntityGetTransform(player)
local controls = EntityGetFirstComponentIncludingDisabled(player, "ControlsComponent")
if controls == nil then return end

ComponentSetValue2(controls, "enabled", false)

local all_button_names = {
	"Fire", "Fire2", "Action", "Throw", "Interact", "Left", "Right", "Up", "Down", "Jump", "Fly", "ChangeItemR", "ChangeItemL", "Inventory", "DropItem", "Kick", "Eat"
}

local monkey_button_names = {
	"Fire", "Fire2", "Interact", "Left", "Right", "Fly", "ChangeItemR", "ChangeItemL", "Inventory", "Kick", "Eat"
}

local instant_switch_names = {
	Fire = true,
	Interact = true,
	ChangeItemR = true,
	ChangeItemL = true,
	Kick = true
}

local function ReleaseButton(name)
	ComponentSetValue2(controls, "mButtonDown" .. name, false)
	if name == "ChangeItemR" or name == "ChangeItemL" then
		ComponentSetValue2(controls, "mButtonCount" .. name, 0)
	end
end

local function ReleaseAllButtons()
	for _,name in ipairs(all_button_names) do
		ReleaseButton(name)
	end
end

local function PressOnly(name, norelease)
	if not norelease then
		ReleaseAllButtons()
	end
	ComponentSetValue2(controls, "mButtonDown" .. name, true)
	ComponentSetValue2(controls, "mButtonFrame" .. name, GameGetFrameNum())

	if name == "ChangeItemR" or name == "ChangeItemL" then
		ComponentSetValue2(controls, "mButtonCount" .. name, 1)
	end
	if name == "Jump" or name == "Fly" then
		PressOnly("Up", true)
	elseif name == "Eat" then
		PressOnly("Down", true)
	end
end

local function AimAt(x, y)
	ComponentSetValue2(controls, "mAimingVector", x, y)
	ComponentSetValue2(controls, "mMousePosition", player_x + x, player_y + y)
	if x ~= 0 or y ~= 0 then
		local len = math.sqrt(x * x + y * y)
		ComponentSetValue2(controls, "mAimingVectorNormalized", x / len, y / len)
	else
		ComponentSetValue2(controls, "mAimingVectorNormalized", 0, 0)
	end
end

local function OpenInventory()
	local inv_ui = EntityGetFirstComponentIncludingDisabled(player, "InventoryGuiComponent")
	if inv_ui ~= nil then
		if not ComponentGetValue2(inv_ui, "mActive") then
			ComponentSetValue2(inv_ui, "mActive", true)
			GamePlaySound("data/audio/Desktop/ui.bank", "ui/inventory_open", player_x, player_y)
		end
	end
end

local function CloseInventory()
	local inv_ui = EntityGetFirstComponentIncludingDisabled(player, "InventoryGuiComponent")
	if inv_ui ~= nil then
		if ComponentGetValue2(inv_ui, "mActive") then
			ComponentSetValue2(inv_ui, "mActive", false)
			GamePlaySound("data/audio/Desktop/ui.bank", "ui/inventory_close", player_x, player_y)
		end
	end
end


-- Randomize inputs
if DirConsistency == nil then DirConsistency = 0 end
if Input == nil or GameGetFrameNum() % 12 == 0 then
	if Input == "Inventory" then CloseInventory() end

	local x, y = EntityGetTransform(GetUpdatedEntityID())
	SetRandomSeed(x, y + GameGetFrameNum())
	---@type string?
	Input = monkey_button_names[Random(1, #monkey_button_names)]

	if DirConsistency % 6 == 0 then
		TargetX = Random(-50,50)
		TargetY = Random(-50,50)
		MoveTargetX = Random() * 2 - 1
		MoveTargetY = Random() * 2 - 1
		DirConsistency = 0
	end
	DirConsistency = DirConsistency + 1
end

-- Process inputs

AimAt(TargetX, TargetY)
TargetX = TargetX + MoveTargetX
TargetY = TargetY + MoveTargetY

if Input == "ChangeItemR" then
	SwitchInventoryItem(1)
elseif Input == "ChangeItemL" then
	SwitchInventoryItem(-1)
elseif Input == "Inventory" then
	OpenInventory()
else
	PressOnly(Input)
end

if instant_switch_names[Input] then
	Input = nil
end
