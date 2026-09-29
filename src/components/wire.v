module components

import data
import math.vec
import raylib as rl
import utils
import fonts

struct Wire {
	data.ComponentBase
mut:
	// properties for this wire component
	// the component position functions as the starting point of the wire
	wire_to vec.Vec2[int] // this is the endpoint of the wire
	state   data.WireState
}

pub fn Wire.new(mut app data.App, wire_from vec.Vec2[int], wire_to vec.Vec2[int], color rl.Color) Wire {
	// initialize a new component with all its unique data
	mut w := Wire{
		wire_to: wire_to
		state:   .high
	}

	// initialize the component base with all the standardized data
	w.ComponentBase = data.ComponentBase.new(mut app, wire_from, vec.vec2[int](1, 1),
		.left, color)

	// create a dummy name for this component
	w.comp_name = 'Wire ${w.comp_id}'

	// add this wire to the global component list
	app.sim.components << w

	// add this wire to the wire lookup table
	app.sim.wire_table[w.comp_id] = data.WireTableEntry{
		comp_id:       w.comp_id
		component:     &w
		wire_from_pos: utils.vec_to_str(w.pos)
		wire_to_pos:   utils.vec_to_str(w.wire_to)
	}

	// register this wire on the map
	utils.register_wire(mut app, w.pos, w.comp_id)
	utils.register_wire(mut app, w.wire_to, w.comp_id)

	// new wire! recalculate the meshes
	app.sim.wire_mesh_recalc_needed = true

	// done :)
	return w
}

fn (w &Wire) draw(app data.App) {
	wire_from, zoomed_unit := utils.get_drawing_variables(app, w.ComponentBase)
	wire_to := utils.worldspace_to_screenspace(app, w.wire_to)
	wire_color := match w.state {
		.low {
			data.get_low_color_from_high_color(w.color)
		}
		.high {
			w.color
		}
		.error {
			data.wire_error_color
		}
	}

	rl.draw_line_ex(utils.vec_to_rl(wire_from), utils.vec_to_rl(wire_to), 2, wire_color)
}

fn (mut w Wire) draw_component_window(mut app data.App) {
	if !w.component_window_open {
		return
	}

	pos_in_screen_space := utils.worldspace_to_screenspace(app, w.pos)
	if app.mu.begin_window_ex_bool_controlled('Wire (id: ${w.comp_id})', rl.Rectangle{pos_in_screen_space.x, pos_in_screen_space.y, 200, 85},
		.noscroll | .noresize, w.component_window_open)
	{
		app.mu.layout_row([50, -1], 0)

		app.mu.label('Name')
		app.mu.textbox(w.comp_name)

		app.mu.end_window_bool_controlled(w.component_window_open)
	}
}

pub fn (mut w Wire) on_move(mut app data.App) {
	utils.unregister_wire(mut app, w.pos, w.comp_id)
	utils.unregister_wire(mut app, w.wire_to, w.comp_id)
}

pub fn (mut w Wire) on_moved(mut app data.App) {
	utils.register_wire(mut app, w.pos, w.comp_id)
	utils.register_wire(mut app, w.wire_to, w.comp_id)
	app.sim.wire_table[w.comp_id] = data.WireTableEntry{
		comp_id:       w.comp_id
		component:     w
		wire_from_pos: utils.vec_to_str(w.pos)
		wire_to_pos:   utils.vec_to_str(w.wire_to)
	}
	app.sim.wire_mesh_recalc_needed = true
}
