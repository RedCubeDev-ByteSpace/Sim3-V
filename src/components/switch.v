module components

import raylib as rl
import math.vec
import data
import utils
import imgui

@[heap]
struct Switch {
	data.ComponentBase
mut:
	// properties for this switch component
	state         bool
	contact_point data.ContactPoint
}

pub fn Switch.new(mut app data.App, cfg data.SwitchCfg) Switch {
	// initialize a new component with all its unique data
	mut s := Switch{
		state: cfg.state
	}

	// initialize the component base with all the standardized data
	s.ComponentBase = data.ComponentBase.new(mut app, cfg.pos, vec.vec2[int](2, 2), data.Rotation.from_int(cfg.rot),
		cfg.color.to_rl(), true)

	// add this wire to the global component list
	s.comp_handle = utils.add_component(mut app, s)
	app.sim.wire_mesh_recalc_needed = true

	// create a dummy name for this component
	s.comp_name = 'Switch (${s.comp_handle.id}:${s.comp_handle.gen})'

	// calculate where this components bounding box is based on its rotation
	s.aabb_offset = utils.get_aabb_offset_for_rotation(-1, -3, 2, 2, data.Rotation.from_int(cfg.rot))

	// create a new contact point where wires can connect to
	s.contact_point = data.ContactPoint.new(mut app, if cfg.state { .high } else { .low })
	app.sim.contact_point_table[s.contact_point.cont_id] = &s.contact_point
	utils.register_contact_point(mut app, s.pos, s.contact_point.cont_id)

	// done :)
	return s
}

pub fn (s Switch) get_cfg() data.ComponentCfg {
	return data.SwitchCfg{
		pos:   s.pos
		rot:   s.rotation.to_int()
		color: data.Color.from_rl(s.color)
		state: s.state
	}
}

fn (mut s Switch) interact(mut app data.App) {
	s.state = !s.state
	s.contact_point.set_output_state(mut app, if s.state { .high } else { .low })
}

pub fn (mut s Switch) on_move(mut app data.App) {
	utils.unregister_contact_point(mut app, s.pos, s.contact_point.cont_id)
}

pub fn (mut s Switch) on_moved(mut app data.App) {
	utils.register_contact_point(mut app, s.pos, s.contact_point.cont_id)
	app.sim.wire_mesh_recalc_needed = true
}

pub fn (mut s Switch) on_delete(mut app data.App) {
	utils.unregister_contact_point(mut app, s.pos, s.contact_point.cont_id)
	app.sim.contact_point_table.delete(s.contact_point.cont_id)
	app.sim.wire_mesh_recalc_needed = true
	utils.remove_component(mut app, s)
}

fn (s &Switch) draw(mut app data.App) {
	contact_point, zoomed_unit := utils.get_drawing_variables(app, s.ComponentBase)
	Switch.draw(mut app.renderers.raylib_direct_renderer, contact_point, zoomed_unit,
		s.color, s.state, s.rotation)
}

pub fn Switch.draw(mut renderer data.IRenderer, contact_point vec.Vec2[f32], zoomed_unit f32, color rl.Color, state bool, rot data.Rotation) {
	low_color := data.get_low_color_from_high_color(color)

	renderer.draw_circle_lines(contact_point.x, contact_point.y, zoomed_unit, 0, 0, data.contact_point_size,
		rot, low_color)

	renderer.draw_contact_line(contact_point.x, contact_point.y, zoomed_unit, 0, 0, 0,
		-1, rot, low_color)

	renderer.draw_component_rectangle(contact_point.x, contact_point.y, zoomed_unit, -1,
		-3, 2, 2, rot, low_color)

	renderer.draw_circle_filled(contact_point.x, contact_point.y, zoomed_unit, 0, -2,
		0.5, rot, if state { color } else { low_color })
}

fn (mut s Switch) draw_component_window(mut app data.App) {
	if !s.component_window_open {
		return
	}

	pos_in_screen_space := data.worldspace_to_screenspace(app, s.pos)
	imgui.set_next_window_pos(imgui.ImVec2{pos_in_screen_space.x, pos_in_screen_space.y},
		int(imgui.Cond_.appearing), imgui.ImVec2{})

	if utils.gui_begin_component_window(s, 'Switch', s.component_window_open) {
		if utils.gui_begin_comp_layout_table(50, 100) {
			imgui.table_next_row(0, 0)

			imgui.table_set_column_index(0)
			utils.gui_do_label('Name')

			imgui.table_set_column_index(1)
			s.comp_name = utils.gui_do_text_input(mut app, '##name_input', s.comp_name)

			imgui.table_next_row(0, 0)

			imgui.table_set_column_index(0)
			utils.gui_do_label('State')

			imgui.table_set_column_index(1)
			imgui.checkbox(c'##state_check', s.state)

			imgui.end_table()
		}
	}
	imgui.end()
}
