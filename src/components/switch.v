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
	state bool
}

pub fn Switch.new(mut app data.App, pos vec.Vec2[int], rot data.Rotation, color rl.Color, state bool) Switch {
	// initialize a new component with all its unique data
	mut s := Switch{
		state: state
	}

	// initialize the component base with all the standardized data
	s.ComponentBase = data.ComponentBase.new(mut app, pos, vec.vec2[int](2, 2), rot, color)

	// create a dummy name for this component
	s.comp_name = 'Switch ${s.comp_id}'

	// calculate where this components bounding box is based on its rotation
	s.aabb_offset = utils.get_aabb_offset_for_rotation(-1, -3, 2, 2, rot)

	// add this wire to the global component list
	app.sim.components << s

	// done :)
	return s
}

fn (mut s Switch) interact() {
	s.state = !s.state
}

fn (s &Switch) draw(app data.App) {
	contact_point, zoomed_unit := utils.get_drawing_variables(app, s.ComponentBase)
	low_color := data.get_low_color_from_high_color(s.color)

	rl.draw_circle_lines(int(contact_point.x), int(contact_point.y), int(zoomed_unit / 4),
		low_color)

	utils.draw_contact_line(contact_point.x, contact_point.y, zoomed_unit, 0, 0, 0, -1,
		s.rotation, s.color)

	utils.draw_component_rectangle(contact_point.x, contact_point.y, zoomed_unit, -1,
		-3, 2, 2, s.rotation, s.color)

	utils.draw_circle_filled(contact_point.x, contact_point.y, zoomed_unit, 0, -2, 0.5,
		s.rotation, s.color)
}

fn (mut s Switch) draw_component_window(mut app data.App) {
	if !s.component_window_open {
		return
	}

	pos_in_screen_space := utils.worldspace_to_screenspace(app, s.pos)
	if app.mu.begin_window_ex_bool_controlled('Switch (id: ${s.comp_id})', rl.Rectangle{pos_in_screen_space.x, pos_in_screen_space.y, 200, 85},
		.noscroll | .noresize, s.component_window_open)
	{
		app.mu.layout_row([50, -1], 0)

		app.mu.label('Name')
		app.mu.textbox(s.comp_name)

		app.mu.label('State')
		app.mu.checkbox('', s.state)

		app.mu.end_window_bool_controlled(s.component_window_open)
	}
}
