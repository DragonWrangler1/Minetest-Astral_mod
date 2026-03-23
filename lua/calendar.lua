local data = astral.data

function astral.get_next_lunar()
	local moon_day = minetest.get_day_count() + astral.day_offset
	local cycle_len = astral.constants.MOON_PHASE_COUNT
	local month_cycle_len = #astral.month_cycle

	for i = 1, month_cycle_len * cycle_len do
		local future_day = moon_day + i
		local future_phase = future_day % cycle_len
		local future_month_idx = 1 + math.floor(future_day / cycle_len) % month_cycle_len
		local special = astral.month_cycle[future_month_idx].special

		if special ~= "normal" and astral.special_moon_config[special] then
			local config = astral.special_moon_config[special]
			if config.at_phase == future_phase then
				return special, config.name, i
			end
		end
	end
	return "normal", "None", 0
end

function astral.get_next_solar()
	local sun_day = minetest.get_day_count() + astral.day_offset
	local cycle_len = astral.constants.MOON_PHASE_COUNT
	local month_cycle_len = #astral.month_cycle

	for i = 1, month_cycle_len * cycle_len do
		local future_day = sun_day + i
		local future_phase = future_day % cycle_len
		local future_month_idx = 1 + math.floor(future_day / cycle_len) % month_cycle_len
		local special = astral.month_cycle[future_month_idx].special

		if special ~= "normal" and astral.special_sun_config[special] then
			local config = astral.special_sun_config[special]
			if config.at_phase == future_phase then
				return special, config.name, i
			end
		end
	end
	return "normal", "None", 0
end

function astral.update_calendar_node_entity(pos, ent)
	local node = minetest.get_node(pos)
	local prefix = node.name:match("^astral:(.*)_calendar")
	if not prefix then return end

	local meta = minetest.get_meta(pos)
	local show_next = meta:get_int("show_next") == 1

	local target
	local label
	if prefix == "lunar" then
		local nl, nl_name, nl_days = astral.get_next_lunar()
		target = show_next and nl or data.special_moon
		label = nl_name .. " (" .. nl_days .. " days)"
	else
		local ns, ns_name, ns_days = astral.get_next_solar()
		target = show_next and ns or data.special_sun
		label = ns_name .. " (" .. ns_days .. " days)"
	end

	local texture = "astral_" .. prefix .. "_calendar_" .. target .. ".png"

	-- Calculate shifted position to avoid Z-fighting and fix alignment
	local offset = 0.44 -- Just in front of the nodebox face (0.45)
	local epos = vector.new(pos)
	if node.param2 == 0 then epos.y = pos.y + offset
	elseif node.param2 == 1 then epos.y = pos.y - offset
	elseif node.param2 == 2 then epos.x = pos.x + offset
	elseif node.param2 == 3 then epos.x = pos.x - offset
	elseif node.param2 == 4 then epos.z = pos.z + offset
	elseif node.param2 == 5 then epos.z = pos.z - offset
	end

	-- Find or spawn entity
	if not ent then
		local objects = minetest.get_objects_inside_radius(pos, 0.5)
		for _, obj in ipairs(objects) do
			local luaent = obj:get_luaentity()
			if luaent and luaent.name == "astral:calendar_entity" then
				ent = obj
				break
			end
		end
	end

	if not ent then
		ent = minetest.add_entity(epos, "astral:calendar_entity")
	else
		ent:set_pos(epos)
	end

	if ent then
		local yaw = astral.wallmounted_to_yaw[node.param2]
		if yaw then
			ent:set_rotation({x=0, y=yaw, z=0})
		end
		ent:set_properties({textures = {texture}})
		local status = show_next and "Upcoming" or "Current"
		meta:set_string("infotext", prefix:sub(1,1):upper() .. prefix:sub(2) .. " Calendar (" .. status .. ")\nNext: " .. label)
	end
end

minetest.register_entity(":astral:calendar_entity", {
	initial_properties = {
		visual = "upright_sprite",
		textures = {"astral_lunar_calendar_normal.png"},
		visual_size = {x = 0.75, y = 0.75},
		collisionbox = {0, 0, 0, 0, 0, 0},
		physical = false,
		static_save = true,
		backface_culling = false,
	},
	on_activate = function(self, staticdata)
		self.object:set_armor_groups({immortal = 1})
		local pos = self.object:get_pos()
		local node_pos = vector.round(pos)
		local node = minetest.get_node(node_pos)
		if not node.name:match("^astral:.*_calendar") then
			self.object:remove()
			return
		end
		-- Re-set rotation and texture on load
		astral.update_calendar_node_entity(node_pos, self.object)
	end,
})

local function register_calendar(prefix, label)
	local get_next = (prefix == "lunar") and astral.get_next_lunar or astral.get_next_solar
	local special_config = (prefix == "lunar") and astral.special_moon_config or astral.special_sun_config

	minetest.register_node(":astral:" .. prefix .. "_calendar_node", {
		description = label .. " Calendar",
		drawtype = "nodebox",
		node_box = {
			type = "wallmounted",
			wall_top    = {-0.4, 0.45, -0.4, 0.4, 0.5, 0.4},
			wall_bottom = {-0.4, -0.5, -0.4, 0.4, -0.45, 0.4},
			wall_side   = {-0.5, -0.4, -0.4, -0.45, 0.4, 0.4},
		},
		tiles = {"astral_blank.png"},
		use_texture_alpha = "clip",
		paramtype = "light",
		paramtype2 = "wallmounted",
		sunlight_propagates = true,
		walkable = false,
		groups = {choppy = 2, dig_immediate = 3, attached_node = 1, calendar = 1, not_in_creative_inventory = 1},
		drop = "astral:" .. prefix .. "_calendar",

		on_construct = function(pos)
			astral.update_calendar_node_entity(pos)
		end,

		on_destruct = function(pos)
			local objects = minetest.get_objects_inside_radius(pos, 0.6)
			for _, obj in ipairs(objects) do
				local luaent = obj:get_luaentity()
				if luaent and luaent.name == "astral:calendar_entity" then
					obj:remove()
				end
			end
		end,

		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			if not clicker or not clicker:is_player() then return end
			local meta = minetest.get_meta(pos)
			local show_next = meta:get_int("show_next")
			meta:set_int("show_next", 1 - show_next)
			astral.update_calendar_node_entity(pos)

			local status = (1 - show_next == 1) and "upcoming" or "current"
			minetest.chat_send_player(clicker:get_player_name(), label .. " Calendar set to show " .. status .. " event.")
		end,
	})

	local on_place = function(itemstack, placer, pointed_thing)
		local pos = pointed_thing.above
		local under = pointed_thing.under
		local node = minetest.get_node(under)
		local def = minetest.registered_nodes[node.name]
		if def and def.on_rightclick and not placer:get_player_control().sneak then
			return def.on_rightclick(under, node, placer, itemstack, pointed_thing)
		end

		local res = minetest.item_place(ItemStack("astral:" .. prefix .. "_calendar_node"), placer, pointed_thing)
		if res then
			local meta = itemstack:get_meta()
			local node_meta = minetest.get_meta(pos)
			node_meta:set_int("show_next", meta:get_int("show_next"))
			astral.update_calendar_node_entity(pos)
			itemstack:take_item()
		end
		return itemstack
	end

	minetest.register_craftitem(":astral:" .. prefix .. "_calendar", {
		description = label .. " Calendar",
		inventory_image = "astral_" .. prefix .. "_calendar_normal.png",
		stack_max = 1,
		on_place = on_place,
		on_use = function(itemstack, user, pointed_thing)
			if not user or not user:is_player() then return end
			local name = user:get_player_name()
			local meta = itemstack:get_meta()
			local show_next = meta:get_int("show_next") == 1

			if show_next then
				meta:set_int("show_next", 0)
				local cur_special = (prefix == "lunar") and data.special_moon or data.special_sun
				if cur_special ~= "normal" then
					minetest.chat_send_player(name, "Current event: " .. (special_config[cur_special].name or cur_special))
				else
					minetest.chat_send_player(name, "No special " .. prefix .. " event today.")
				end
			else
				meta:set_int("show_next", 1)
				local event, event_name, days = get_next()
				minetest.chat_send_player(name, "Next special event: " .. event_name .. " in " .. days .. " days.")
			end
			return itemstack
		end,
	})

	local events = (prefix == "lunar") and
		{"normal", "blood_moon", "pink_moon", "blue_moon", "harvest_moon", "golden_moon", "super_moon", "blood_moon2", "black_moon", "eerie_moon"} or
		{"normal", "rainbow_sun", "ring_of_fire", "crescent_sun", "solar_eclipse"}

	for _, e in ipairs(events) do
		if e ~= "normal" then
			minetest.register_craftitem(":astral:" .. prefix .. "_calendar_" .. e, {
				description = label .. " Calendar",
				inventory_image = "astral_" .. prefix .. "_calendar_" .. e .. ".png",
				groups = {not_in_creative_inventory = 1},
				stack_max = 1,
				on_place = on_place,
				on_use = function(itemstack, user, pointed_thing)
					local base = minetest.registered_items["astral:" .. prefix .. "_calendar"]
					if base and base.on_use then
						return base.on_use(itemstack, user, pointed_thing)
					end
				end,
			})
		end
	end
end

register_calendar("lunar", "Lunar")
register_calendar("solar", "Solar")

function astral.update_calendar_item(player)
	local inv = player:get_inventory()
	local list = inv:get_list("main")
	if not list then return end

	local nl, nl_name, nl_days = astral.get_next_lunar()
	local ns, ns_name, ns_days = astral.get_next_solar()

	local changed = false
	for i, stack in ipairs(list) do
		local iname = stack:get_name()
		local meta = stack:get_meta()
		local mode = meta:get_int("show_next")
		local new_name = iname
		local new_desc = ""

		-- Handle legacy name conversion
		if iname == "astral:calendar" or iname:match("^astral:calendar_") then
			new_name = "astral:lunar_calendar"
		end

		if new_name:match("^astral:lunar_calendar") then
			local target = (mode == 1) and nl or data.special_moon
			new_name = "astral:lunar_calendar_" .. target
			if target == "normal" then new_name = "astral:lunar_calendar" end

			local status = (mode == 1) and "Upcoming" or "Current"
			new_desc = "Lunar Calendar (" .. status .. ")\nNext: " .. nl_name .. " (" .. nl_days .. " days)"
		elseif new_name:match("^astral:solar_calendar") then
			local target = (mode == 1) and ns or data.special_sun
			new_name = "astral:solar_calendar_" .. target
			if target == "normal" then new_name = "astral:solar_calendar" end

			local status = (mode == 1) and "Upcoming" or "Current"
			new_desc = "Solar Calendar (" .. status .. ")\nNext: " .. ns_name .. " (" .. ns_days .. " days)"
		end

		if new_name ~= iname or meta:get_string("description") ~= new_desc then
			stack:set_name(new_name)
			stack:get_meta():set_string("description", new_desc)
			changed = true
		end
	end
	if changed then inv:set_list("main", list) end
end
