local mod_storage = minetest.get_mod_storage()

-- Internal state
astral.data = {
	moon_phase = 0,
	moon_texture = "moon-0.png",
	moon_visible = true,
	moon_scale = 0.8,
	sun_texture = "sun.png",
	sun_scale = 3,
	month = 1,
	special_month = "normal",
	special_moon = "normal",
	special_sun = "normal",
	astral_event = "none",
	astral_event_name = "none",
	day_sky_color = "#8cbafa",
	day_horizon_color = "#9bc1f0",
	dawn_sky_color = "#b4bafa",
	dawn_horizon_color = "#bac1f0",
	night_sky_color = "#020508",
	night_horizon_color = "#010305",
	star_color = "#ebebff69",
	star_day_opacity = 0.0,
	cloud_density = 0.4,
	light_ratio = 0.15, -- Normal night ratio
}

astral.day_offset = mod_storage:get_int("astral_day_offset")
if astral.day_offset == 0 then
	astral.day_offset = math.random(1, 10000)
	mod_storage:set_int("astral_day_offset", astral.day_offset)
end

astral.set_day_offset = function(new_offset)
	astral.day_offset = math.floor(tonumber(new_offset) or 0)
	mod_storage:set_int("astral_day_offset", astral.day_offset)
	if astral.update_all_players then
		astral.update_all_players()
	end
end

astral.phase_callbacks = {}
function astral.register_on_phase(phase, callback)
	if not astral.phase_callbacks[phase] then
		astral.phase_callbacks[phase] = {}
	end
	table.insert(astral.phase_callbacks[phase], callback)
end

astral.last_notified_phase = ""
