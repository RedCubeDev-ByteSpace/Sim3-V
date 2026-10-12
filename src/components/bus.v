module components

import data
import math.vec
import raylib as rl
import utils
import imgui

@[heap]
pub struct Bus {
	data.WireBase
}

pub fn Bus.new(mut app data.App, cfg data.BusCfg) Bus {
	// initialize a new component with all its unique data
	mut b := Bus{}

	// initialize the component base with all the standardized data
	b.WireBase = data.WireBase.new(mut app, cfg.wire_from, cfg.wire_to, cfg.color.to_rl())

	// add this wire to the global component list
	b.comp_handle = utils.add_component(mut app, b)

	// create a dummy name for this component
	b.comp_name = 'Bus (${b.comp_handle.id}:${b.comp_handle.gen})'

	// register this wire on the map
	utils.register_wire(mut app, b.wire_from, b.comp_handle)
	utils.register_wire(mut app, b.wire_to, b.comp_handle)

	// new wire! recalculate the meshes
	app.sim.wire_mesh_recalc_needed = true

	// done :)
	return b
}

pub fn (b Bus) get_cfg() data.ComponentCfg {
	return data.BusCfg{
		wire_from: b.wire_from
		wire_to:   b.wire_to
		color:     data.Color.from_rl(b.color)
	}
}

pub fn (mut b Bus) on_move(mut app data.App) {
	utils.unregister_wire(mut app, b.wire_from, b.comp_handle)
	utils.unregister_wire(mut app, b.wire_to, b.comp_handle)
}

pub fn (mut b Bus) on_moved(mut app data.App) {
	utils.register_wire(mut app, b.wire_from, b.comp_handle)
	utils.register_wire(mut app, b.wire_to, b.comp_handle)
	app.sim.wire_mesh_recalc_needed = true
}

pub fn (mut b Bus) on_delete(mut app data.App) {
	utils.unregister_wire(mut app, b.wire_from, b.comp_handle)
	utils.unregister_wire(mut app, b.wire_to, b.comp_handle)
	app.sim.wire_mesh_recalc_needed = true
	utils.remove_component(mut app, b)
}

pub fn (b &Bus) draw(mut app data.App) {
	Bus.draw(mut app.renderers.raylib_direct_renderer, data.worldspace_to_screenspace(app,
		b.wire_from.add(b.offset_from)), data.worldspace_to_screenspace(app, b.wire_to.add(b.offset_to)),
		app.view.zoom, b.color, false)
}

pub fn Bus.draw(mut renderer data.IRenderer, wire_from vec.Vec2[int], wire_to vec.Vec2[int], zoom f32, color rl.Color, single_pixel_wire bool) {
	draw_zoom := if zoom > 1 { 1 } else { zoom }

	if !single_pixel_wire {
		renderer.draw_direct_line(wire_from, wire_to, 2 * data.component_line_thickness * draw_zoom,
			color)
	} else {
		renderer.draw_direct_line(wire_from, wire_to, 0, color)
	}
}

fn (mut b Bus) draw_component_window(mut app data.App) {
	if !b.component_window_open {
		return
	}

	pos_in_screen_space := data.worldspace_to_screenspace(app, b.wire_from.add(b.wire_to).div_scalar[f32](2))
	imgui.set_next_window_pos(imgui.ImVec2{pos_in_screen_space.x, pos_in_screen_space.y},
		int(imgui.Cond_.appearing), imgui.ImVec2{})

	if utils.gui_begin_component_window(b, 'Bus', b.component_window_open) {
		if utils.gui_begin_comp_layout_table(50, 100) {
			imgui.table_next_row(0, 0)

			imgui.table_set_column_index(0)
			utils.gui_do_label('Name')

			imgui.table_set_column_index(1)
			b.comp_name = utils.gui_do_text_input(mut app, '##name_input', b.comp_name)

			imgui.end_table()
		}
	}
	imgui.end()
}
