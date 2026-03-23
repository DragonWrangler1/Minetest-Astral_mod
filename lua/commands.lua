astral.set_phase = function(name_or_number)
	local target_phase = tonumber(name_or_number)
	local target_month = nil

	if not target_phase then
		-- Try to find by name
		local name = tostring(name_or_number):lower():gsub(" ", "_")

		-- Search in moon phase names first
		for i = 0, astral.constants.MOON_PHASE_COUNT - 1 do
			if astral.moon_phase_names[i]:lower():gsub(" ", "_") == name then
				target_phase = i
				break
			end
		end

		-- If still not found, search in special month cycles
		if not target_phase then
			for i, m in ipairs(astral.month_cycle) do
				if m.special:lower() == name then
					target_month = i
					local config = astral.special_moon_config[m.special] or astral.special_sun_config[m.special]
					if config then
						target_phase = config.at_phase
					else
						target_phase = 0 -- Default to phase 0 for normal special months
					end
					break
				end
			end
		end
	end

	if not target_phase then return false, "Phase or special event not found" end
	target_phase = math.floor(target_phase) % astral.constants.MOON_PHASE_COUNT

	local current_day = minetest.get_day_count()

	local new_offset
	if target_month then
		-- Need to find an offset that satisfies both month and phase
		new_offset = (target_month - 1) * astral.constants.MOON_PHASE_COUNT + target_phase - (current_day % (astral.constants.MOON_PHASE_COUNT * #astral.month_cycle))
	else
		-- Just set phase for current month
		local current_moon_day = current_day + astral.day_offset
		local current_phase = current_moon_day % astral.constants.MOON_PHASE_COUNT
		new_offset = astral.day_offset + (target_phase - current_phase)
	end

	astral.set_day_offset(new_offset)
	return true
end

minetest.register_privilege( "astral", {
	description = "Change astral features",
	give_to_singleplayer = false
})

minetest.register_chatcommand( "set_astral_day_offset", {
	params = "<offset>",
	description = "Set the astral day offset to the given value",
	privs = { astral = true },
	func = function( playername, params )
		if params == nil or params == "" then
			minetest.chat_send_player(playername, "Missing day offset number")
		else
			astral.set_day_offset( params )
		end
	end
})

minetest.register_chatcommand( "set_astral_phase", {
	params = "<phase name/number>",
	description = "Set the moon/sun phase or special event by name or number (0-7)",
	privs = { astral = true },
	func = function( playername, params )
		if params == nil or params == "" then
			minetest.chat_send_player(playername, "Missing phase name or number")
		else
			local success, msg = astral.set_phase( params )
			if success then
				minetest.chat_send_player(playername, "Astral phase set to: " .. params)
			else
				minetest.chat_send_player(playername, "Error: " .. (msg or "Unknown error"))
			end
		end
	end
})

minetest.register_chatcommand( "get_astral_day_offset", {
	description = "Get the astral day offset",
	privs = { astral = true },
	func = function( playername )
		minetest.chat_send_player(playername, "Astral day offset: " .. astral.day_offset )
	end
})

minetest.register_chatcommand( "get_astral_event", {
	description = "Display the current astral event",
	privs = { astral = true },
	func = function( playername )
		local id, name = astral.data.astral_event, astral.data.astral_event_name
		minetest.chat_send_player(playername, "Astral event: " .. name )
	end
})

minetest.register_chatcommand( "get_astral_day", {
	description = "Display the current astral day",
	privs = { astral = true },
	func = function( playername )
		local data = astral.data
		local month = data.month
		local moon_phase = data.moon_phase
		local moon_phase_name = astral.moon_phase_names[moon_phase]
		local special_sun, special_moon = data.special_sun, data.special_moon
		local event_name = data.astral_event_name
		
		minetest.chat_send_player(playername, "Astral day: " .. moon_phase_name .. " (" .. moon_phase .. ") of Month " .. month .. " -- special: ".. special_sun .. " / " .. special_moon .. " => " .. event_name )
	end
})
