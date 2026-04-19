function astral.compute_moon()
	local data = astral.data
	local constants = astral.constants
	local moon_day = core.get_day_count() + astral.day_offset
	if core.get_timeofday() > 0.5 then
		moon_day = moon_day + 1
	end

	data.moon_visible = true
	data.moon_phase = moon_day % constants.MOON_PHASE_COUNT

	local cycle_count = math.floor(moon_day / constants.MOON_PHASE_COUNT)
	data.month = 1 + cycle_count % #astral.month_cycle
	data.special_month = astral.month_cycle[data.month].special

	local config = astral.special_moon_config[data.special_month]
	if data.special_month == "normal" or not config or config.at_phase ~= data.moon_phase then
		data.special_moon = "normal"
		data.moon_texture = "moon-" .. data.moon_phase .. ".png"
		data.moon_scale = constants.NORMAL_MOON_SCALE
		data.night_sky_color = astral.moon_phase_sky_colors[data.moon_phase]
		data.night_horizon_color = astral.moon_phase_horizon_colors[data.moon_phase]
		data.light_ratio = astral.moon_phase_light_ratios[data.moon_phase]
		data.star_color = constants.NORMAL_STAR_COLOR
		data.cloud_density = constants.NORMAL_CLOUD_DENSITY

		-- Hide moon during solar events (around phase 0)
		if astral.special_sun_config[data.special_month] then
			if data.moon_phase == 0 or data.moon_phase == 1 or data.moon_phase == 7 then
				data.moon_visible = false
			end
		end

		return
	end

	data.special_moon = data.special_month
	data.moon_texture = config.texture
	if config.not_visible then data.moon_visible = false end
	data.moon_scale = config.scale
	data.night_sky_color = config.sky_color
	data.night_horizon_color = config.horizon_color
	data.light_ratio = config.light_ratio
	data.star_color = config.star_color or constants.NORMAL_STAR_COLOR
	data.cloud_density = 0.2
end

function astral.compute_sun()
	local data = astral.data
	local constants = astral.constants
	local sun_day = core.get_day_count() + astral.day_offset
	local local_moon_phase = sun_day % constants.MOON_PHASE_COUNT
	local cycle_count = math.floor(sun_day / constants.MOON_PHASE_COUNT)
	local local_month = 1 + cycle_count % #astral.month_cycle
	local local_special_month = astral.month_cycle[local_month].special

	local config = astral.special_sun_config[local_special_month]
	if local_special_month == "normal" or not config or config.at_phase ~= local_moon_phase then
		data.special_sun = "normal"
		data.sun_texture = "sun.png"
		data.sun_scale = constants.NORMAL_SUN_SCALE
		data.day_sky_color = constants.NORMAL_DAY_SKY_COLOR
		data.day_horizon_color = constants.NORMAL_DAY_HORIZON_COLOR
		data.dawn_sky_color = constants.NORMAL_DAWN_SKY_COLOR
		data.dawn_horizon_color = constants.NORMAL_DAWN_HORIZON_COLOR
		data.star_day_opacity = 0.0
		return
	end

	data.special_sun = local_special_month
	data.sun_texture = config.texture or "sun.png"
	data.sun_scale = config.scale or constants.NORMAL_SUN_SCALE
	data.day_sky_color = config.sky_color or constants.NORMAL_DAY_SKY_COLOR
	data.day_horizon_color = config.horizon_color or constants.NORMAL_DAY_HORIZON_COLOR
	data.dawn_sky_color = config.sky_color or constants.NORMAL_DAWN_SKY_COLOR
	data.dawn_horizon_color = config.horizon_color or constants.NORMAL_DAWN_HORIZON_COLOR
	data.star_day_opacity = config.star_day_opacity or 0.0
end

function astral.compute_astral_event()
	local data = astral.data
	local time_of_day = core.get_timeofday()
	local moon_config = astral.special_moon_config[data.special_moon]
	local sun_config = astral.special_sun_config[data.special_sun]

	if data.special_moon ~= "normal" and moon_config and not moon_config.no_astral_event and (time_of_day < 0.21 or time_of_day > 0.79) then
		data.astral_event = data.special_moon
		data.astral_event_name = moon_config.name
	elseif data.special_sun ~= "normal" and sun_config and not sun_config.no_astral_event and time_of_day > 0.2 and time_of_day < 0.8 then
		data.astral_event = data.special_sun
		data.astral_event_name = sun_config.name
	else
		data.astral_event = "none"
		data.astral_event_name = "none"
	end
end

function astral.trigger_phase_callbacks()
	local data = astral.data
	local time = core.get_timeofday()

	-- Determine the currently active event or phase name and its object type
	local current_phase
	local is_moon = false
	local is_sun = false

	if data.special_moon ~= "normal" then
		current_phase = data.special_moon
		is_moon = true
	elseif data.special_sun ~= "normal" then
		current_phase = data.special_sun
		is_sun = true
	else
		current_phase = "phase_" .. data.moon_phase
		is_moon = true
	end

	-- Moons rise around sunset (0.78), Suns rise around sunrise (0.2)
	local has_risen = false
	if is_moon then
		if time > 0.78 or time < 0.22 then
			has_risen = true
		end
	elseif is_sun then
		if time > 0.2 and time < 0.8 then
			has_risen = true
		end
	end

	if has_risen and astral.last_notified_phase ~= current_phase then
		local old_phase = astral.last_notified_phase
		astral.last_notified_phase = current_phase

		-- Trigger for specific special phase (e.g. "blood_moon")
		if astral.phase_callbacks[current_phase] then
			for _, cb in ipairs(astral.phase_callbacks[current_phase]) do
				cb(current_phase, old_phase)
			end
		end

		-- Also trigger for the numerical phase (e.g. "phase_4")
		local num_phase = "phase_" .. data.moon_phase
		if current_phase ~= num_phase and astral.phase_callbacks[num_phase] then
			for _, cb in ipairs(astral.phase_callbacks[num_phase]) do
				cb(num_phase, old_phase)
			end
		end
	end
end

function astral.update_all_players(dtime)
	astral.compute_moon()
	astral.compute_sun()
	astral.compute_astral_event()
	astral.trigger_phase_callbacks()
	for _, player in ipairs(core.get_connected_players()) do
		astral.set_player_sky(player)
		if astral.update_player_ratio then
			astral.update_player_ratio(player, dtime)
		end
	end
end
