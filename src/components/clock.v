module components

import raylib as rl
import math.vec
import data
import utils
import math

const frequency_exponent = 4.0

const frequency_min_val = 0.01

const frequency_max_val = 100.0

@[heap]
struct Clock {
	data.ComponentBase
mut:
	// properties for this clock component
	state            bool
	frequency_slider f32
	frequency        f32
	time_accumulator f32
	contact_point    data.ContactPoint
}

pub fn Clock.new(mut app data.App, cfg data.ClockCfg) Clock {
	// initialize a new component with all its unique data
	mut c := Clock{
		state:            false
		frequency:        cfg.frequency
		frequency_slider: f32(math.pow(cfg.frequency / frequency_max_val, 1.0 / frequency_exponent))
	}

	// initialize the component base with all the standardized data
	c.ComponentBase = data.ComponentBase.new(mut app, cfg.pos, vec.vec2[int](2, 2), data.Rotation.from_int(cfg.rot),
		cfg.color.to_rl(), false)
	c.has_step = true

	// create a dummy name for this component
	c.comp_name = 'Clock ${c.comp_id}'

	// calculate where this components bounding box is based on its rotation
	c.aabb_offset = utils.get_aabb_offset_for_rotation(-1, -3, 2, 2, data.Rotation.from_int(cfg.rot))

	// create a new contact point where wires can connect to
	c.contact_point = data.ContactPoint.new(mut app, .low)
	app.sim.contact_point_table[c.contact_point.cont_id] = &c.contact_point
	utils.register_contact_point(mut app, c.pos, c.contact_point.cont_id)

	// add this wire to the global component list
	utils.add_component(mut app, c)
	app.sim.wire_mesh_recalc_needed = true

	// done :)
	return c
}

pub fn (c Clock) get_cfg() data.ComponentCfg {
	return data.ClockCfg{
		pos:       c.pos
		rot:       c.rotation.to_int()
		color:     data.Color.from_rl(c.color)
		frequency: c.frequency
	}
}

pub fn (mut c Clock) on_move(mut app data.App) {
	utils.unregister_contact_point(mut app, c.pos, c.contact_point.cont_id)
}

pub fn (mut c Clock) on_moved(mut app data.App) {
	utils.register_contact_point(mut app, c.pos, c.contact_point.cont_id)
	app.sim.wire_mesh_recalc_needed = true
}

pub fn (mut c Clock) on_delete(mut app data.App) {
	utils.unregister_contact_point(mut app, c.pos, c.contact_point.cont_id)
	app.sim.contact_point_table.delete(c.contact_point.cont_id)
	app.sim.wire_mesh_recalc_needed = true
}

fn (c &Clock) draw(app data.App) {
	contact_point, zoomed_unit := utils.get_drawing_variables(app, c.ComponentBase)
	Clock.draw_static(contact_point, zoomed_unit, c.color, c.time_accumulator, 1.0 / c.frequency / 2,
		c.rotation)
}

pub fn Clock.draw_static(contact_point vec.Vec2[f32], zoomed_unit f32, color rl.Color, time f32, timeout f32, rot data.Rotation) {
	low_color := data.get_low_color_from_high_color(color)

	rl.draw_circle_lines(int(contact_point.x), int(contact_point.y), int(zoomed_unit / 4),
		low_color)

	utils.draw_contact_line(contact_point.x, contact_point.y, zoomed_unit, 0, 0, 0, -1,
		rot, low_color)

	utils.draw_component_rectangle(contact_point.x, contact_point.y, zoomed_unit, -1,
		-3, 2, 2, rot, low_color)

	angle := (time / timeout) * math.pi * 2 + math.pi_2
	outer_x := f32(math.cos(angle)) * 0.9
	outer_y := -2 + f32(math.sin(angle)) * 0.9
	inner_x := f32(math.cos(angle)) * 0.3
	inner_y := -2 + f32(math.sin(angle)) * 0.3
	utils.draw_line(contact_point.x, contact_point.y, zoomed_unit, inner_x, inner_y, outer_x,
		outer_y, 0.1, rot, color)
}

fn (mut c Clock) draw_component_window(mut app data.App) {
	if !c.component_window_open {
		return
	}

	pos_in_screen_space := data.worldspace_to_screenspace(app, c.pos)
	if app.mu.begin_window_ex_bool_controlled('Clock (id: ${c.comp_id})', rl.Rectangle{pos_in_screen_space.x, pos_in_screen_space.y, 250, 105},
		.noscroll | .noresize, c.component_window_open)
	{
		app.mu.layout_row([55, -1], 0)

		app.mu.label('Name')
		app.mu.textbox(c.comp_name)

		app.mu.label('Timeout')
		if app.mu.slider_ex(c.frequency_slider, 0, 1, 0.005, '${c.frequency:.2} Hz', 0) {
			// apply a power curve mapping
			c.frequency = f32(frequency_min_val + (math.pow(c.frequency_slider, frequency_exponent) * (frequency_max_val - frequency_min_val)))
		}

		app.mu.label('Elapsed')
		app.mu.label('${c.time_accumulator + if !c.state { 1.0 / c.frequency / 2 } else { 0 }:.1f}s')

		app.mu.end_window_bool_controlled(c.component_window_open)
	}
}

pub fn (mut c Clock) step(app data.App, delta f32) {
	c.time_accumulator += delta
	if c.time_accumulator >= 1.0 / c.frequency / 2 {
		c.time_accumulator = 0
		c.state = !c.state
		c.contact_point.output_state = if c.state { .high } else { .low }
	}
}
