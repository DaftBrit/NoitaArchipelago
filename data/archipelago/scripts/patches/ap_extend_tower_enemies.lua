local function ap_extend_tower_enemies()
	local ap_old_spawn_any_enemy = spawn_any_enemy
	spawn_any_enemy = function(x, y)
		if Random(1, 99) == 1 then
			EntityLoad("data/entities/animals/ap_chest_mimic.xml")
		else
			ap_old_spawn_any_enemy(x, y)
		end
	end
end

ap_extend_tower_enemies()
