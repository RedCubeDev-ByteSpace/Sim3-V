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

pub fn Switch.new(pos vec.Vec2[int], rot data.Rotation, color gg.Color, state bool) Switch {
	// initialize a new component with all its unique data
	mut s := Switch{
		state: state
	}

	// initialize the component base with all the standardized data
	s.ComponentBase = data.ComponentBase.new(pos, vec.vec2[int](2, 2), rot, color)

	// done :)
	return s
}

fn (s &Switch) draw(app data.App) {
	top_left, zoomed_unit := utils.get_drawing_variables(app, s.ComponentBase)

	app.gg.draw_rect_empty(top_left.x, top_left.y, zoomed_unit * 2, zoomed_unit * 2, data.component_color)
}
