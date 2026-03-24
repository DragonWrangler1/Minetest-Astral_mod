astral.constants = {
	MOON_PHASE_COUNT = 8,
	NORMAL_MOON_SCALE = 0.8,
	NORMAL_SUN_SCALE = 3,
	NORMAL_STAR_COLOR = "#ebebff69",
	NORMAL_CLOUD_DENSITY = 0.4,
	NORMAL_DAY_SKY_COLOR = "#8cbafa",
	NORMAL_DAY_HORIZON_COLOR = "#9bc1f0",
	NORMAL_DAWN_SKY_COLOR = "#b4bafa",
	NORMAL_DAWN_HORIZON_COLOR = "#bac1f0",
}

astral.moon_phase_names = {
	[0] = "New Moon",
	"Waxing Crescent",
	"First Quarter",
	"Waxing Gibbous",
	"Full Moon",
	"Waning Gibbous",
	"Last Quarter",
	"Waning Crescent"
}

-- Realistic night colors (transitioning from dark to moonlit blue)
astral.moon_phase_sky_colors = {
	[0] = "#010204", -- New Moon (Deep black-blue)
	"#02050a",
	"#040a15",
	"#060e1e",
	"#081224", -- Full Moon (Subdued moonlit blue)
	"#060e1e",
	"#040a15",
	"#02050a"
}

astral.moon_phase_horizon_colors = {
	[0] = "#000102",
	"#010306",
	"#02060c",
	"#040a18",
	"#060f21",
	"#040a18",
	"#02060c",
	"#010306"
}
-- Light ratio override for each phase
astral.moon_phase_light_ratios = {
	[0] = 0.13, -- No moon shining.. Though This value considers there to be some ambient light sources. What would we do without light!?
	0.15,
	0.17,
	0.18,
	0.2,
	0.18,
	0.17,
	0.15
}

astral.wallmounted_to_yaw = {
	[2] = math.pi / 2,
	[3] = -math.pi / 2,
	[4] = math.pi,
	[5] = 0,
}
