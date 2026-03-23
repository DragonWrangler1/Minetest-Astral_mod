astral = {}

local path = minetest.get_modpath("astral_redo")

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
	local ok, err = pcall(dofile, filepath)
	if not ok then
		minetest.log("error", "[astral_redo] Failed to load " .. mod .. ": " .. tostring(err))
	end
end

minetest.log("action", "[astral_redo] Mod loaded successfully")
