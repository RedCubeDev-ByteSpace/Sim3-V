module components

import data
import math.vec
import gg
import utils

struct FixedContact {
	data.ComponentBase
mut:
	// properties for this fixed contact component
	state bool
}

pub fn FixedContact.new(mut app data.App, pos vec.Vec2[int], rot data.Rotation, color gg.Color, state bool) FixedContact {
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

	app.gg.draw_rect_empty(top_left.x + 0.5 * zoomed_unit, top_left.y + 0.5 * zoomed_unit,
		zoomed_unit, zoomed_unit, low_color)

	state := if s.state { '1' } else { '0' }
	app.gg.set_text_cfg(gg.TextCfg{ size: int(zoomed_unit * 0.75) })
	width := app.gg.text_width(state)
	app.gg.draw_text(int(top_left.x + zoomed_unit - width / 2) + 1, int(top_left.y +
		0.625 * zoomed_unit), state, gg.TextCfg{ size: int(zoomed_unit * 0.75) })

	match s.rotation {
		.left {
			app.gg.draw_line(top_left.x + 0.5 * zoomed_unit, top_left.y + zoomed_unit,
				top_left.x, top_left.y + zoomed_unit, low_color)
			app.gg.draw_circle_empty(top_left.x, top_left.y + zoomed_unit, zoomed_unit / 4,
				low_color)
		}
		.up {
			app.gg.draw_line(top_left.x + zoomed_unit, top_left.y + zoomed_unit * 0.5,
				top_left.x + zoomed_unit, top_left.y, low_color)
			app.gg.draw_circle_empty(top_left.x + zoomed_unit, top_left.y, zoomed_unit / 4,
				low_color)
		}
		.right {
			app.gg.draw_line(top_left.x + zoomed_unit * 1.5, top_left.y + zoomed_unit,
				top_left.x + zoomed_unit * 2, top_left.y + zoomed_unit, low_color)
			app.gg.draw_circle_empty(top_left.x + zoomed_unit * 2, top_left.y + zoomed_unit,
				zoomed_unit / 4, low_color)
		}
		.down {
			app.gg.draw_line(top_left.x + zoomed_unit, top_left.y + zoomed_unit * 1.5,
				top_left.x + zoomed_unit, top_left.y + zoomed_unit * 2, low_color)
			app.gg.draw_circle_empty(top_left.x + zoomed_unit, top_left.y + zoomed_unit * 2,
				zoomed_unit / 4, low_color)
		}
	}
}

fn (mut s FixedContact) draw_component_window(mut app data.App) {
	if !s.component_window_open {
		return
	}

	pos_in_screen_space := utils.worldspace_to_screenspace(app, s.pos)
	if app.mu.begin_window_ex_bool_controlled('Fixed Contact (id: ${s.comp_id})', gg.Rect{pos_in_screen_space.x, pos_in_screen_space.y, 200, 85},
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
