module components

import raylib as rl
import math.vec
import data
import utils
import imgui

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
		cfg.color.to_rl())

	// add this wire to the global component list
	l.comp_handle = utils.add_component(mut app, l)
	app.sim.wire_mesh_recalc_needed = true

	// create a dummy name for this component
	l.comp_name = 'LED (${l.comp_handle.id}:${l.comp_handle.gen})'

	// calculate where this components bounding box is based on its rotation
	l.aabb_offset = utils.get_aabb_offset_for_rotation(-1, -3, 2, 2, data.Rotation.from_int(cfg.rot))

	// create a new contact point where wires can connect to
	l.contact_point = data.ContactPoint.new(mut app, .floating)
	l.contact_point.contact_handle = utils.add_contact_point(mut app, l.contact_point)
	utils.register_contact_point(mut app, l.pos.x, l.pos.y, mut l.contact_point)

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
	utils.unregister_contact_point(mut app, mut l.contact_point)
}

pub fn (mut l LED) on_moved(mut app data.App) {
	utils.register_contact_point(mut app, l.pos.x, l.pos.y, mut l.contact_point)
	app.sim.wire_mesh_recalc_needed = true
}

pub fn (mut l LED) on_delete(mut app data.App) {
	utils.unregister_contact_point(mut app, mut l.contact_point)
	app.sim.contact_points.remove(l.contact_point.contact_handle)
	app.sim.wire_mesh_recalc_needed = true
	utils.remove_component(mut app, l)
}

fn (l &LED) draw(mut app data.App) {
	contact_point, zoomed_unit := utils.get_drawing_variables(app, l.ComponentBase)
	LED.draw(mut app.renderers.raylib_direct_renderer, contact_point, zoomed_unit, l.color,
		l.contact_point.input_state == .high, l.rotation)
}

pub fn LED.draw(mut renderer data.IRenderer, contact_point vec.Vec2[f32], zoomed_unit f32, color rl.Color, state bool, rot data.Rotation) {
	low_color := data.get_low_color_from_high_color(color)

	renderer.draw_circle_lines(contact_point.x, contact_point.y, zoomed_unit, 0, 0, data.contact_point_size,
		rot, low_color)

	renderer.draw_contact_line(contact_point.x, contact_point.y, zoomed_unit, 0, 0, 0,
		-1, rot, low_color)

	renderer.draw_circle_lines(contact_point.x, contact_point.y, zoomed_unit, 0, -2, 1,
		rot, low_color)

	if state {
		renderer.draw_circle_filled(contact_point.x, contact_point.y, zoomed_unit, 0,
			-2, 0.8, rot, color)
	}
}

fn (mut l LED) draw_component_window(mut app data.App) {
	if !l.component_window_open {
		return
	}

	pos_in_screen_space := data.worldspace_to_screenspace(app, l.pos)
	imgui.set_next_window_pos(imgui.ImVec2{pos_in_screen_space.x, pos_in_screen_space.y},
		int(imgui.Cond_.appearing), imgui.ImVec2{})

	if utils.gui_begin_component_window(l, 'LED', l.component_window_open) {
		if utils.gui_begin_comp_layout_table(50, 100) {
			imgui.table_next_row(0, 0)

			imgui.table_set_column_index(0)
			utils.gui_do_label('Name')

			imgui.table_set_column_index(1)
			l.comp_name = utils.gui_do_text_input(mut app, '##name_input', l.comp_name)

			imgui.end_table()
		}
	}
	imgui.end()
}
