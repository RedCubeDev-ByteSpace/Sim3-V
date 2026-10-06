module components

import raylib as rl
import math.vec
import data
import utils

@[heap]
struct LED {
	data.ComponentBase
mut:
	// properties for this LED component
	contact_point data.ContactPoint
}

pub fn LED.new(mut app data.App, cfg data.LEDCfg) LED {
	// initialize a new component with all its unique data
	mut l := LED{}

	// initialize the component base with all the standardized data
	l.ComponentBase = data.ComponentBase.new(mut app, cfg.pos, vec.vec2[int](2, 2), data.Rotation.from_int(cfg.rot),
		cfg.color.to_rl(), false)

	// create a dummy name for this component
	l.comp_name = 'LED ${l.comp_id}'

	// calculate where this components bounding box is based on its rotation
	l.aabb_offset = utils.get_aabb_offset_for_rotation(-1, -3, 2, 2, data.Rotation.from_int(cfg.rot))

	// create a new contact point where wires can connect to
	l.contact_point = data.ContactPoint.new(mut app, .floating)
	app.sim.contact_point_table[l.contact_point.cont_id] = &l.contact_point
	utils.register_contact_point(mut app, l.pos, l.contact_point.cont_id)

	// add this wire to the global component list
	utils.add_component(mut app, l)
	app.sim.wire_mesh_recalc_needed = true

	// done :)
	return l
}

pub fn (l LED) get_cfg() data.ComponentCfg {
	return data.LEDCfg{
		pos:   l.pos
		rot:   l.rotation.to_int()
		color: data.Color.from_rl(l.color)
	}
}

pub fn (mut l LED) on_move(mut app data.App) {
	utils.unregister_contact_point(mut app, l.pos, l.contact_point.cont_id)
}

pub fn (mut l LED) on_moved(mut app data.App) {
	utils.register_contact_point(mut app, l.pos, l.contact_point.cont_id)
	app.sim.wire_mesh_recalc_needed = true
}

pub fn (mut l LED) on_delete(mut app data.App) {
	utils.unregister_contact_point(mut app, l.pos, l.contact_point.cont_id)
	app.sim.contact_point_table.delete(l.contact_point.cont_id)
	app.sim.wire_mesh_recalc_needed = true
}

fn (l &LED) draw(app data.App) {
	contact_point, zoomed_unit := utils.get_drawing_variables(app, l.ComponentBase)
	LED.draw_static(contact_point, zoomed_unit, l.color, l.contact_point.input_state == .high,
		l.rotation)
}

pub fn LED.draw_static(contact_point vec.Vec2[f32], zoomed_unit f32, color rl.Color, state bool, rot data.Rotation) {
	low_color := data.get_low_color_from_high_color(color)

	rl.draw_circle_lines(int(contact_point.x), int(contact_point.y), int(zoomed_unit / 4),
		low_color)

	utils.draw_contact_line(contact_point.x, contact_point.y, zoomed_unit, 0, 0, 0, -1,
		rot, low_color)

	utils.draw_circle_lines(contact_point.x, contact_point.y, zoomed_unit, 0, -2, 1, rot,
		low_color)

	if state {
		utils.draw_circle_filled(contact_point.x, contact_point.y, zoomed_unit, 0, -2,
			0.8, rot, color)
	}
}

fn (mut l LED) draw_component_window(mut app data.App) {
	if !l.component_window_open {
		return
	}

	pos_in_screen_space := data.worldspace_to_screenspace(app, l.pos)
	if app.mu.begin_window_ex_bool_controlled('Switch (id: ${l.comp_id})', rl.Rectangle{pos_in_screen_space.x, pos_in_screen_space.y, 200, 85},
		.noscroll | .noresize, l.component_window_open)
	{
		app.mu.layout_row([50, -1], 0)

		app.mu.label('Name')
		app.mu.textbox(l.comp_name)

		app.mu.end_window_bool_controlled(l.component_window_open)
	}
}
