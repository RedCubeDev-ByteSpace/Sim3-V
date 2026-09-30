module components

import data
import math.vec
import raylib as rl
import utils
import fonts

struct FixedContact {
	data.ComponentBase
mut:
	// properties for this fixed contact component
	state         bool
	contact_point data.ContactPoint
}

pub fn FixedContact.new(mut app data.App, pos vec.Vec2[int], rot data.Rotation, color rl.Color, state bool) FixedContact {
	// initialize a new component with all its unique data
	mut c := FixedContact{
		state: state
	}

	// initialize the component base with all the standardized data
	c.ComponentBase = data.ComponentBase.new(mut app, pos, vec.vec2[int](1, 1), rot, color,
		false)

	// create a dummy name for this component
	c.comp_name = 'Fixed Contact ${c.comp_id}'

	// calculate where this components bounding box is based on its rotation
	c.aabb_offset = utils.get_aabb_offset_for_rotation(-0.5, -1.5, 1, 1, rot)

	// create a new contact point where wires can connect to
	c.contact_point = data.ContactPoint.new(mut app, if state { .high } else { .low })
	app.sim.contact_point_table[c.contact_point.cont_id] = &c.contact_point
	utils.register_contact_point(mut app, c.pos, c.contact_point.cont_id)

	// add this wire to the global component list
	app.sim.components << c
	app.sim.wire_mesh_recalc_needed = true

	// done :)
	return c
}

pub fn (mut s FixedContact) on_move(mut app data.App) {
	utils.unregister_contact_point(mut app, s.pos, s.contact_point.cont_id)
}

pub fn (mut s FixedContact) on_moved(mut app data.App) {
	utils.register_contact_point(mut app, s.pos, s.contact_point.cont_id)
	app.sim.wire_mesh_recalc_needed = true
}

pub fn (mut s FixedContact) on_delete(mut app data.App) {
	utils.unregister_contact_point(mut app, s.pos, s.contact_point.cont_id)
	app.sim.contact_point_table.delete(s.contact_point.cont_id)
	app.sim.wire_mesh_recalc_needed = true
}

fn (f &FixedContact) draw(app data.App) {
	contact_point, zoomed_unit := utils.get_drawing_variables(app, f.ComponentBase)
	FixedContact.draw(app, contact_point, zoomed_unit, f.color, f.state, f.rotation)
}

pub fn FixedContact.draw(app data.App, contact_point vec.Vec2[f32], zoomed_unit f32, color rl.Color, state bool, rot data.Rotation) {
	low_color := data.get_low_color_from_high_color(color)
	draw_color := if state { color } else { low_color }

	rl.draw_circle_lines(int(contact_point.x), int(contact_point.y), int(zoomed_unit / 4),
		draw_color)

	utils.draw_contact_line(contact_point.x, contact_point.y, zoomed_unit, 0, 0, 0, -0.5,
		rot, draw_color)

	utils.draw_component_rectangle(contact_point.x, contact_point.y, zoomed_unit, -0.5,
		-1.5, 1, 1, rot, draw_color)

	state_label := if state { '1' } else { '0' }
	utils.draw_centered_text(app, contact_point.x, contact_point.y, zoomed_unit, 0, -1,
		state_label, 0.75, rot, draw_color)
}

fn (mut s FixedContact) draw_component_window(mut app data.App) {
	if !s.component_window_open {
		return
	}

	pos_in_screen_space := data.worldspace_to_screenspace(app, s.pos)
	if app.mu.begin_window_ex_bool_controlled('Fixed Contact (id: ${s.comp_id})', rl.Rectangle{pos_in_screen_space.x, pos_in_screen_space.y, 200, 85},
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
