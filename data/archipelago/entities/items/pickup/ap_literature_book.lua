dofile_once("data/archipelago/scripts/ap_utils.lua")

InitRandomSeed()
local entity = GetUpdatedEntityID()

local literature_pool = {
	{"$booktitle00", "$bookdesc00" },
	{"$booktitle01", "$bookdesc01" },
	{"$booktitle02", "$bookdesc02" },
	{"$booktitle03", "$bookdesc03" },
	{"$booktitle04", "$bookdesc04" },
	{"$booktitle05", "$bookdesc05" },
	{"$booktitle06", "$bookdesc06" },
	{"$booktitle07", "$bookdesc07" },
	{"$booktitle08", "$bookdesc08" },
	{"$booktitle09", "$bookdesc09" },
	{"$booktitle10", "$bookdesc10" },
	{"$booktitle_corpse", "$bookdesc_corpse" },
	{"$booktitle_tree", "$bookdesc_tree" },
	{"$menuupdatenotification_title", "$menureleasenotes_eawarning"},
	{"$item_weathercrystal_book", "$itemdesc_weathercrystal_book"},
	{"$menu_mods", "$menu_mods_help"},
	{"$booktitle_allspells", "$bookdesc_allspells"},
	{"$gamemode_dailyrun", "$gamemode_dailyrun_desc"},
	{"$action_nolla", "$menureleasenotes_noita10"},
	{"$booktitle_fisher", "$bookdesc_fisher"},
	{"$booktitle_mestari", "$bookdesc_mestari"},
	{"$log_dark_moon_altar", "$logdesc_dark_moon_altar"},
	{"$item_book_s_a", "$itemdesc_book_s_a"},
	{"$item_book_s_a", "$itemdesc_book_s_b"},
	{"$item_book_s_a", "$itemdesc_book_s_c"},
	{"$item_book_s_a", "$itemdesc_book_s_d"},
	{"$item_book_s_a", "$itemdesc_book_s_e"},
	{"$item_book_music_b", "$itemdesc_book_music_b"},
	{"$item_book_music_c", "$itemdesc_book_music_c"},
	{"$item_book_robot", "$itemdesc_book_robot"},
	{"$item_book_moon", "$itemdesc_book_moon"},
	{"$booktitle_barren", "$bookdesc_barren"},
	{"$ap_literature_1_name", "$ap_literature_1_desc"},
	{"$ap_literature_2_name", "$ap_literature_2_desc"},
	{"$ap_literature_3_name", "$ap_literature_3_desc"},
}

local literature = literature_pool[Random(1, #literature_pool)]

-- #####################
--         Text
-- #####################
for _,comp in ipairs(EntityGetComponentIncludingDisabled(entity, "UIInfoComponent") or {}) do
	ComponentSetValue2(comp, "name", literature[1])
end

for _,comp in ipairs(EntityGetComponentIncludingDisabled(entity, "ItemComponent") or {}) do
	ComponentSetValue2(comp, "item_name", literature[1])
	ComponentSetValue2(comp, "ui_description", literature[2])
end

for _,comp in ipairs(EntityGetComponentIncludingDisabled(entity, "AbilityComponent") or {}) do
	ComponentSetValue2(comp, "ui_name", literature[1])
end

-- #####################
--       Visuals
-- #####################
for _,comp in ipairs(EntityGetComponentIncludingDisabled(entity, "ParticleEmitterComponent") or {}) do
	EntityRemoveComponent(entity, comp)
end
