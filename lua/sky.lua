function astral.set_player_sky(player, force)
	local data = astral.data
	local pos = player:get_pos()
	local meta = player:get_meta()
	local last_sky = meta:get_string("astral_last_sky")
	local current_sky = ""

	if nether and nether.DEPTH_CEILING and nether.DEPTH_FLOOR and
			pos.y < nether.DEPTH_CEILING and pos.y > nether.DEPTH_FLOOR then
		current_sky = "nether"
		if last_sky ~= current_sky or force then
			player:set_sky({
				type = "plain",
				base_color = "#300808",
				clouds = false,
				stars = { count = 0 },
				moon = { visible = false },
				sun = {
					visible = false,
					sunrise_visible = false,
					sunrise = "astral_blank.png",
				}
			})
			-- Fallback
			player:set_stars({ count = 0 })
			player:set_moon({ visible = false })
			player:set_sun({
				visible = false,
				sunrise_visible = false,
				sunrise = "astral_blank.png",
			})
			player:set_clouds({ density = 0 })
			meta:set_string("astral_last_sky", current_sky)
		end
		return
	end

	-- Normal sky logic
	-- Cache colors and textures to avoid redundant set_sky calls which cause flickers
	local sun_config = astral.special_sun_config[data.special_sun]
	local sunrise_visible = true
	if sun_config and sun_config.sunrise_visible == false then
		sunrise_visible = false
	end

	current_sky = table.concat({
		data.day_sky_color, data.day_horizon_color,
		data.dawn_sky_color, data.dawn_horizon_color,
		data.night_sky_color, data.night_horizon_color,
		data.moon_texture, data.sun_texture,
		data.moon_visible and "v" or "h",
		data.moon_scale, data.sun_scale,
		data.star_color, data.star_day_opacity,
		data.cloud_density,
		sunrise_visible and "sv" or "sh"
	}, ",")

	if last_sky == current_sky and not force then return end

	player:set_sky({
		type = "regular",
		sky_color = {
			day_sky = data.day_sky_color,
			day_horizon = data.day_horizon_color,
			dawn_sky = data.dawn_sky_color,
			dawn_horizon = data.dawn_horizon_color,
			night_sky = data.night_sky_color,
			night_horizon = data.night_horizon_color
		},
		stars = {
			count = 7500,
			scale = 0.35,
			star_color = data.star_color,
			day_opacity = data.star_day_opacity,
		},
		moon = {
			visible = data.moon_visible,
			texture = data.moon_texture,
			scale = data.moon_scale
		},
		sun = {
			visible = true,
			texture = data.sun_texture,
			scale = data.sun_scale,
			sunrise_visible = sunrise_visible,
			sunrise = sunrise_visible and "sunrisebg.png" or "astral_blank.png",
		}
	})

	-- Fallback for older engines that don't support nested tables in set_sky
	player:set_stars({
		count = 7500,
		scale = 0.35,
		star_color = data.star_color,
		day_opacity = data.star_day_opacity,
	})

	player:set_moon({
		visible = data.moon_visible,
		texture = data.moon_texture,
		scale = data.moon_scale
	})

	player:set_sun({
		visible = true,
		texture = data.sun_texture,
		scale = data.sun_scale,
		sunrise_visible = sunrise_visible,
		sunrise = sunrise_visible and "sunrisebg.png" or "astral_blank.png",
	})

	player:set_clouds({ density = data.cloud_density })
	meta:set_string("astral_last_sky", current_sky)
end

local function map_value(val, in_min, in_max, out_min, out_max)
	if in_max == in_min then return out_min end
	return (val - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end

function astral.update_player_ratio(player, dtime, force)
	local data = astral.data
	local pos = player:get_pos()
	if nether and nether.DEPTH_CEILING and nether.DEPTH_FLOOR and
			pos.y < nether.DEPTH_CEILING and pos.y > nether.DEPTH_FLOOR then
		player:override_day_night_ratio(0.6)
		return
	end

	local time = core.get_timeofday()
	local engine_ratio = core.time_to_day_night_ratio(time)

	-- Define targets for day and night
	local night_target = data.light_ratio or 0.15
	local day_target = 1.0

	if data.special_sun ~= "normal" and astral.special_sun_config[data.special_sun].light_ratio then
		day_target = astral.special_sun_config[data.special_sun].light_ratio
	end

	-- Map the natural engine curve [0.15, 1.0] to our [night_target, day_target]
	local target_ratio = map_value(engine_ratio, 0.15, 1.0, night_target, day_target)
	target_ratio = math.max(0, math.min(1.5, target_ratio))

	-- Current ratio tracking
	local meta = player:get_meta()
	local current_ratio = meta:get_float("astral_current_ratio")

	if current_ratio == 0 or force or not dtime then
		current_ratio = target_ratio
		meta:set_float("astral_current_ratio", current_ratio)
		player:override_day_night_ratio(current_ratio)
		return
	end

	-- Smooth transition (Lerp) to avoid jumps if targets change suddenly (e.g. phase change)
	local speed = 0.5 -- Allow faster catch-up but still smooth
	if math.abs(target_ratio - current_ratio) > 0.001 then
		if target_ratio > current_ratio then
			current_ratio = math.min(target_ratio, current_ratio + speed * dtime)
		else
			current_ratio = math.max(target_ratio, current_ratio - speed * dtime)
		end
		meta:set_float("astral_current_ratio", current_ratio)
	else
		current_ratio = target_ratio
		meta:set_float("astral_current_ratio", current_ratio)
	end

	player:override_day_night_ratio(current_ratio)
end
