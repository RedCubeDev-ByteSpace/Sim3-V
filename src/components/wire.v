module components

import data
import math.vec
import raylib as rl
import utils
import fonts

pub struct Wire {
	data.WireBase
mut:
	// properties for this wire component
	state data.WireState
}

pub fn Wire.new(mut app data.App, cfg data.WireCfg) Wire {
	// initialize a new component with all its unique data
	mut w := Wire{
		state: .low
	}

	// initialize the component base with all the standardized data
	w.WireBase = data.WireBase.new(mut app, cfg.wire_from, cfg.wire_to, cfg.color)

	// create a dummy name for this component
	w.comp_name = 'Wire ${w.comp_id}'

	// add this wire to the global component list
	utils.add_component(mut app, w)

	// register this wire on the map
	utils.register_wire(mut app, w.wire_from, w.comp_id)
	utils.register_wire(mut app, w.wire_to, w.comp_id)

	// new wire! recalculate the meshes
	app.sim.wire_mesh_recalc_needed = true

	// done :)
	return w
}

pub fn (w Wire) get_cfg() data.ComponentCfg {
	return data.WireCfg{
		wire_from: w.wire_from
		wire_to:   w.wire_to
		color:     w.color
	}
}

pub fn (mut w Wire) set_state(wire_state data.WireState) {
	w.state = wire_state
}

pub fn (mut w Wire) on_move(mut app data.App) {
	utils.unregister_wire(mut app, w.wire_from, w.comp_id)
	utils.unregister_wire(mut app, w.wire_to, w.comp_id)
}

pub fn (mut w Wire) on_moved(mut app data.App) {
	utils.register_wire(mut app, w.wire_from, w.comp_id)
	utils.register_wire(mut app, w.wire_to, w.comp_id)
	app.sim.wire_mesh_recalc_needed = true
}

pub fn (mut w Wire) on_delete(mut app data.App) {
	utils.unregister_wire(mut app, w.wire_from, w.comp_id)
	utils.unregister_wire(mut app, w.wire_to, w.comp_id)
	app.sim.wire_mesh_recalc_needed = true
}

fn (w &Wire) draw(app data.App) {
	Wire.draw(data.worldspace_to_screenspace(app, w.wire_from.add(w.offset_from)), data.worldspace_to_screenspace(app,
		w.wire_to.add(w.offset_to)), w.state, w.color)
}

pub fn Wire.draw(wire_from vec.Vec2[int], wire_to vec.Vec2[int], state data.WireState, color rl.Color) {
	if state == .error {
		rl.draw_line_ex(utils.vec_to_rl(wire_from), utils.vec_to_rl(wire_to), 2 * data.component_line_thickness,
			data.wire_error_color)
	}

	wire_thickness := match state {
		.low {
			data.component_line_thickness
		}
		.high {
			data.component_line_thickness * 1.5
		}
		.error {
			data.component_line_thickness
		}
	}

	rl.draw_line_ex(utils.vec_to_rl(wire_from), utils.vec_to_rl(wire_to), int(wire_thickness),
		color)
}

fn (mut w Wire) draw_component_window(mut app data.App) {
	if !w.component_window_open {
		return
	}

	pos_in_screen_space := data.worldspace_to_screenspace(app, w.wire_from.add(w.wire_to).div_scalar[f32](2))
	if app.mu.begin_window_ex_bool_controlled('Wire (id: ${w.comp_id})', rl.Rectangle{pos_in_screen_space.x, pos_in_screen_space.y, 200, 85},
		.noscroll | .noresize, w.component_window_open)
	{
		app.mu.layout_row([50, -1], 0)

		app.mu.label('Name')
		app.mu.textbox(w.comp_name)

		app.mu.end_window_bool_controlled(w.component_window_open)
	}
}
