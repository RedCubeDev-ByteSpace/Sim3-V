module components

import raylib as rl
import math.vec
import data
import utils
import abuss.vlua.vlua
import lua

@[heap]
struct Chip {
	data.ComponentBase // properties for this switch component
	chip_uid string
mut:
	contact_points []data.ContactPoint

	lua_state_initialized bool
	lua_state             voidptr

	script_capabilities struct {
	pub mut:
		has_pin_setup    bool
		has_step         bool
		has_step_rising  bool
		has_step_falling bool
		has_load_state   bool
		has_save_state   bool
	}
}

pub fn Chip.new(mut app data.App, pos vec.Vec2[int], rot data.Rotation, color rl.Color, chip_uid string) Chip {
	// initialize a new component with all its unique data
	mut c := Chip{
		chip_uid: chip_uid
	}
	chip_entry := app.catalog.chips[chip_uid]
	height := chip_entry.pins.len / 2

	// initialize the component base with all the standardized data
	c.ComponentBase = data.ComponentBase.new(mut app, pos, vec.vec2[int](height, 2), rot,
		color, false)
	c.has_step = true

	// create a dummy name for this component
	c.comp_name = '${chip_entry.name} ${c.comp_id}'

	// calculate where this components bounding box is based on its rotation
	c.aabb_offset = utils.get_aabb_offset_for_rotation(1, -f32(height) + 0.5, 2, height,
		rot)

	// create a new contact points where wires can connect to
	c.contact_points = []data.ContactPoint{len: chip_entry.pins.len}
	for i in 0 .. chip_entry.pins.len / 2 {
		index_left := chip_entry.pins.len / 2 - i - 1
		c.contact_points[index_left] = data.ContactPoint.new(mut app, .floating)
		c.contact_points[index_left].label = chip_entry.pins[index_left].label

		app.sim.contact_point_table[c.contact_points[index_left].cont_id] = &c.contact_points[index_left]

		lx, ly := utils.translate_point(pos, 0, -i, rot)
		utils.register_contact_point(mut app, vec.vec2(lx, ly), c.contact_points[index_left].cont_id)

		index_right := chip_entry.pins.len / 2 + i
		c.contact_points[index_right] = data.ContactPoint.new(mut app, .floating)
		c.contact_points[index_right].label = chip_entry.pins[index_right].label
		app.sim.contact_point_table[c.contact_points[index_right].cont_id] = &c.contact_points[index_right]

		rx, ry := utils.translate_point(pos, 4, -i, rot)
		utils.register_contact_point(mut app, vec.vec2(rx, ry), c.contact_points[index_right].cont_id)
	}

	// add this wire to the global component list
	utils.add_component(mut app, c)
	app.sim.wire_mesh_recalc_needed = true

	// try to load the script for this chip
	c.lua_state_initialized = true
	c.lua_state = lua.setup_chip_lua_state(app, chip_uid) or {
		c.lua_state_initialized = false
		unsafe { nil }
	}

	// find out which functions the chips script allows
	if c.lua_state_initialized {
		c.script_capabilities.has_pin_setup = lua.has_function(c.lua_state, 'PinSetup')
		c.script_capabilities.has_step = lua.has_function(c.lua_state, 'Step')
		c.script_capabilities.has_step_rising = lua.has_function(c.lua_state, 'StepRising')
		c.script_capabilities.has_step_falling = lua.has_function(c.lua_state, 'StepFalling')
		c.script_capabilities.has_load_state = lua.has_function(c.lua_state, 'LoadState')
		c.script_capabilities.has_save_state = lua.has_function(c.lua_state, 'SaveState')
	}

	c.setup_pins()

	// done :)
	return c
}

fn (mut c Chip) setup_pins() {
	if !c.lua_state_initialized || !c.script_capabilities.has_pin_setup {
		return
	}

	// call the pin setup method
	lua.do_pin_setup(c.lua_state, mut c.contact_points)
}

pub fn (mut c Chip) on_move(mut app data.App) {
	chip_entry := app.catalog.chips[c.chip_uid]
	for i in 0 .. chip_entry.pins.len / 2 {
		index_left := chip_entry.pins.len / 2 - i - 1
		lx, ly := utils.translate_point(c.pos, 0, -i, c.rotation)
		utils.unregister_contact_point(mut app, vec.vec2(lx, ly), c.contact_points[index_left].cont_id)

		index_right := chip_entry.pins.len / 2 + i
		rx, ry := utils.translate_point(c.pos, 4, -i, c.rotation)
		utils.unregister_contact_point(mut app, vec.vec2(rx, ry), c.contact_points[index_right].cont_id)
	}
}

pub fn (mut c Chip) on_moved(mut app data.App) {
	chip_entry := app.catalog.chips[c.chip_uid]
	for i in 0 .. chip_entry.pins.len / 2 {
		index_left := chip_entry.pins.len / 2 - i - 1
		lx, ly := utils.translate_point(c.pos, 0, -i, c.rotation)
		utils.register_contact_point(mut app, vec.vec2(lx, ly), c.contact_points[index_left].cont_id)

		index_right := chip_entry.pins.len / 2 + i
		rx, ry := utils.translate_point(c.pos, 4, -i, c.rotation)
		utils.register_contact_point(mut app, vec.vec2(rx, ry), c.contact_points[index_right].cont_id)
	}
	app.sim.wire_mesh_recalc_needed = true
}

pub fn (mut c Chip) on_delete(mut app data.App) {
	chip_entry := app.catalog.chips[c.chip_uid]
	for i in 0 .. chip_entry.pins.len / 2 {
		index_left := chip_entry.pins.len / 2 - i - 1
		lx, ly := utils.translate_point(c.pos, 0, -i, c.rotation)
		utils.unregister_contact_point(mut app, vec.vec2(lx, ly), c.contact_points[index_left].cont_id)
		app.sim.contact_point_table.delete(c.contact_points[index_left].cont_id)

		index_right := chip_entry.pins.len / 2 + i
		rx, ry := utils.translate_point(c.pos, 4, -i, c.rotation)
		utils.unregister_contact_point(mut app, vec.vec2(rx, ry), c.contact_points[index_right].cont_id)
		app.sim.contact_point_table.delete(c.contact_points[index_right].cont_id)
	}
	app.sim.wire_mesh_recalc_needed = true

	if c.lua_state_initialized {
		lua.destroy_lua_state(c.lua_state)
	}
}

fn (c &Chip) draw(app data.App) {
	contact_point, zoomed_unit := utils.get_drawing_variables(app, c.ComponentBase)
	Chip.draw(app, contact_point, zoomed_unit, c.color, c.rotation, c.chip_uid)
}

pub fn Chip.draw(app data.App, contact_point vec.Vec2[f32], zoomed_unit f32, color rl.Color, rot data.Rotation, chip_uid string) {
	low_color := data.get_low_color_from_high_color(color)
	chip := app.catalog.chips[chip_uid]
	height := chip.pins.len / 2

	// draw the box
	utils.draw_component_rectangle(contact_point.x, contact_point.y, zoomed_unit, 1, -f32(height) +
		0.5, 2, height, rot, low_color)

	// draw the contacts
	for i in 0 .. chip.pins.len / 2 {
		utils.draw_circle_lines(contact_point.x, contact_point.y, zoomed_unit, 0, -i,
			0.25, rot, low_color)
		utils.draw_contact_line(contact_point.x, contact_point.y, zoomed_unit, 0, -i,
			1, -i, rot, low_color)

		utils.draw_circle_lines(contact_point.x, contact_point.y, zoomed_unit, 4, -i,
			0.25, rot, low_color)
		utils.draw_contact_line(contact_point.x, contact_point.y, zoomed_unit, 3, -i,
			4, -i, rot, low_color)
	}

	// draw the label
	utils.draw_centered_text_rotated(app, contact_point.x, contact_point.y, zoomed_unit,
		2, -(height / 2), chip.name, 1, rot, low_color)
}

fn (mut c Chip) draw_component_window(mut app data.App) {
	if !c.component_window_open {
		return
	}

	pos_in_screen_space := data.worldspace_to_screenspace(app, c.pos)
	if app.mu.begin_window_ex_bool_controlled('Chip (id: ${c.comp_id})', rl.Rectangle{pos_in_screen_space.x, pos_in_screen_space.y, 200, 85},
		.noscroll | .noresize, c.component_window_open)
	{
		app.mu.layout_row([50, -1], 0)

		app.mu.label('Name')
		app.mu.textbox(c.comp_name)

		app.mu.end_window_bool_controlled(c.component_window_open)
	}
}

pub fn (mut c Chip) step() {
	if !c.lua_state_initialized || !c.script_capabilities.has_step {
		return
	}

	lua.do_step(c.lua_state, mut c.contact_points)
}
