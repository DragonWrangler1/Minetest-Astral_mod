local data = astral.data

function astral.get_next_lunar()
	local moon_day = core.get_day_count() + astral.day_offset
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
	local sun_day = core.get_day_count() + astral.day_offset
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

function astral.apply_calendar_meta(stack, prefix)
	local meta = stack:get_meta()
	local show_next = meta:get_int("show_next") == 1
	local label = (prefix == "lunar") and "Lunar" or "Solar"

	local target, event_name, days
	if prefix == "lunar" then
		local nl, nln, nld = astral.get_next_lunar()
		target = show_next and nl or astral.data.special_moon
		event_name, days = nln, nld
	else
		local ns, nsn, nsd = astral.get_next_solar()
		target = show_next and ns or astral.data.special_sun
		event_name, days = nsn, nsd
	end

	local texture = "astral_" .. prefix .. "_calendar_" .. target .. ".png"
	local status = show_next and "Upcoming" or "Current"
	local new_desc = label .. " Calendar (" .. status .. ")\nNext: " .. event_name .. " (" .. days .. " days)"

	local changed = false
	if meta:get_string("inventory_image") ~= texture then
		meta:set_string("inventory_image", texture)
		changed = true
	end
	if meta:get_string("wield_image") ~= texture then
		meta:set_string("wield_image", texture)
		changed = true
	end
	if meta:get_string("description") ~= new_desc then
		meta:set_string("description", new_desc)
		changed = true
	end
	return changed
end

function astral.update_calendar_node_entity(pos, ent)
	local node = core.get_node(pos)
	local prefix = node.name:match("^astral:(.*)_calendar")
	if not prefix then return end

	local meta = core.get_meta(pos)
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
		local objects = core.get_objects_inside_radius(pos, 0.5)
		for _, obj in ipairs(objects) do
			local luaent = obj:get_luaentity()
			if luaent and luaent.name == "astral:calendar_entity" then
				ent = obj
				break
			end
		end
	end

	if not ent then
		ent = core.add_entity(epos, "astral:calendar_entity")
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

core.register_entity(":astral:calendar_entity", {
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
		local node = core.get_node(node_pos)
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

	core.register_node(":astral:" .. prefix .. "_calendar_node", {
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
			local objects = core.get_objects_inside_radius(pos, 0.6)
			for _, obj in ipairs(objects) do
				local luaent = obj:get_luaentity()
				if luaent and luaent.name == "astral:calendar_entity" then
					obj:remove()
				end
			end
		end,

		on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
			if not clicker or not clicker:is_player() then return end
			local meta = core.get_meta(pos)
			local show_next = meta:get_int("show_next")
			meta:set_int("show_next", 1 - show_next)
			astral.update_calendar_node_entity(pos)

			local status = (1 - show_next == 1) and "upcoming" or "current"
			core.chat_send_player(clicker:get_player_name(), label .. " Calendar set to show " .. status .. " event.")
		end,
	})

	local on_place = function(itemstack, placer, pointed_thing)
		local pos = pointed_thing.above
		local under = pointed_thing.under
		local node = core.get_node(under)
		local def = core.registered_nodes[node.name]
		if def and def.on_rightclick and not placer:get_player_control().sneak then
			return def.on_rightclick(under, node, placer, itemstack, pointed_thing)
		end

		local res = core.item_place(ItemStack("astral:" .. prefix .. "_calendar_node"), placer, pointed_thing)
		if res then
			local meta = itemstack:get_meta()
			local node_meta = core.get_meta(pos)
			node_meta:set_int("show_next", meta:get_int("show_next"))
			astral.update_calendar_node_entity(pos)
			itemstack:take_item()
		end
		return itemstack
	end

	core.register_craftitem(":astral:" .. prefix .. "_calendar", {
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
					core.chat_send_player(name, "Current event: " .. (special_config[cur_special].name or cur_special))
				else
					core.chat_send_player(name, "No special " .. prefix .. " event today.")
				end
			else
				meta:set_int("show_next", 1)
				local event, event_name, days = get_next()
				core.chat_send_player(name, "Next special event: " .. event_name .. " in " .. days .. " days.")
			end
			astral.apply_calendar_meta(itemstack, prefix)
			return itemstack
		end,
	})
end

register_calendar("lunar", "Lunar")
register_calendar("solar", "Solar")

function astral.update_calendar_item(player)
	local inv = player:get_inventory()
	local list = inv:get_list("main")
	if not list then return end

	local changed = false
	for i, stack in ipairs(list) do
		local iname = stack:get_name()
		local cur_changed = false

		-- Handle legacy name conversion and normalize to base names
		local base_name = iname
		if iname == "astral:calendar" or iname:match("^astral:calendar_") or iname:match("^astral:lunar_calendar_") then
			base_name = "astral:lunar_calendar"
		elseif iname:match("^astral:solar_calendar_") then
			base_name = "astral:solar_calendar"
		end

		if base_name ~= iname then
			stack:set_name(base_name)
			iname = base_name
			cur_changed = true
		end

		if iname == "astral:lunar_calendar" then
			if astral.apply_calendar_meta(stack, "lunar") then
				cur_changed = true
			end
		elseif iname == "astral:solar_calendar" then
			if astral.apply_calendar_meta(stack, "solar") then
				cur_changed = true
			end
		end

		if cur_changed then
			changed = true
		end
	end
	if changed then inv:set_list("main", list) end
end
