local endpoint_underground = EntityGetWithTag( "ending_sampo_spot_underground" )
local endpoint_mountain = EntityGetWithTag( "ending_sampo_spot_mountain" )
local orb_count = GameGetOrbCountThisRun()

local entity_id = GetUpdatedEntityID()
local x, y = EntityGetTransform(entity_id)

if(doing_newgame_plus == false) then
    print(tostring(endpoint_underground))
    if(orb_count >= 33) then
        --33 orb ending
        if (orb_count > 33) then
        --34 orb ending
        end

        local distance_from_mountain = 1000

        if(#endpoint_mountain > 0) then
            local ex, ey = EntityGetTransform(endpoint_mountaion[1])
            distance_from_mountain = math.abs(x - ex) + math.abs(y-ey)
        end

        if(distance_from_mountain < 32) then
        --peaceful ending
        end
    end

	elseif ( #endpoint_underground > 0 ) then
        local endpoint_id = endpoint_underground[1]
		local ex, ey = EntityGetTransform( endpoint_id )
		local distance = math.abs(x - ex) + math.abs(y - ey)
		
		if (distance < 32) then
        --normal ending
            print("normal ending was gotten here and this script append works")
        end

	elseif ( #endpoint_mountain > 0 ) then
		local endpoint_id = endpoint_mountain[1]
		local ex, ey = EntityGetTransform( endpoint_id )
		
		local distance = math.abs(x - ex) + math.abs(y - ey)
		
		if (distance < 32) then
        --secret ending?
        end
end