module components

import raylib as rl
import math.vec
import data
import utils

@[heap]
struct Switch {
	data.ComponentBase
mut:
	// properties for this switch component
	state         bool
	contact_point data.ContactPoint
}

pub fn Switch.new(mut app data.App, cfg data.SwitchCfg) Switch {
	// initialize a new component with all its unique data
	mut s := Switch{
		state: cfg.state
	}

	// initialize the component base with all the standardized data
	s.ComponentBase = data.ComponentBase.new(mut app, cfg.pos, vec.vec2[int](2, 2), data.Rotation.from_int(cfg.rot),
		cfg.color.to_rl(), true)

	// create a dummy name for this component
	s.comp_name = 'Switch ${s.comp_id}'

	// calculate where this components bounding box is based on its rotation
	s.aabb_offset = utils.get_aabb_offset_for_rotation(-1, -3, 2, 2, data.Rotation.from_int(cfg.rot))

	// create a new contact point where wires can connect to
	s.contact_point = data.ContactPoint.new(mut app, if cfg.state { .high } else { .low })
	app.sim.contact_point_table[s.contact_point.cont_id] = &s.contact_point
	utils.register_contact_point(mut app, s.pos, s.contact_point.cont_id)

	// add this wire to the global component list
	utils.add_component(mut app, s)
	app.sim.wire_mesh_recalc_needed = true

	// done :)
	return s
}

pub fn (s Switch) get_cfg() data.ComponentCfg {
	return data.SwitchCfg{
		pos:   s.pos
		rot:   s.rotation.to_int()
		color: data.Color.from_rl(s.color)
		state: s.state
	}
}

fn (mut s Switch) interact() {
	s.state = !s.state
	s.contact_point.output_state = if s.state { .high } else { .low }
}

pub fn (mut s Switch) on_move(mut app data.App) {
	utils.unregister_contact_point(mut app, s.pos, s.contact_point.cont_id)
}

pub fn (mut s Switch) on_moved(mut app data.App) {
	utils.register_contact_point(mut app, s.pos, s.contact_point.cont_id)
	app.sim.wire_mesh_recalc_needed = true
}

pub fn (mut s Switch) on_delete(mut app data.App) {
	utils.unregister_contact_point(mut app, s.pos, s.contact_point.cont_id)
	app.sim.contact_point_table.delete(s.contact_point.cont_id)
	app.sim.wire_mesh_recalc_needed = true
}

fn (s &Switch) draw(app data.App) {
	contact_point, zoomed_unit := utils.get_drawing_variables(app, s.ComponentBase)
	Switch.draw_static(contact_point, zoomed_unit, s.color, s.state, s.rotation)
}

pub fn Switch.draw_static(contact_point vec.Vec2[f32], zoomed_unit f32, color rl.Color, state bool, rot data.Rotation) {
	low_color := data.get_low_color_from_high_color(color)

	rl.draw_circle_lines(int(contact_point.x), int(contact_point.y), int(zoomed_unit / 4),
		low_color)

	utils.draw_contact_line(contact_point.x, contact_point.y, zoomed_unit, 0, 0, 0, -1,
		rot, low_color)

	utils.draw_component_rectangle(contact_point.x, contact_point.y, zoomed_unit, -1,
		-3, 2, 2, rot, low_color)

	utils.draw_circle_filled(contact_point.x, contact_point.y, zoomed_unit, 0, -2, 0.5,
		rot, if state { color } else { low_color })
}

fn (mut s Switch) draw_component_window(mut app data.App) {
	if !s.component_window_open {
		return
	}

	pos_in_screen_space := data.worldspace_to_screenspace(app, s.pos)
	if app.mu.begin_window_ex_bool_controlled('Switch (id: ${s.comp_id})', rl.Rectangle{pos_in_screen_space.x, pos_in_screen_space.y, 200, 85},
		.noscroll | .noresize, s.component_window_open)
	{
		app.mu.layout_row([50, -1], 0)

		app.mu.label('Name')
		app.mu.textbox(s.comp_name)

		app.mu.label('State')
		if app.mu.checkbox('', s.state) {
			s.contact_point.output_state = if s.state { .high } else { .low }
		}

		app.mu.end_window_bool_controlled(s.component_window_open)
	}
}
