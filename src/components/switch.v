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

	// add this wire to the global component list
	app.sim.components << s

	// done :)
	return s
}

fn (mut s Switch) interact() {
	s.state = !s.state
}

fn (s &Switch) draw(app data.App) {
	top_left, zoomed_unit := utils.get_drawing_variables(app, s.ComponentBase)

	low_color := data.get_low_color_from_high_color(s.color)

	rl.draw_rectangle_lines(int(top_left.x), int(top_left.y), int(zoomed_unit * 2), int(zoomed_unit * 2),
		low_color)
	rl.draw_circle(int(top_left.x + zoomed_unit), int(top_left.y + zoomed_unit), int(zoomed_unit / 2),
		if s.state { s.color } else { low_color })

	match s.rotation {
		.left {
			rl.draw_line(int(top_left.x), int(top_left.y + zoomed_unit), int(top_left.x - zoomed_unit),
				int(top_left.y + zoomed_unit), low_color)
			rl.draw_circle_lines(int(top_left.x - zoomed_unit), int(top_left.y + zoomed_unit),
				int(zoomed_unit / 4), low_color)
		}
		.up {
			rl.draw_line(int(top_left.x + zoomed_unit), int(top_left.y), int(top_left.x +
				zoomed_unit), int(top_left.y - zoomed_unit), low_color)
			rl.draw_circle_lines(int(top_left.x + zoomed_unit), int(top_left.y - zoomed_unit),
				int(zoomed_unit / 4), low_color)
		}
		.right {
			rl.draw_line(int(top_left.x + zoomed_unit * 2), int(top_left.y + zoomed_unit),
				int(top_left.x + zoomed_unit * 3), int(top_left.y + zoomed_unit), low_color)
			rl.draw_circle_lines(int(top_left.x + zoomed_unit * 3), int(top_left.y + zoomed_unit),
				int(zoomed_unit / 4), low_color)
		}
		.down {
			rl.draw_line(int(top_left.x + zoomed_unit), int(top_left.y + zoomed_unit * 2),
				int(top_left.x + zoomed_unit), int(top_left.y + zoomed_unit * 3), low_color)
			rl.draw_circle_lines(int(top_left.x + zoomed_unit), int(top_left.y + zoomed_unit * 3),
				int(zoomed_unit / 4), low_color)
		}
	}
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
