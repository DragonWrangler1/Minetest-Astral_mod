astral = {}

local path = core.get_modpath("astral_redo")

-- Load modules in order
local modules = {
	"api",
	"config",
	"cycle",
	"sky",
	"astronomy",
	"calendar",
	"commands",
	"hooks",
}

for _, mod in ipairs(modules) do
	local filepath = path .. "/lua/" .. mod .. ".lua"
	dofile(filepath)
end

core.log("action", "[astral_redo] Mod loaded successfully")
