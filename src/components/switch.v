module components

import math.vec
import gg
import data
import utils

@[heap]
struct Switch {
	data.ComponentBase
mut:
	// properties for this switch component
	state bool
}

pub fn Switch.new(mut app data.App, pos vec.Vec2[int], rot data.Rotation, color gg.Color, state bool) Switch {
	// initialize a new component with all its unique data
	mut s := Switch{
		state: state
	}

	// initialize the component base with all the standardized data
	s.ComponentBase = data.ComponentBase.new(mut app, pos, vec.vec2[int](2, 2), rot, color)

	// create a dummy name for this component
	s.comp_name = 'Switch ${s.comp_id}'

	// done :)
	return s
}

fn (mut s Switch) interact() {
	s.state = !s.state
}

fn (s &Switch) draw(app data.App) {
	top_left, zoomed_unit := utils.get_drawing_variables(app, s.ComponentBase)

	low_color := data.get_low_color_from_high_color(s.color)

	app.gg.draw_rect_empty(top_left.x, top_left.y, zoomed_unit * 2, zoomed_unit * 2, low_color)
	app.gg.draw_circle_filled(top_left.x + zoomed_unit, top_left.y + zoomed_unit, zoomed_unit / 2,
		if s.state { s.color } else { low_color })

	match s.rotation {
		.left {
			app.gg.draw_line(top_left.x, top_left.y + zoomed_unit, top_left.x - zoomed_unit,
				top_left.y + zoomed_unit, low_color)
			app.gg.draw_circle_empty(top_left.x - zoomed_unit, top_left.y + zoomed_unit,
				zoomed_unit / 4, low_color)
		}
		.up {
			app.gg.draw_line(top_left.x + zoomed_unit, top_left.y, top_left.x + zoomed_unit,
				top_left.y - zoomed_unit, low_color)
			app.gg.draw_circle_empty(top_left.x + zoomed_unit, top_left.y - zoomed_unit,
				zoomed_unit / 4, low_color)
		}
		.right {
			app.gg.draw_line(top_left.x + zoomed_unit * 2, top_left.y + zoomed_unit, top_left.x +
				zoomed_unit * 3, top_left.y + zoomed_unit, low_color)
			app.gg.draw_circle_empty(top_left.x + zoomed_unit * 3, top_left.y + zoomed_unit,
				zoomed_unit / 4, low_color)
		}
		.down {
			app.gg.draw_line(top_left.x + zoomed_unit, top_left.y + zoomed_unit * 2, top_left.x +
				zoomed_unit, top_left.y + zoomed_unit * 3, low_color)
			app.gg.draw_circle_empty(top_left.x + zoomed_unit, top_left.y + zoomed_unit * 3,
				zoomed_unit / 4, low_color)
		}
	}
}

fn (mut s Switch) draw_component_window(mut app data.App) {
	if !s.component_window_open {
		return
	}

	pos_in_screen_space := utils.worldspace_to_screenspace(app, s.pos)
	if app.mu.begin_window_ex_bool_controlled('Switch (id: ${s.comp_id})', gg.Rect{pos_in_screen_space.x, pos_in_screen_space.y, 200, 85},
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
