module components

import raylib as rl
import math.vec
import data
import utils
import lua
import chip_catalog
import math
import render_cache
import fonts

@[heap]
struct Chip {
	data.ComponentBase // properties for this switch component
	chip_uid string
mut:
	contact_points []data.ContactPoint

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
		chip_uid: cfg.chip_uid
	}
	chip_entry := app.catalog.chips[cfg.chip_uid]
	height := chip_entry.pins.len / 2

	// -----------------------------------------------------------------------------------------------------------------

	// initialize the component base with all the standardized data
	c.ComponentBase = data.ComponentBase.new(mut app, cfg.pos, vec.vec2[int](height, 2),
		data.Rotation.from_int(cfg.rot), cfg.color.to_rl(), false)
	c.has_step = true

	// create a dummy name for this component
	c.comp_name = '${chip_entry.name} ${c.comp_id}'

	// calculate where this components bounding box is based on its rotation
	c.aabb_offset = utils.get_aabb_offset_for_rotation(1, -f32(height) + 0.5, 2, height,
		data.Rotation.from_int(cfg.rot))

	// -----------------------------------------------------------------------------------------------------------------

	// create a new contact points where wires can connect to
	c.contact_points = []data.ContactPoint{len: chip_entry.pins.len}
	for i in 0 .. chip_entry.pins.len / 2 {
		index_left := chip_entry.pins.len / 2 - i - 1
		c.contact_points[index_left] = data.ContactPoint.new(mut app, .floating)
		c.contact_points[index_left].label = chip_entry.pins[index_left].label

		app.sim.contact_point_table[c.contact_points[index_left].cont_id] = &c.contact_points[index_left]

		lx, ly := utils.translate_point(cfg.pos, 0, -i, data.Rotation.from_int(cfg.rot))
		utils.register_contact_point(mut app, vec.vec2(lx, ly), c.contact_points[index_left].cont_id)

		index_right := chip_entry.pins.len / 2 + i
		c.contact_points[index_right] = data.ContactPoint.new(mut app, .floating)
		c.contact_points[index_right].label = chip_entry.pins[index_right].label
		app.sim.contact_point_table[c.contact_points[index_right].cont_id] = &c.contact_points[index_right]

		rx, ry := utils.translate_point(cfg.pos, 4, -i, data.Rotation.from_int(cfg.rot))
		utils.register_contact_point(mut app, vec.vec2(rx, ry), c.contact_points[index_right].cont_id)
	}

	// add this wire to the global component list
	utils.add_component(mut app, c)
	app.sim.wire_mesh_recalc_needed = true

	// -----------------------------------------------------------------------------------------------------------------

	// set up the render settings for caching
	c.render_size, c.render_offset = utils.get_render_rect_for_rotation(-0.5, -f32(height) + 0.5,
		vec.Vec2[f32]{5, height}, c.rotation)

	// -----------------------------------------------------------------------------------------------------------------

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

	c.setup_pins()

	// done :)
	return c
}

pub fn (c Chip) get_cfg() data.ComponentCfg {
	return data.ChipCfg{
		pos:      c.pos
		rot:      c.rotation.to_int()
		color:    data.Color.from_rl(c.color)
		chip_uid: c.chip_uid
	}
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

fn (c &Chip) draw(mut app data.App) {
	if !app.renderers.use_render_cache {
		contact_point, zoomed_unit := utils.get_drawing_variables(app, c.ComponentBase)
		Chip.draw(mut app.renderers.raylib_direct_renderer, app, contact_point, zoomed_unit,
			c.color, c.rotation, c.chip_uid, c.contact_points)
		return
	}

	// -----------------------------------------------------------------------------------------------------------------
	// Render caching

	raw_zoom := app.input.target_zoom

	// what texture would we need?
	cache_key := 'CH_${raw_zoom:.1f}_${int(c.rotation)}_${c.color.r},${c.color.g},${c.color.b},${c.color.a}_${c.chip_uid}'
	cache_key_labels := 'CL_${raw_zoom:.1f}_${int(c.rotation)}_${c.color.r},${c.color.g},${c.color.b},${c.color.a}_${c.chip_uid}'

	// does the texture we need exist already?
	if render_cache.has_cache(app, cache_key) {
		// draw it!
		c.draw_from_cache(mut app, cache_key, cache_key_labels)
		return
	}

	// otherwise: create a cache!

	// first: cache the base chip structure
	// -> the rectangle, lines to the pins and the chip label
	render_width, render_height := utils.get_zoomed_render_rect(c.get_rendering_rect(),
		raw_zoom)
	t := render_cache.begin_cache(app, render_width, render_height)
	{
		origin, zoomed_unit := utils.get_render_origin_and_zoom(c.render_offset, raw_zoom)

		// -------------------------------------------------------------------------------------------------------------
		// draw the base shape of the chip and the lines out to the contacts

		chip_label_font_size := zoomed_unit
		chip_label_font := fonts.get_font_for_size(app, int(chip_label_font_size))

		Chip.draw_base(mut app.renderers.raylib_direct_renderer, app, origin, zoomed_unit,
			c.color, c.rotation, chip_label_font, chip_label_font_size, c.chip_uid, c.contact_points)
	}
	render_cache.end_cache(mut app, cache_key, t)

	// if we're zoomed in enough
	zoom_percent := if app.view.zoom >= 1 {
		math.log(app.view.zoom) / math.log(12)
	} else {
		0
	}

	if zoom_percent >= 0.5 {
		// second: cache the pin labels separately
		// -> this way we can still smoothly fade them in and out based on zoom
		t_labels := render_cache.begin_cache(app, render_width, render_height)
		{
			origin, zoomed_unit := utils.get_render_origin_and_zoom(c.render_offset, raw_zoom)

			// -------------------------------------------------------------------------------------------------------------
			// draw the base shape of the chip and the lines out to the contacts

			pin_label_font_size := zoomed_unit * 0.25
			pin_label_font := fonts.get_font_for_size(app, int(pin_label_font_size))

			Chip.draw_pin_labels(mut app.renderers.raylib_direct_renderer, app, origin,
				zoomed_unit, c.color, c.rotation, pin_label_font, pin_label_font_size,
				c.chip_uid, c.contact_points, 1)
		}
		render_cache.end_cache(mut app, cache_key_labels, t_labels)
	}

	// and then draw it
	c.draw_from_cache(mut app, cache_key, cache_key_labels)
}

fn (c &Chip) draw_from_cache(mut app data.App, cache_key string, cache_key_labels string) {
	render_cache.draw_from_cache(app, cache_key, utils.get_render_rect_in_screenspace(app,
		c.get_rendering_rect()), 1)

	zoom_percent := if app.view.zoom >= 1 {
		math.log(app.view.zoom) / math.log(12)
	} else {
		0
	}

	if zoom_percent >= 0.5 {
		opacity := if zoom_percent > 0.7 {
			1
		} else {
			1.0 - (0.7 - zoom_percent) / 0.2
		}

		render_cache.draw_from_cache(app, cache_key_labels, utils.get_render_rect_in_screenspace(app,
			c.get_rendering_rect()), f32(opacity))
	}

	// draw the contacts the old fashioned way because it doesnt really make sense to cache them
	contact_point, zoomed_unit := utils.get_drawing_variables(app, c.ComponentBase)
	Chip.draw_pin_contacts(mut app.renderers.raylib_direct_renderer, app, contact_point,
		zoomed_unit, c.color, c.rotation, c.chip_uid, c.contact_points)
}

pub fn Chip.draw(mut renderer data.IRenderer, app data.App, contact_point vec.Vec2[f32], zoomed_unit f32, color rl.Color, rot data.Rotation, chip_uid string, contact_points []data.ContactPoint) {
	// -----------------------------------------------------------------------------------------------------------------
	// draw the base shape of the chip and the lines out to the contacts

	Chip.draw_base(mut renderer, app, contact_point, zoomed_unit, color, rot, app.fonts.chip_label_font,
		app.fonts.chip_label_font_size, chip_uid, contact_points)

	// -----------------------------------------------------------------------------------------------------------------
	// draw the shapes at the ends of the pins

	Chip.draw_pin_contacts(mut renderer, app, contact_point, zoomed_unit, color, rot,
		chip_uid, contact_points)

	// -----------------------------------------------------------------------------------------------------------------
	// draw the pin documentation

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

	Chip.draw_pin_labels(mut renderer, app, contact_point, zoomed_unit, color, rot, app.fonts.chip_pin_label_font,
		app.fonts.chip_pin_label_font_size, chip_uid, contact_points, f32(opacity))
}

fn Chip.draw_base(mut renderer data.IRenderer, app data.App, contact_point vec.Vec2[f32], zoomed_unit f32, color rl.Color, rot data.Rotation, font rl.Font, font_size f32, chip_uid string, contact_points []data.ContactPoint) {
	low_color := data.get_low_color_from_high_color(color)
	chip := app.catalog.chips[chip_uid]
	height := f32(chip.pins.len / 2)

	// draw the box
	renderer.draw_component_rectangle(contact_point.x, contact_point.y, zoomed_unit, 1,
		-height + 0.5, 2, height, rot, low_color)

	// draw the contact lines
	for i in 0 .. chip.pins.len / 2 {
		renderer.draw_contact_line(contact_point.x, contact_point.y, zoomed_unit, 0, -i,
			1, -i, rot, low_color)

		renderer.draw_contact_line(contact_point.x, contact_point.y, zoomed_unit, 3, -i,
			4, -i, rot, low_color)
	}

	// draw the chip label
	renderer.draw_centered_text_rotated(contact_point.x, contact_point.y, zoomed_unit,
		2, -(f32(height - 1) / 2.0), chip.name, font_size, font, rot, low_color)
}

fn Chip.draw_pin_contacts(mut renderer data.IRenderer, app data.App, contact_point vec.Vec2[f32], zoomed_unit f32, color rl.Color, rot data.Rotation, chip_uid string, contact_points []data.ContactPoint) {
	low_color := data.get_low_color_from_high_color(color)
	chip := app.catalog.chips[chip_uid]

	// draw the contacts
	for i in 0 .. chip.pins.len / 2 {
		renderer.draw_contact_line(contact_point.x, contact_point.y, zoomed_unit, 0, -i,
			1, -i, rot, low_color)

		idx_left := chip.pins.len / 2 - i - 1
		contact_point_left := if contact_points.len > 0 {
			contact_points[idx_left]
		} else {
			data.ContactPoint{}
		}
		renderer.draw_chip_pin(contact_point.x, contact_point.y, zoomed_unit, 0, -i, contact_point_left,
			chip.pins[idx_left], true, rot, low_color)

		renderer.draw_contact_line(contact_point.x, contact_point.y, zoomed_unit, 3, -i,
			4, -i, rot, low_color)

		idx_right := chip.pins.len / 2 + i
		contact_point_right := if contact_points.len > 0 {
			contact_points[idx_right]
		} else {
			data.ContactPoint{}
		}
		renderer.draw_chip_pin(contact_point.x, contact_point.y, zoomed_unit, 4, -i, contact_point_right,
			chip.pins[idx_right], false, rot, low_color)
	}
}

fn Chip.draw_pin_labels(mut renderer data.IRenderer, app data.App, contact_point vec.Vec2[f32], zoomed_unit f32, color rl.Color, rot data.Rotation, font rl.Font, font_size f32, chip_uid string, contact_points []data.ContactPoint, opacity f32) {
	low_color := data.get_low_color_from_high_color(color)
	chip := app.catalog.chips[chip_uid]

	label_color := rl.Color{
		...low_color
		a: u8(opacity * 255)
	}

	// draw pin labels!
	for i in 0 .. chip.pins.len / 2 {
		rect_left := renderer.draw_centered_text_rotated(contact_point.x, contact_point.y,
			zoomed_unit, 1.25, -i, chip.pins[chip.pins.len / 2 - i - 1].label, font_size,
			font, rot, label_color)

		if chip.pins[chip.pins.len / 2 - i - 1].is_active_low {
			renderer.draw_contact_line(contact_point.x, contact_point.y, zoomed_unit,
				rect_left.x + rect_left.height / 2, rect_left.y - rect_left.width / 2.0,
				rect_left.x + rect_left.height / 2, rect_left.y + rect_left.width / 2.0,
				rot, label_color)
		}

		rect_right := renderer.draw_centered_text_rotated(contact_point.x, contact_point.y,
			zoomed_unit, 2.75, -i, chip.pins[chip.pins.len / 2 + i].label, font_size,
			font, rot, label_color)
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
	if app.mu.begin_window_ex_bool_controlled('Chip (id: ${c.comp_id})', rl.Rectangle{pos_in_screen_space.x, pos_in_screen_space.y, 200, 85},
		.noscroll | .noresize, c.component_window_open)
	{
		app.mu.layout_row([50, -1], 0)

		app.mu.label('Name')
		app.mu.textbox(c.comp_name)

		app.mu.end_window_bool_controlled(c.component_window_open)
	}
}

pub fn (mut c Chip) step(app data.App, delta f32) {
	if !c.lua_state_initialized || !c.script_capabilities.has_step {
		return
	}

	// do a stateless step
	lua.do_step(c.lua_state, mut c.contact_points)

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
			lua.do_step_rising(c.lua_state, mut c.contact_points)
		}

		// falling
	} else {
		if c.script_capabilities.has_step_falling {
			lua.do_step_falling(c.lua_state, mut c.contact_points)
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
