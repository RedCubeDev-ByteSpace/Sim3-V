module components

import data
import math.vec
import raylib as rl
import utils
import imgui

@[heap]
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
	w.WireBase = data.WireBase.new(mut app, cfg.wire_from, cfg.wire_to, cfg.color.to_rl())

	// add this wire to the global component list
	w.comp_handle = utils.add_component(mut app, w)

	// create a dummy name for this component
	w.comp_name = 'Wire (${w.comp_handle.id}:${w.comp_handle.gen})'

	// register this wire on the map
	utils.register_wire(mut app, w.wire_from, w.comp_handle)
	utils.register_wire(mut app, w.wire_to, w.comp_handle)

	// new wire! recalculate the meshes
	app.sim.wire_mesh_recalc_needed = true

	// done :)
	return w
}

pub fn (w Wire) get_cfg() data.ComponentCfg {
	return data.WireCfg{
		wire_from: w.wire_from
		wire_to:   w.wire_to
		color:     data.Color.from_rl(w.color)
	}
}

pub fn (mut w Wire) set_state(wire_state data.WireState) {
	w.state = wire_state
}

pub fn (mut w Wire) on_move(mut app data.App) {
	utils.unregister_wire(mut app, w.wire_from, w.comp_handle)
	utils.unregister_wire(mut app, w.wire_to, w.comp_handle)
}

pub fn (mut w Wire) on_moved(mut app data.App) {
	utils.register_wire(mut app, w.wire_from, w.comp_handle)
	utils.register_wire(mut app, w.wire_to, w.comp_handle)
	app.sim.wire_mesh_recalc_needed = true
}

pub fn (mut w Wire) on_delete(mut app data.App) {
	utils.unregister_wire(mut app, w.wire_from, w.comp_handle)
	utils.unregister_wire(mut app, w.wire_to, w.comp_handle)
	app.sim.wire_mesh_recalc_needed = true
	utils.remove_component(mut app, w)
}

fn (w &Wire) draw(mut app data.App) {
	Wire.draw(mut app.renderers.raylib_direct_renderer, data.worldspace_to_screenspace(app,
		w.wire_from.add(w.offset_from)), data.worldspace_to_screenspace(app, w.wire_to.add(w.offset_to)),
		app.view.zoom, w.state, w.color, false)
}

pub fn Wire.draw(mut renderer data.IRenderer, wire_from vec.Vec2[int], wire_to vec.Vec2[int], zoom f32, state data.WireState, color rl.Color, single_pixel_wire bool) {
	draw_zoom := if zoom > 1 { 1 } else { zoom }

	if state == .error {
		renderer.draw_direct_line(wire_from, wire_to, f32(2 * data.component_line_thickness * draw_zoom),
			data.wire_error_color)
	}

	wire_thickness := match state {
		.low, .uninitialized {
			data.component_line_thickness
		}
		.high {
			data.component_line_thickness * 1.5
		}
		.error {
			data.component_line_thickness
		}
	}

	if !single_pixel_wire {
		renderer.draw_direct_line(wire_from, wire_to, f32(wire_thickness * draw_zoom),
			color)
	} else {
		renderer.draw_direct_line(wire_from, wire_to, 0, color)
	}
}

fn (mut w Wire) draw_component_window(mut app data.App) {
	if !w.component_window_open {
		return
	}

	pos_in_screen_space := data.worldspace_to_screenspace(app, w.wire_from.add(w.wire_to).div_scalar[f32](2))
	imgui.set_next_window_pos(imgui.ImVec2{pos_in_screen_space.x, pos_in_screen_space.y},
		int(imgui.Cond_.appearing), imgui.ImVec2{})

	if utils.gui_begin_component_window(w, 'Wire', w.component_window_open) {
		if utils.gui_begin_comp_layout_table(50, 100) {
			imgui.table_next_row(0, 0)

			imgui.table_set_column_index(0)
			utils.gui_do_label('Name')

			imgui.table_set_column_index(1)
			w.comp_name = utils.gui_do_text_input(mut app, '##name_input', w.comp_name)

			imgui.end_table()
		}
	}
	imgui.end()
}
