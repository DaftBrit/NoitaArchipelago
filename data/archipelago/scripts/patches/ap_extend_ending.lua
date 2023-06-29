local function ap_extend_ending()
	local endpoint_underground = EntityGetWithTag( "ending_sampo_spot_underground" )
	local endpoint_mountain = EntityGetWithTag( "ending_sampo_spot_mountain" )
	local orb_count = GameGetOrbCountThisRun()
	local entity_id = GetUpdatedEntityID()
	local ap_x, ap_y = EntityGetTransform(entity_id)

	if ( #endpoint_underground > 0 ) then
		local endpoint_id = endpoint_underground[1]
		local ex, ey = EntityGetTransform( endpoint_id )
		local distance = math.abs(ap_x - ex) + math.abs(ap_y - ey)

		if (distance < 32) then
			--normal ending
			GameAddFlagRun("ap_greed_ending")
		end

	elseif ( #endpoint_mountain > 0 ) then
		local endpoint_id = endpoint_mountain[1]
		local ex, ey = EntityGetTransform( endpoint_id )
		local distance = math.abs(ap_x - ex) + math.abs(ap_y - ey)

		if (distance < 32) then
			if (orb_count >= 34) then
				-- yendor ending
				print("red pixel pog")
				GameAddFlagRun("ap_yendor_ending")
			end
			if (orb_count >= 33) then
				-- peaceful ending
				GameAddFlagRun("ap_peaceful_ending")
			end
			if (orb_count >= 11) then
				-- pure ending
				GameAddFlagRun("ap_pure_ending")
			elseif (orb_count < 33) then
				--toxic ending or ng+
				print(GameGetOrbCountThisRun())
				print("wrong ending, get greened on nerd or go to ng+ I guess")
			end
		end
	end
	dofile_once("data/entities/animals/boss_centipede/ending/sampo_start_ending_sequence.lua")
end

ap_extend_ending()
