local Log = dofile("data/archipelago/scripts/logger.lua") ---@type Logger
dofile_once("data/archipelago/scripts/ap_utils.lua")

---@type string[]?
local chaos_fungal_shift_pool = nil
local banned_fungal_list = {
	rat_powder = true,
	fungus_powder = true,
	fungus_powder_bad = true,
	monster_powder_test = true,
	rock_hard = true,
	rock_hard_border = true,
}

local function InitFungalPool()
	if chaos_fungal_shift_pool ~= nil then return end
	chaos_fungal_shift_pool = {}

	-- Same pool as fungal pain
	---@type string[][]
	local all_materials = {
		CellFactory_GetAllLiquids(false),
		CellFactory_GetAllSands(false),
		CellFactory_GetAllGases(false),
		CellFactory_GetAllFires(false),
	}

	for _, category in ipairs(all_materials) do
		for _, material in ipairs(category) do
			local id = CellFactory_GetType(material)
			if not banned_fungal_list[material] and not CellFactory_HasTag(id, "[NO_FUNGAL_SHIFT]") and not CellFactory_HasTag(id, "[box2d]") then
				table.insert(chaos_fungal_shift_pool, material)
			end
		end
	end
end

local already_has_fungal_icon = false
local function HasFungalShiftIcon(entity)
	if already_has_fungal_icon then return true end

	if entity == nil then return false end
	local children = EntityGetAllChildren(entity) or {}
	for _, it in ipairs(children) do
		if (EntityGetName(it) == "fungal_shift_ui_icon") then
			already_has_fungal_icon = true
			return true
		end
	end
	return false
end

local function AddFungalShiftIcon()
	local player = get_player()
	if player == nil or HasFungalShiftIcon(player) then return end

	local icon_entity = EntityCreateNew("fungal_shift_ui_icon")
	EntityAddComponent2(icon_entity, "UIIconComponent", {
		name = "$status_reality_mutation",
		description = "$statusdesc_reality_mutation",
		icon_sprite_file = "data/ui_gfx/status_indicators/fungal_shift.png"
	})
	EntityAddChild(player, icon_entity)
end

function ChaosFungalShift()
	InitRandomSeed()
	InitFungalPool()

	-- Randomize materials
	local from_material = chaos_fungal_shift_pool[Random(1, #chaos_fungal_shift_pool)]
	local to_material = nil
	for _ = 1,1000 do
		to_material = chaos_fungal_shift_pool[Random(1, #chaos_fungal_shift_pool)]
		if to_material ~= from_material then break end
	end
	if to_material == from_material then
		Log.Error("Failed to get a fungal shift material")
		return
	end

	-- Convert
	local from_id = CellFactory_GetType(from_material)
	local to_id = CellFactory_GetType(to_material)
	Log.Info(CellFactory_GetUIName(from_id) .. " -> " .. CellFactory_GetUIName(to_id))
	ConvertMaterialEverywhere(from_id, to_id)

	-- Effects
	local x, y = get_spawn_position()
	GameTriggerMusicFadeOutAndDequeueAll(5.0)
	GameTriggerMusicEvent("music/oneshot/tripping_balls_01", false, x, y)

	for _ = 1,3 do
		EntityLoad("data/entities/particles/treble_eye.xml", x + Randomf(-120, 120), y + Randomf(-120, 120))
	end

	local from_material_str = GameTextGetTranslatedOrNot(CellFactory_GetUIName(from_id))
	GamePrint(GameTextGet("$logdesc_reality_mutation", from_material_str))
	AddFungalShiftIcon()
end
