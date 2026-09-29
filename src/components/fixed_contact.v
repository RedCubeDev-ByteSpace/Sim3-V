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
	mut s := FixedContact{
		state: state
	}

	// initialize the component base with all the standardized data
	s.ComponentBase = data.ComponentBase.new(mut app, pos, vec.vec2[int](1, 1), rot, color)

	// create a dummy name for this component
	s.comp_name = 'Fixed Contact ${s.comp_id}'

	// offset the aabb by half of a unit
	s.aabb_offset = vec.vec2[f32](0.5, 0.5)

	// done :)
	return s
}

fn (s &FixedContact) draw(app data.App) {
	top_left, zoomed_unit := utils.get_drawing_variables(app, s.ComponentBase)

	low_color := data.get_low_color_from_high_color(s.color)

	rl.draw_rectangle_lines(int(top_left.x + 0.5 * zoomed_unit), int(top_left.y + 0.5 * zoomed_unit),
		int(zoomed_unit), int(zoomed_unit), low_color)

	state := if s.state { '1' } else { '0' }
	font_size := int(zoomed_unit * 0.75)
	font := fonts.get_font_for_size(app, font_size)
	text_size := rl.measure_text_ex(font, state, font_size, 1)
	rl.draw_text_ex(font, state, rl.Vector2{int(top_left.x + zoomed_unit) - text_size.x / 2, int(
		top_left.y + zoomed_unit) - text_size.y / 2}, font_size, 1, low_color)

	match s.rotation {
		.left {
			rl.draw_line(int(top_left.x + 0.5 * zoomed_unit), int(top_left.y + zoomed_unit),
				int(top_left.x), int(top_left.y + zoomed_unit), low_color)
			rl.draw_circle_lines(int(top_left.x), int(top_left.y + zoomed_unit), int(zoomed_unit / 4),
				low_color)
		}
		.up {
			rl.draw_line(int(top_left.x + zoomed_unit), int(top_left.y + zoomed_unit * 0.5),
				int(top_left.x + zoomed_unit), int(top_left.y), low_color)
			rl.draw_circle_lines(int(top_left.x + zoomed_unit), int(top_left.y), int(zoomed_unit / 4),
				low_color)
		}
		.right {
			rl.draw_line(int(top_left.x + zoomed_unit * 1.5), int(top_left.y + zoomed_unit),
				int(top_left.x + zoomed_unit * 2), int(top_left.y + zoomed_unit), low_color)
			rl.draw_circle_lines(int(top_left.x + zoomed_unit * 2), int(top_left.y + zoomed_unit),
				int(zoomed_unit / 4), low_color)
		}
		.down {
			rl.draw_line(int(top_left.x + zoomed_unit), int(top_left.y + zoomed_unit * 1.5),
				int(top_left.x + zoomed_unit), int(top_left.y + zoomed_unit * 2), low_color)
			rl.draw_circle_lines(int(top_left.x + zoomed_unit), int(top_left.y + zoomed_unit * 2),
				int(zoomed_unit / 4), low_color)
		}
	}
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

pub fn (mut c FixedContact) on_move() {
	println('old position: ${c.pos}')
}

pub fn (mut c FixedContact) on_moved() {
	println('new position: ${c.pos}')
}
