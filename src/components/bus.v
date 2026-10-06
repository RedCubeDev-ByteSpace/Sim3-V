module components

import data
import math.vec
import raylib as rl
import utils

pub struct Bus {
	data.WireBase
}

pub fn Bus.new(mut app data.App, cfg data.BusCfg) Bus {
	// initialize a new component with all its unique data
	mut b := Bus{}

	// initialize the component base with all the standardized data
	b.WireBase = data.WireBase.new(mut app, cfg.wire_from, cfg.wire_to, cfg.color.to_rl())

	// create a dummy name for this component
	b.comp_name = 'Bus ${b.comp_id}'

	// add this wire to the global component list
	utils.add_component(mut app, b)

	// register this wire on the map
	utils.register_wire(mut app, b.wire_from, b.comp_id)
	utils.register_wire(mut app, b.wire_to, b.comp_id)

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
	utils.unregister_wire(mut app, b.wire_from, b.comp_id)
	utils.unregister_wire(mut app, b.wire_to, b.comp_id)
}

pub fn (mut b Bus) on_moved(mut app data.App) {
	utils.register_wire(mut app, b.wire_from, b.comp_id)
	utils.register_wire(mut app, b.wire_to, b.comp_id)
	app.sim.wire_mesh_recalc_needed = true
}

pub fn (mut b Bus) on_delete(mut app data.App) {
	utils.unregister_wire(mut app, b.wire_from, b.comp_id)
	utils.unregister_wire(mut app, b.wire_to, b.comp_id)
	app.sim.wire_mesh_recalc_needed = true
}

pub fn (b &Bus) draw(app data.App) {
	Bus.draw_static(data.worldspace_to_screenspace(app, b.wire_from.add(b.offset_from)), data.worldspace_to_screenspace(app,
		b.wire_to.add(b.offset_to)), app.view.zoom, b.color, false)
}

pub fn Bus.draw_static(wire_from vec.Vec2[int], wire_to vec.Vec2[int], zoom f32, color rl.Color, single_pixel_wire bool) {
	draw_zoom := if zoom > 1 { 1 } else { zoom }

	if !single_pixel_wire {
		rl.draw_line_ex(utils.vec_to_rl(wire_from), utils.vec_to_rl(wire_to), 2 * data.component_line_thickness * draw_zoom,
			color)
	} else {
		rl.draw_line(int(wire_from.x), int(wire_from.y), int(wire_to.x), int(wire_to.y),
			color)
	}
}

fn (mut b Bus) draw_component_window(mut app data.App) {
	if !b.component_window_open {
		return
	}

	pos_in_screen_space := data.worldspace_to_screenspace(app, b.wire_from.add(b.wire_to).div_scalar[f32](2))
	if app.mu.begin_window_ex_bool_controlled('Bus (id: ${b.comp_id})', rl.Rectangle{pos_in_screen_space.x, pos_in_screen_space.y, 200, 85},
		.noscroll | .noresize, b.component_window_open)
	{
		app.mu.layout_row([50, -1], 0)

		app.mu.label('Name')
		app.mu.textbox(b.comp_name)

		app.mu.end_window_bool_controlled(b.component_window_open)
	}
}
