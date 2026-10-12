module components

import raylib as rl
import math.vec
import data
import utils
import math
import imgui

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

	// add this wire to the global component list
	c.comp_handle = utils.add_component(mut app, c)
	app.sim.wire_mesh_recalc_needed = true

	// create a dummy name for this component
	c.comp_name = 'Clock (${c.comp_handle.id}:${c.comp_handle.gen})'

	// calculate where this components bounding box is based on its rotation
	c.aabb_offset = utils.get_aabb_offset_for_rotation(-1, -3, 2, 2, data.Rotation.from_int(cfg.rot))

	// create a new contact point where wires can connect to
	c.contact_point = data.ContactPoint.new(mut app, .low)
	app.sim.contact_point_table[c.contact_point.cont_id] = &c.contact_point
	utils.register_contact_point(mut app, c.pos, c.contact_point.cont_id)

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
	utils.remove_component(mut app, c)
}

fn (c &Clock) draw(mut app data.App) {
	contact_point, zoomed_unit := utils.get_drawing_variables(app, c.ComponentBase)
	Clock.draw(mut app.renderers.raylib_direct_renderer, contact_point, zoomed_unit, c.color,
		c.time_accumulator, 1.0 / c.frequency / 2, c.rotation)
}

pub fn Clock.draw(mut renderer data.IRenderer, contact_point vec.Vec2[f32], zoomed_unit f32, color rl.Color, time f32, timeout f32, rot data.Rotation) {
	low_color := data.get_low_color_from_high_color(color)

	renderer.draw_circle_lines(contact_point.x, contact_point.y, zoomed_unit, 0, 0, data.contact_point_size,
		rot, low_color)

	renderer.draw_contact_line(contact_point.x, contact_point.y, zoomed_unit, 0, 0, 0,
		-1, rot, low_color)

	renderer.draw_component_rectangle(contact_point.x, contact_point.y, zoomed_unit, -1,
		-3, 2, 2, rot, low_color)

	angle := (time / timeout) * math.pi * 2 + math.pi_2
	outer_x := f32(math.cos(angle)) * 0.9
	outer_y := -2 + f32(math.sin(angle)) * 0.9
	inner_x := f32(math.cos(angle)) * 0.3
	inner_y := -2 + f32(math.sin(angle)) * 0.3
	renderer.draw_line(contact_point.x, contact_point.y, zoomed_unit, inner_x, inner_y,
		outer_x, outer_y, 0.1, rot, color)
}

fn (mut c Clock) draw_component_window(mut app data.App) {
	if !c.component_window_open {
		return
	}

	pos_in_screen_space := data.worldspace_to_screenspace(app, c.pos)
	imgui.set_next_window_pos(imgui.ImVec2{pos_in_screen_space.x, pos_in_screen_space.y},
		int(imgui.Cond_.appearing), imgui.ImVec2{})

	if utils.gui_begin_component_window(c, 'Clock', c.component_window_open) {
		if utils.gui_begin_comp_layout_table(50, 200) {
			imgui.table_next_row(0, 0)

			imgui.table_set_column_index(0)
			utils.gui_do_label('Name')

			imgui.table_set_column_index(1)
			c.comp_name = utils.gui_do_text_input(mut app, '##name_input', c.comp_name)

			imgui.table_next_row(0, 0)

			imgui.table_set_column_index(0)
			utils.gui_do_label('Timeout')

			imgui.table_set_column_index(1)
			imgui.set_next_item_width(imgui.get_content_region_avail().x)
			if imgui.slider_float(c'##frequency_slider', c.frequency_slider, 0, 1, '${c.frequency:.2} Hz'.str,
				0)
			{
				// apply a power curve mapping
				c.frequency = f32(frequency_min_val +(math.pow(c.frequency_slider, frequency_exponent) * (frequency_max_val - frequency_min_val)))
			}

			imgui.table_next_row(0, 0)

			imgui.table_set_column_index(0)
			utils.gui_do_label('Elapsed')

			imgui.table_set_column_index(1)
			utils.gui_do_label('${c.time_accumulator +
				if !c.state { 1.0 / c.frequency / 2 } else { 0 }:.1f}s')

			imgui.end_table()
		}
	}
	imgui.end()
}

pub fn (mut c Clock) step(mut app data.App, delta f32) {
	c.time_accumulator += delta
	if c.time_accumulator >= 1.0 / c.frequency / 2 {
		c.time_accumulator = 0
		c.state = !c.state
		c.contact_point.set_output_state(mut app, if c.state { .high } else { .low })
	}
}
