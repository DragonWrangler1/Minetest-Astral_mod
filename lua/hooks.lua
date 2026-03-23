local timer = 0
local cal_timer = 0

minetest.register_globalstep(function(dtime)
	-- Update sky and light ratios every step for smoothness and instant transitions
	for _, player in ipairs(minetest.get_connected_players()) do
		astral.set_player_sky(player)
		astral.update_player_ratio(player, dtime)
	end

	-- Update calendar items and entities every 10 seconds
	cal_timer = cal_timer + dtime
	if cal_timer > 10 then
		for _, player in ipairs(minetest.get_connected_players()) do
			astral.update_calendar_item(player)

			local ppos = player:get_pos()
			local nodes = minetest.find_nodes_in_area(
				{x=ppos.x-12, y=ppos.y-12, z=ppos.z-12},
				{x=ppos.x+12, y=ppos.y+12, z=ppos.z+12},
				{"group:calendar"}
			)
			for _, npos in ipairs(nodes) do
				astral.update_calendar_node_entity(npos)
			end
		end
		cal_timer = 0
	end

	-- Update sky parameters every 2 seconds
	timer = timer + dtime
	if timer < 2 then return end
	astral.update_all_players(dtime)
	timer = 0
end)

minetest.register_on_joinplayer(function(player)
	-- Recompute once on join to ensure data is absolutely current for this player
	astral.compute_moon()
	astral.compute_sun()
	astral.compute_astral_event()

	astral.set_player_sky(player, true)
	astral.update_player_ratio(player, nil, true)
	astral.update_calendar_item(player)
end)
