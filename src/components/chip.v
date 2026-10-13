module components

import raylib as rl
import math.vec
import data
import utils
import lua
import chip_catalog
import math
import imgui

@[heap]
struct Chip {
	data.ComponentBase // properties for this switch component
	chip_uid      string
	catalog_entry chip_catalog.ChipEntry
mut:
	contact_points    []data.ContactPoint
	last_input_states []data.WireState

	lua_state_initialized bool
	lua_state             voidptr

	previous_clock_state bool

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

pub fn Chip.new(mut app data.App, cfg data.ChipCfg) Chip {
	// initialize a new component with all its unique data
	mut c := Chip{
		chip_uid:      cfg.chip_uid
		catalog_entry: app.catalog.chips[cfg.chip_uid]
	}

	// calculate the height of the chip based on the number of pins it has
	height := c.catalog_entry.pins.len / 2

	// initialize the component base with all the standardized data
	c.ComponentBase = data.ComponentBase.new_chip(mut app, cfg.pos, vec.vec2[int](height,
		2), data.Rotation.from_int(cfg.rot), cfg.color.to_rl())

	// add this to the global component list
	c.comp_handle = utils.add_component(mut app, c)
	app.sim.wire_mesh_recalc_needed = true

	// create a dummy name for this component
	c.comp_name = '${c.catalog_entry.name} (${c.comp_handle.id}:${c.comp_handle.gen})'

	// calculate where this components bounding box is based on its rotation
	c.aabb_offset = utils.get_aabb_offset_for_rotation(1, -f32(height) + 0.5, 2, height,
		data.Rotation.from_int(cfg.rot))

	// -----------------------------------------------------------------------------------------------------------------
	// create a new contact points where wires can connect to
	num_pins := c.catalog_entry.pins.len

	// create a new buffer for all contact points
	c.contact_points = []data.ContactPoint{len: num_pins}

	// go through half of the pins
	// -> we will create a pair of pins per simulation
	//   +---+
	//  [|   |] <- and so on
	//  [|   |] <- then these
	//  [|   |] <- then these
	//  [|   |] <- these two first
	//   +---+
	for i in 0 .. num_pins / 2 {
		// first the left sides entry
		index_left := num_pins / 2 - i - 1

		// create a contact point
		c.contact_points[index_left] = data.ContactPoint.new(mut app, .floating)

		// assign it its label
		c.contact_points[index_left].label = c.catalog_entry.pins[index_left].label

		// add it to the global contact point register
		lx, ly := utils.translate_point(cfg.pos, 0, -i, data.Rotation.from_int(cfg.rot))
		c.contact_points[index_left].contact_handle = utils.add_contact_point(mut app,
			c.contact_points[index_left])

		// place it at a location in the sim space
		utils.register_contact_point(mut app, lx, ly, mut c.contact_points[index_left])

		// then do the other side, same thing as above
		index_right := num_pins / 2 + i
		c.contact_points[index_right] = data.ContactPoint.new(mut app, .floating)
		c.contact_points[index_right].label = c.catalog_entry.pins[index_right].label
		rx, ry := utils.translate_point(cfg.pos, 4, -i, data.Rotation.from_int(cfg.rot))
		c.contact_points[index_right].contact_handle = utils.add_contact_point(mut app,
			c.contact_points[index_right])
		utils.register_contact_point(mut app, rx, ry, mut c.contact_points[index_right])
	}

	// try to load the script for this chip
	c.lua_state_initialized = true
	c.lua_state = lua.setup_chip_lua_state(app, cfg.chip_uid) or {
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

	// run the scripts pin setup
	c.setup_pins(mut app)

	// if this is a stateful chip -> try loading the state
	if c.catalog_entry.script.has_state && cfg.chip_state.len > 0 {
		lua.do_load_state(c.lua_state, cfg.chip_state)
	}

	// also remember the previous clock state so we dont accidentally tick this chip even though it shouldn't be ticked
	c.previous_clock_state = cfg.clock_pin_state

	// initialize our last input state array so we can check if any inputs changed
	c.last_input_states = []data.WireState{len: num_pins}
	for i in 0 .. c.last_input_states.len {
		c.last_input_states[i] = .uninitialized
	}

	// done :)
	return c
}

pub fn (c Chip) get_cfg() data.ComponentCfg {
	return data.ChipCfg{
		pos:             c.pos
		rot:             c.rotation.to_int()
		color:           data.Color.from_rl(c.color)
		chip_uid:        c.chip_uid
		clock_pin_state: c.previous_clock_state
		chip_state:      if c.catalog_entry.script.has_state && c.script_capabilities.has_save_state {
			lua.do_save_state(c.lua_state)
		} else {
			''
		}
	}
}

fn (mut c Chip) setup_pins(mut app data.App) {
	if !c.lua_state_initialized || !c.script_capabilities.has_pin_setup {
		return
	}

	// call the pin setup method
	lua.do_pin_setup(mut app, c.lua_state, mut c.contact_points)
}

pub fn (mut c Chip) on_move(mut app data.App) {
	// unregister all contact points from the location they were placed in
	for i in 0 .. c.contact_points.len {
		utils.unregister_contact_point(mut app, mut c.contact_points[i])
	}
}

pub fn (mut c Chip) on_moved(mut app data.App) {
	// reregister all contact points at their new positions
	chip_entry := c.catalog_entry
	for i in 0 .. chip_entry.pins.len / 2 {
		index_left := chip_entry.pins.len / 2 - i - 1
		lx, ly := utils.translate_point(c.pos, 0, -i, c.rotation)
		utils.register_contact_point(mut app, lx, ly, mut c.contact_points[index_left])

		index_right := chip_entry.pins.len / 2 + i
		rx, ry := utils.translate_point(c.pos, 4, -i, c.rotation)
		utils.register_contact_point(mut app, rx, ry, mut c.contact_points[index_right])
	}
	app.sim.wire_mesh_recalc_needed = true
}

pub fn (mut c Chip) on_delete(mut app data.App) {
	// unregister all contact points
	for i in 0 .. c.contact_points.len {
		utils.unregister_contact_point(mut app, mut c.contact_points[i])
		app.sim.contact_points.remove(c.contact_points[i].contact_handle)
	}
	app.sim.wire_mesh_recalc_needed = true

	if c.lua_state_initialized {
		lua.destroy_lua_state(c.lua_state)
	}

	utils.remove_component(mut app, c)
}

fn (c &Chip) draw(mut app data.App) {
	contact_point, zoomed_unit := utils.get_drawing_variables(app, c.ComponentBase)
	Chip.draw(mut app.renderers.raylib_direct_renderer, app, contact_point, zoomed_unit,
		c.color, c.rotation, c.catalog_entry, c.contact_points)
}

pub fn Chip.draw(mut renderer data.IRenderer, app &data.App, contact_point vec.Vec2[f32], zoomed_unit f32, color rl.Color, rot data.Rotation, chip chip_catalog.ChipEntry, contact_points []data.ContactPoint) {
	Chip.draw_base(mut renderer, app, contact_point, zoomed_unit, color, rot, chip, contact_points)

	// are we close enough to draw pin labels?
	zoom_percent := if app.view.zoom >= 1 {
		math.log(app.view.zoom) / math.log(12)
	} else {
		0
	}

	if zoom_percent < 0.5 {
		return
	}

	opacity := if zoom_percent > 0.7 {
		1
	} else {
		1.0 - (0.7 - zoom_percent) / 0.2
	}

	Chip.draw_pin_labels(mut renderer, app, contact_point, zoomed_unit, color, rot, chip,
		contact_points, f32(opacity))
}

fn Chip.draw_base(mut renderer data.IRenderer, app &data.App, contact_point vec.Vec2[f32], zoomed_unit f32, color rl.Color, rot data.Rotation, chip chip_catalog.ChipEntry, contact_points []data.ContactPoint) {
	low_color := data.get_low_color_from_high_color(color)
	height := f32(chip.pins.len / 2)

	// draw the box
	renderer.draw_component_rectangle(contact_point.x, contact_point.y, zoomed_unit, 1,
		-height + 0.5, 2, height, rot, low_color)

	// draw the contacts
	for i in 0 .. chip.pins.len / 2 {
		renderer.draw_contact_line(contact_point.x, contact_point.y, zoomed_unit, 0, -i,
			1, -i, rot, low_color)

		renderer.draw_contact_line(contact_point.x, contact_point.y, zoomed_unit, 3, -i,
			4, -i, rot, low_color)

		// only draw the individual context when we're close enough to see them
		if app.view.draw_details {
			idx_left := chip.pins.len / 2 - i - 1
			contact_point_left := if contact_points.len > 0 {
				contact_points[idx_left]
			} else {
				data.ContactPoint{}
			}
			renderer.draw_chip_pin(contact_point.x, contact_point.y, zoomed_unit, 0, -i,
				contact_point_left, chip.pins[idx_left], true, rot, low_color)

			idx_right := chip.pins.len / 2 + i
			contact_point_right := if contact_points.len > 0 {
				contact_points[idx_right]
			} else {
				data.ContactPoint{}
			}
			renderer.draw_chip_pin(contact_point.x, contact_point.y, zoomed_unit, 4, -i,
				contact_point_right, chip.pins[idx_right], false, rot, low_color)
		}
	}

	// draw the chip label
	renderer.draw_centered_text_rotated(contact_point.x, contact_point.y, zoomed_unit,
		2, -(f32(height - 1) / 2.0), chip.name, app.fonts.chip_label_font_size, app.fonts.chip_label_font,
		rot, low_color)
}

fn Chip.draw_pin_labels(mut renderer data.IRenderer, app &data.App, contact_point vec.Vec2[f32], zoomed_unit f32, color rl.Color, rot data.Rotation, chip chip_catalog.ChipEntry, contact_points []data.ContactPoint, opacity f32) {
	low_color := data.get_low_color_from_high_color(color)

	label_color := rl.Color{
		...low_color
		a: u8(opacity * 255)
	}

	// draw pin labels!
	for i in 0 .. chip.pins.len / 2 {
		rect_left := renderer.draw_centered_text_rotated(contact_point.x, contact_point.y,
			zoomed_unit, 1.25, -i, chip.pins[chip.pins.len / 2 - i - 1].label, app.fonts.chip_pin_label_font_size,
			app.fonts.chip_pin_label_font, rot, label_color)

		if chip.pins[chip.pins.len / 2 - i - 1].is_active_low {
			renderer.draw_contact_line(contact_point.x, contact_point.y, zoomed_unit,
				rect_left.x + rect_left.height / 2, rect_left.y - rect_left.width / 2.0,
				rect_left.x + rect_left.height / 2, rect_left.y + rect_left.width / 2.0,
				rot, label_color)
		}

		rect_right := renderer.draw_centered_text_rotated(contact_point.x, contact_point.y,
			zoomed_unit, 2.75, -i, chip.pins[chip.pins.len / 2 + i].label, app.fonts.chip_pin_label_font_size,
			app.fonts.chip_pin_label_font, rot, label_color)
		if chip.pins[chip.pins.len / 2 + i].is_active_low {
			renderer.draw_contact_line(contact_point.x, contact_point.y, zoomed_unit,
				rect_right.x + rect_right.height / 2, rect_right.y - rect_right.width / 2.0,
				rect_right.x + rect_right.height / 2, rect_right.y + rect_right.width / 2.0,
				rot, label_color)
		}
	}
}

fn (mut c Chip) draw_component_window(mut app data.App) {
	if !c.component_window_open {
		return
	}

	pos_in_screen_space := data.worldspace_to_screenspace(app, c.pos)
	imgui.set_next_window_pos(imgui.ImVec2{pos_in_screen_space.x, pos_in_screen_space.y},
		int(imgui.Cond_.appearing), imgui.ImVec2{})

	if utils.gui_begin_component_window(c, 'Chip', c.component_window_open) {
		if utils.gui_begin_comp_layout_table(50, 100) {
			imgui.table_next_row(0, 0)

			imgui.table_set_column_index(0)
			utils.gui_do_label('Name')

			imgui.table_set_column_index(1)
			c.comp_name = utils.gui_do_text_input(mut app, '##name_input', c.comp_name)

			imgui.end_table()
		}
	}
	imgui.end()
}

pub fn (mut c Chip) step(mut app data.App, delta f32) {
	if !c.lua_state_initialized || !c.script_capabilities.has_step {
		return
	}

	// only do a chip step if any of the inputs changed
	mut has_changed := false
	for i, contact in c.contact_points {
		if contact.input_state != c.last_input_states[i] {
			has_changed = true
			break
		}
	}

	// nothing to do
	if !has_changed {
		return
	}

	// remember this state for later
	for i, contact in c.contact_points {
		c.last_input_states[i] = contact.input_state
	}

	// do a stateless step
	lua.do_step(mut app, c.lua_state, mut c.contact_points)

	// if this is a stateless chip -> we're done!
	chip_entry := app.catalog.chips[c.chip_uid]
	if !chip_entry.script.has_state {
		return
	}

	// otherwise: whats the value of the clock pin?
	current_clock_state := c.get_clock_state(chip_entry)

	// has there been a change?
	if current_clock_state == c.previous_clock_state {
		return
	}

	// are we on a falling or rising edge?

	// rising
	if current_clock_state {
		if c.script_capabilities.has_step_rising {
			lua.do_step_rising(mut app, c.lua_state, mut c.contact_points)
		}

		// falling
	} else {
		if c.script_capabilities.has_step_falling {
			lua.do_step_falling(mut app, c.lua_state, mut c.contact_points)
		}
	}

	// remember this clock state
	c.previous_clock_state = current_clock_state
}

pub fn (mut c Chip) get_clock_state(chip_entry chip_catalog.ChipEntry) bool {
	mut state := c.contact_points[chip_entry.clock_pin].input_state == .high

	// if this is an active low pin -> invert
	if chip_entry.pins[chip_entry.clock_pin].is_active_low {
		state = !state
	}

	return state
}
