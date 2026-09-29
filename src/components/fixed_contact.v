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
	state bool
}

pub fn FixedContact.new(mut app data.App, pos vec.Vec2[int], rot data.Rotation, color rl.Color, state bool) FixedContact {
	// initialize a new component with all its unique data
	mut c := FixedContact{
		state: state
	}

	// initialize the component base with all the standardized data
	c.ComponentBase = data.ComponentBase.new(mut app, pos, vec.vec2[int](1, 1), rot, color)

	// create a dummy name for this component
	c.comp_name = 'Fixed Contact ${c.comp_id}'

	// calculate where this components bounding box is based on its rotation
	c.aabb_offset = utils.get_aabb_offset_for_rotation(-0.5, -1.5, 1, 1, rot)

	// add this wire to the global component list
	app.sim.components << c

	// done :)
	return c
}

fn (f &FixedContact) draw(app data.App) {
	contact_point, zoomed_unit := utils.get_drawing_variables(app, f.ComponentBase)
	low_color := data.get_low_color_from_high_color(f.color)

	rl.draw_circle_lines(int(contact_point.x), int(contact_point.y), int(zoomed_unit / 4),
		low_color)

	utils.draw_contact_line(contact_point.x, contact_point.y, zoomed_unit, 0, 0, 0, -0.5,
		f.rotation, f.color)

	utils.draw_component_rectangle(contact_point.x, contact_point.y, zoomed_unit, -0.5,
		-1.5, 1, 1, f.rotation, f.color)

	state := if f.state { '1' } else { '0' }
	utils.draw_centered_text(app, contact_point.x, contact_point.y, zoomed_unit, 0, -1,
		state, 0.75, f.rotation, f.color)
}

fn (mut s FixedContact) draw_component_window(mut app data.App) {
	if !s.component_window_open {
		return
	}

	pos_in_screen_space := utils.worldspace_to_screenspace(app, s.pos)
	if app.mu.begin_window_ex_bool_controlled('Fixed Contact (id: ${s.comp_id})', rl.Rectangle{pos_in_screen_space.x, pos_in_screen_space.y, 200, 85},
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
