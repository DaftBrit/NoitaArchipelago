dofile_once("data/scripts/perks/perk.lua")
dofile_once("data/archipelago/scripts/ap_utils.lua")
local item_table = dofile("data/archipelago/scripts/item_mappings.lua")
local AP = dofile("data/archipelago/scripts/constants.lua")

local worldOffsetX = -250
local worldOffsetY = -2500
local itemZones =  {
	[110006] = { x = 70, y = 306, w = 110 }, -- Wands 1-6
	[110007] = { x = 300, y = 306, w = 100 },
	[110008] = { x = 67, y = 245, w = 110 },
	[110009] = { x = 305, y = 245, w = 120 },
	[110010] = { x = 130, y = 168, w = 100 },
	[110011] = { x = 295, y = 168, w = 90 },

	[110012] = { x = 143, y = 360, w = 1}, -- Kentele

	[110028] = { x = 175, y = 387, w = 24 }, -- Heals
	[110029] = { x = 199, y = 387, w = 24 },

	[110025] = { x = 253, y = 387, w = 45 }, -- Powders

	[110030] = { x = 320, y = 387, w = 23 }, -- Misc
	[110031] = { x = 343, y = 387, w = 23 },
}

function APEggStartSpawn(item_counts)

	for item, quantity in pairs(item_counts) do

		print("SPAWNING:" .. item)
		if item_table[item].wand ~= nil then
			-- spawn the wands in an array inside the cave
			for i = 0, quantity - 1 do
				local item_to_spawn = item_table[item].items[Random(1, #item_table[item].items)]
				local wandx = worldOffsetX + itemZones[item].x + (itemZones[item].w * (i / quantity))
				local wandy = worldOffsetY + itemZones[item].y
				EntityLoad(item_to_spawn, wandx, wandy)
			end
			item_counts[item] = nil
		elseif item == AP.MAP_PERK_ID then
			-- spawn the map perk on the ground, in case you find it distracting
			perk_spawn(813, -96, item_table[item].perk)
			item_counts[item] = nil

		elseif item_table[item].perk ~= nil then
			-- give the player their perks
			for _ = 1, quantity do
				give_perk(item_table[item].perk)
			end
			item_table[item] = nil
		elseif item ~= AP.TRAP_ID then
			-- spawn the rest of the items on the cave floor
			for i = 0, quantity - 1 do
				local item_to_spawn = item_table[item].items[Random(1, #item_table[item].items)]
				local itemx = worldOffsetX + itemZones[item].x + (itemZones[item].w * (i / quantity))
				local itemy = worldOffsetY + itemZones[item].y
				EntityLoad(item_to_spawn, itemx, itemy)
			end
			item_counts[item] = nil
		end

	end

	local lightSource = EntityLoad("data/entities/props/physics_skateboard.xml", worldOffsetX + 235, worldOffsetY + 240)
	EntityAddTag(lightSource, "prop")
	EntityAddComponent2(lightSource, "LightComponent", {radius = 900, r = 100, g = 100, b = 255, blinking_freq = 1 })

	EntityLoad("data/archipelago/entities/buildings/ap_start_portal.xml", worldOffsetX + 110, worldOffsetY + 354)
	local returnPortal = EntityLoad("data/archipelago/entities/buildings/ap_start_portal.xml", 335, -200)
	local returnComponent = EntityGetFirstComponent(returnPortal, "TeleportComponent")
	ComponentSetValue2(returnComponent, "target", 0, -2320)

end