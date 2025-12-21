local nxml = dofile_once("data/archipelago/lib/nxml.lua") ---@type nxml

local Common = dofile("data/archipelago/ui/gift_translate_common.lua")
dofile_once("gun_actions")

local GiftTranslate = {}

local ItemMap = {
	-- Holdable items
	["sädekivi"] = { file = "entities/items/pickup/beamstone.xml" },
	["kiuaskivi"] = { file = "entities/items/pickup/brimstone.xml" },
	["broken wand"] = { file = "entities/items/pickup/broken_wand.xml" },
	["toasty egg"] = { file = "entities/items/pickup/egg_fire.xml" },
	["hollow egg"] = { file = "entities/items/pickup/egg_hollow.xml" },
	["chilly egg"] = { file = "entities/items/pickup/egg_purple.xml" },
	["slimy egg"] = { file = "entities/items/pickup/egg_slime.xml" },
	["wiggling egg"] = { file = "entities/items/pickup/egg_worm.xml" },
	["paha silmä"] = { file = "entities/items/pickup/evil_eye.xml" },
	["refreshing gourd"] = { file = "entities/items/pickup/gourd.xml" },
	["jar"] = { file = "entities/items/pickup/jar.xml" },
	["kuu"] = { file = "entities/items/pickup/moon.xml" },
	["kuulokivi"] = { file = "entities/items/pickup/musicstone.xml" },
	["chaos die"] = { file = "entities/items/pickup/physics_die.xml" },
	["cruel orb"] = { file = "entities/items/pickup/physics_gold_orb_greed.xml" },
	["shiny orb"] = { file = "entities/items/pickup/physics_gold_orb.xml" },
	["greed die"] = { file = "entities/items/pickup/physics_greed_die.xml" },
	["kakkakikkare"] = { file = "entities/items/pickup/poopstone.xml" },
	["potion"] = { file = "entities/items/pickup/potion_empty.xml" },
	["pouch"] = { file = "entities/items/pickup/powder_stash.xml" },
	["kammi"] = { file = "entities/items/pickup/safe_haven.xml" },
	["tannerkivi"] = { file = "entities/items/pickup/stonestone.xml" },
	["broken spell"] = { file = "entities/items/pickup/summon_portal_broken.xml" },
	["ukkoskivi"] = { file = "entities/items/pickup/thunderstone.xml" },
	["sauvan ydin"] = { file = "entities/items/pickup/wandstone.xml" },
	["vuoksikivi"] = { file = "entities/items/pickup/waterstone.xml" },

	-- Other stuff
	["worm crystal"] = { file = "entities/buildings/physics_worm_deflector_crystal.xml" },
}

for _, itemdata in pairs(ItemMap) do
	local xml = nxml.parse_file(itemdata.file)
	local itemComp = xml:first_of("ItemComponent")

	itemdata.icon = "data/archipelago/ui/games/ap.png"
	if itemComp then
		itemdata.icon = itemComp:get("ui_sprite") or itemdata.icon
	end
end

local meats = {
	["Meat"] = "meat",
	["Lightly-Cooked Meat"] = "meat_warm",
	["Cooked Meat"] = "meat_hot",
	["Fully-Cooked Meat"] = "meat_done",
	["Burned Meat"] = "meat_burned",
	["Ambiguous Meat"] = "meat_confusion",
	["Cursed Meat"] = "meat_cursed",
	["Dry Cursed Meat"] = "meat_cursed_dry",
	["Slimy Cursed Meat"] = "meat_slime_cursed",
	["Ethereal Meat"] = "meat_teleport",
	["Frog Meat"] = "meat_frog",
	["Meat of an Innocent Creature"] = "meat_helpless",
	["Rotten Meat"] = "rotten_meat",
	["Stinky Meat"] = "meat_polymorph_protection",
	["Wobbly Meat"] = "meat_fast",
	["Worm Meat"] = "meat_worm",
	["Slimy Meat"] = "meat_slime",
	["Green Slimy Meat"] = "meat_slime_green",
	["Toxic Meat"] = "rotten_meat_radioactive",
	["Unstable Meat"] = "meat_polymorph"
}


local function preprocess_gift(gift)
	-- TODO verify source game
	local result = {
		id = gift.ID,
		item_name = gift.ItemName:lower(),
		amount = gift.Amount or 1,
		value = gift.ItemValue,
		sender_slot = gift.SenderSlot,
		receiver_slot = gift.ReceiverSlot,
		trait = {},
		quality = {},
		duration = {},

		-- These are to be filled in gift processing to determine what it is
		spawn = {
			spawn_fn = nil,
			amount = nil,
			args = {},
			icon = nil,
		}
	}

	for _, trait in ipairs(gift.Traits) do
		result.trait[trait.Trait] = true
		result.quality[trait.Trait] = trait.Quality
		result.duration[trait.Trait] = trait.Duration
	end

	return result
end

-- TODO These will just be callback functions so we don't duplicate the if statements
local function spawn_material(x, y, quantity, material_name)
	GameCreateParticle(material_name, x, y, quantity, 0, 0, false)
end

local function spawn_entity(x, y, quantity, entity_name)
	for _=1,quantity do
		EntityLoad(entity_name, x, y)
	end
end

local function spawn_spell(quantity, spell_name, x, y)
	for _=1,quantity do
		CreateItemActionEntity(spell_name, x, y)
	end
end

local function apply_status(status_name, duration, x, y)
	-- TODO
end

-- materials is a list of (material, quantity) pairs
local function spawn_container(x, y, quantity, container_name, materials)
end

local function process_liquid(name, quantity)
	local internal_name = Common.GetInternalLiquidName(name);
	if internal_name == nil then return nil end
	return {
		fn = spawn_material,
		amount = (quantity or 1) * 1000,
		args = { internal_name },
		icon = Common.GetMaterialIcon(internal_name)
	}
end

local function process_powder(name, quantity)
	local internal_name = Common.GetInternalPowderName(name);
	if internal_name == nil then return nil end
	return {
		fn = spawn_material,
		amount = (quantity or 1) * 1000,
		args = { internal_name },
		icon = Common.GetMaterialIcon(internal_name)
	}
end

local function process_entity(gift)
	local entity_info = ItemMap[gift.item_name]
	local entity_file = entity_info.file

	if gift.item_name == "egg" then
		if gift.trait.red then
			entity_file = "entities/items/pickup/egg_red.xml"
		else
			entity_file = "entities/items/pickup/egg_monster.xml"
		end
	end

	if entity_file == nil then return nil end

	return {
		fn = spawn_entity,
		amount = gift.amount,
		args = { entity_file },
		icon = entity_info.icon,
	}
end

local function process_spell(name, quantity)
	local internal_name = Common.GetInternalSpellName(name);
	if internal_name == nil then return nil end
	return {
		fn = spawn_spell,
		amount = quantity,
		args = { internal_name },
		icon = Common.GetSpellIcon(internal_name)
	}
end

local function process_status(name, duration)
	-- TODO
end

local function process_container(name)
	-- TODO
end



function GiftTranslate.ProcessGift(gift_raw)
	local gift = preprocess_gift(gift_raw)

	-- Traits indicating top level items/entities
	if gift.trait.wand then
		-- TODO Noita Wand
	elseif gift.trait.spell then
		gift.spawn = process_spell(gift.item_name, gift.amount)
	elseif gift.trait.book then
		-- TODO Noita book/tablet
	end
	if gift.spawn then return end

	gift.spawn = process_entity(gift)
	if gift.spawn then return end

	-- Other traits where we guess what it is
	if gift.trait.flower then
		-- TODO flower material
	elseif gift.trait.vine then
		-- TODO vine material
	elseif gift.trait.grass or gift.trait.fiber then
		gift.spawn = process_powder("grass")
	elseif gift.trait.cooking then
		if gift.trait.meat then
			-- Fully-cooked meat
		else
		end
	elseif gift.trait.vegetable then
	elseif gift.trait.fruit then
	elseif gift.trait.egg then
		if gift.trait.heat then
			-- Toasty Egg
		elseif gift.trait.cold then
			-- Chilly Egg
		elseif gift.trait.radioactive then
			-- Slimy Egg
		elseif gift.trait.zombie then
			-- Egg (Hurtta)
		elseif gift.trait.fish then
			-- Egg with fish
		elseif gift.trait.monster then
			-- Egg (Red)
		elseif gift.trait.animal then
			-- Chicken or duck egg
		else
			-- Hollow Egg
		end
	elseif gift.trait.fish then
		-- feeeesh
	elseif gift.trait.zombie then
		-- Hurtta (charmed or no?)
	elseif gift.trait.monster then
		-- ??? will have to check other traits here
	elseif gift.trait.animal then
		-- TODO Animals
	elseif gift.trait.seed or gift.trait.seeds then
		-- Just use seed material for now until we dive into memeland
		gift.spawn = process_powder("seed")
	elseif gift.trait.coal then
		gift.spawn = process_powder("coal")
	elseif gift.trait.ore then
		if gift.trait.iron then
			-- Iron Ore
		elseif gift.trait.copper then
			gift.spawn = process_powder("copper")
		elseif gift.trait.silver then
			gift.spawn = process_powder("silver")
		elseif gift.trait.gold then
			gift.spawn = process_powder("gold")
		elseif gift.trait.radioactive then
			-- Radioactive ore
		elseif gift.trait.metal then
			gift.spawn = process_powder("metal dust")
		else
			-- Other ore
		end
	elseif gift.trait.iron then
		-- Iron material
	elseif gift.trait.copper then
		-- Copper material
	elseif gift.trait.steel then
		-- Steel material
	elseif gift.trait.silver then
		-- Silver material
	elseif gift.trait.gold then
		-- Gold
		if gift.trait.radioactive then
		else
		end
	elseif gift.trait.metal then
		-- Other metal
	elseif gift.trait.gem then
		-- Gems (we don't define any yet)
	elseif gift.trait.crystal then
		-- Crystals (we don't define any yet)
	elseif gift.trait.mineral then
		-- Minerals (we don't define any yet)
	elseif gift.trait.stone then
		-- TODO create stone item or use some stone material?
	elseif gift.trait.rock then
		-- Rock item
	elseif gift.trait.boulder then
		-- Just dump a boulder in the room for fun
	elseif gift.trait.resource then
		-- ??
	elseif gift.trait.meat then
		-- TODO further split this by Trap and Buff
		-- First check if it matches any one of ours
		if gift.trait.animal or gift.trait.fish then
			-- Meat of an innocent creature
		elseif gift.trait.radioactive then
			gift.spawn = process_powder("toxic meat")
		elseif gift.trait.buff then
			-- Fully-cooked meat, Stinky Meat, Wobbly Meat, Worm Meat
		elseif gift.trait.trap then
			-- Cursed Meat, Rotten Meat, Slimy Meat
		elseif gift.trait.heat then
			-- Cooked Meat?
		else
			-- Regular Meat
		end
	elseif gift.trait.food then
		-- Other food
	elseif gift.trait.bomb then
		-- TODO bomb spell or new item with limited stack?
	end
end


return GiftTranslate
