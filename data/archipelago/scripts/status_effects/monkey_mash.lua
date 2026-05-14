local player = EntityGetRootEntity(GetUpdatedEntityID())
local player_x, player_y = EntityGetTransform(player)

---@param tbl any[]
---@param itm any
---@return integer
local function find_item_index(tbl, itm)
	for i,v in ipairs(tbl) do
		if v == itm then return i end
	end
	return 1
end

local function switch_inventory_item(direction)
	local inventory_comp = EntityGetFirstComponentIncludingDisabled(player, "Inventory2Component")
	if inventory_comp == nil then return end

	local active_item = ComponentGetValue2(inventory_comp, "mActiveItem")
	local actual_active_item = ComponentGetValue2(inventory_comp, "mActualActiveItem")

	local children = EntityGetAllChildren(player) or {}
	local inventory_list = {}
	for _,child in ipairs(children) do
		if EntityGetName(child) == "inventory_quick" then
			inventory_list = EntityGetAllChildren(child) or {}
		end
	end
	if #inventory_list == 0 then return end

	local idx = find_item_index(inventory_list, active_item) - 1
	local next_item = inventory_list[(#inventory_list + idx + direction) % #inventory_list + 1]

	EntitySetComponentsWithTagEnabled(active_item, "enabled_in_hand", false)
	EntitySetComponentsWithTagEnabled(actual_active_item, "enabled_in_hand", false)
	EntitySetComponentsWithTagEnabled(next_item, "enabled_in_hand", true)
	ComponentSetValue2(inventory_comp, "mActiveItem", next_item)
	ComponentSetValue2(inventory_comp, "mActualActiveItem", 0)
	ComponentSetValue2(inventory_comp, "mForceRefresh", true)
	GamePlaySound("data/audio/Desktop/ui.bank", "ui/item_equipped", player_x, player_y)
end

local controller = EntityGetFirstComponentIncludingDisabled(player, "CharacterDataComponent")
local shooter = EntityGetFirstComponentIncludingDisabled(player, "PlatformShooterPlayerComponent")
if controller == nil or shooter == nil then return end

local vx, vy = ComponentGetValue2(controller, "mVelocity")

if Input == nil or GameGetFrameNum() % 12 == 0 then
	local x, y = EntityGetTransform(GetUpdatedEntityID())
	SetRandomSeed(x, y + GameGetFrameNum())
	---@type integer?
	Input = Random(0, 9)
end

-- Input == 0	-- Sleep
if Input == 1 then	-- Left
	if vx > -60 then
		ComponentSetValue2(controller, "mVelocity", -60, vy)
	end
elseif Input == 2 then	-- Right
	if vx < 60 then
		ComponentSetValue2(controller, "mVelocity", 60, vy)
	end
elseif Input == 3 then	-- Jump
	if vy > -60 and ComponentGetValue2(controller, "is_on_ground") then
		ComponentSetValue2(controller, "mVelocity", vx, -60)
	end
elseif Input == 4 then	-- Crouch
	ComponentSetValue2(shooter, "mCrouching", true)
elseif Input == 5 then	-- Shoot/Spray
	ComponentSetValue2(shooter, "mForceFireOnNextUpdate", true)
	-- TODO spray
elseif Input == 6 then	-- Next slot
	switch_inventory_item(1)
	Input = nil
elseif Input == 7 then	-- Prev slot
	switch_inventory_item(-1)
	Input = nil
elseif Input == 8 then	-- Open inventory
	local inv_ui = EntityGetFirstComponentIncludingDisabled(player, "InventoryGuiComponent")
	if inv_ui ~= nil and ComponentGetValue2(inv_ui, "mActive") == false then
		ComponentSetValue2(inv_ui, "mActive", true)
		GamePlaySound("data/audio/Desktop/ui.bank", "ui/inventory_open", player_x, player_y)
	end
	Input = nil
elseif Input == 9 then	-- Close inventory
	local inv_ui = EntityGetFirstComponentIncludingDisabled(player, "InventoryGuiComponent")
	if inv_ui ~= nil and ComponentGetValue2(inv_ui, "mActive") == true then
		ComponentSetValue2(inv_ui, "mActive", false)
		GamePlaySound("data/audio/Desktop/ui.bank", "ui/inventory_close", player_x, player_y)
	end
	Input = nil
elseif Input == 10 then	-- Throw
	-- TODO
elseif Input == 11 then	-- Interact
	-- TODO
end
