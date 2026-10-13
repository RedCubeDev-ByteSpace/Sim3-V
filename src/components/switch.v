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
	tri_state     bool
	state         i32
	contact_point data.ContactPoint
}

pub fn Switch.new(mut app data.App, cfg data.SwitchCfg) Switch {
	// initialize a new component with all its unique data
	mut s := Switch{
		tri_state: cfg.tri_state
		state:     cfg.state
	}

	// initialize the component base with all the standardized data
	s.ComponentBase = data.ComponentBase.new_interactable(mut app, cfg.pos, vec.vec2[int](2,
		2), data.Rotation.from_int(cfg.rot), cfg.color.to_rl())

	// add this wire to the global component list
	s.comp_handle = utils.add_component(mut app, s)
	app.sim.wire_mesh_recalc_needed = true

	// create a dummy name for this component
	s.comp_name = 'Switch (${s.comp_handle.id}:${s.comp_handle.gen})'

	// calculate where this components bounding box is based on its rotation
	s.aabb_offset = utils.get_aabb_offset_for_rotation(-1, -3, 2, 2, data.Rotation.from_int(cfg.rot))

	// create a new contact point where wires can connect to
	s.contact_point = data.ContactPoint.new(mut app, match s.state {
		0 { .low }
		1 { .high }
		else { .floating }
	})
	s.contact_point.contact_handle = utils.add_contact_point(mut app, s.contact_point)
	utils.register_contact_point(mut app, s.pos.x, s.pos.y, mut s.contact_point)

	// done :)
	return s
}

pub fn (s Switch) get_cfg() data.ComponentCfg {
	return data.SwitchCfg{
		pos:       s.pos
		rot:       s.rotation.to_int()
		color:     data.Color.from_rl(s.color)
		tri_state: s.tri_state
		state:     s.state
	}
}

fn (mut s Switch) interact(mut app data.App) {
	s.state++
	s.state %= if s.tri_state { 3 } else { 2 }

	s.contact_point.set_output_state(mut app, match s.state {
		0 { .low }
		1 { .high }
		else { .floating }
	})
}

pub fn (mut s Switch) on_move(mut app data.App) {
	utils.unregister_contact_point(mut app, mut s.contact_point)
}

pub fn (mut s Switch) on_moved(mut app data.App) {
	utils.register_contact_point(mut app, s.pos.x, s.pos.y, mut s.contact_point)
	app.sim.wire_mesh_recalc_needed = true
}

pub fn (mut s Switch) on_delete(mut app data.App) {
	utils.unregister_contact_point(mut app, mut s.contact_point)
	app.sim.contact_points.remove(s.contact_point.contact_handle)
	app.sim.wire_mesh_recalc_needed = true
	utils.remove_component(mut app, s)
}

fn (s &Switch) draw(mut app data.App) {
	contact_point, zoomed_unit := utils.get_drawing_variables(app, s.ComponentBase)
	Switch.draw(mut app.renderers.raylib_direct_renderer, contact_point, zoomed_unit,
		s.color, s.state, s.rotation)
}

pub fn Switch.draw(mut renderer data.IRenderer, contact_point vec.Vec2[f32], zoomed_unit f32, color rl.Color, state int, rot data.Rotation) {
	low_color := data.get_low_color_from_high_color(color)

	renderer.draw_circle_lines(contact_point.x, contact_point.y, zoomed_unit, 0, 0, data.contact_point_size,
		rot, low_color)

	renderer.draw_contact_line(contact_point.x, contact_point.y, zoomed_unit, 0, 0, 0,
		-1, rot, low_color)

	renderer.draw_component_rectangle(contact_point.x, contact_point.y, zoomed_unit, -1,
		-3, 2, 2, rot, low_color)

	if state > 1 {
		renderer.draw_circle_lines(contact_point.x, contact_point.y, zoomed_unit, 0, -2,
			0.5, rot, low_color)
	} else {
		renderer.draw_circle_filled(contact_point.x, contact_point.y, zoomed_unit, 0,
			-2, 0.5, rot, if state == 1 { color } else { low_color })
	}
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
			utils.gui_do_label('Tri-State')

			imgui.table_set_column_index(1)
			if imgui.checkbox(c'##tri_state_check', s.tri_state) {
				s.state %= if s.tri_state { 3 } else { 2 }
				s.contact_point.set_output_state(mut app, match s.state {
					0 { .low }
					1 { .high }
					else { .floating }
				})
			}

			imgui.table_next_row(0, 0)

			imgui.table_set_column_index(0)
			utils.gui_do_label('State')

			imgui.table_set_column_index(1)
			imgui.set_next_item_width(imgui.get_content_region_avail().x)
			if imgui.slider_int(c'##state_slider', s.state, 0, if s.tri_state { 2 } else { 1 },
				(match s.state {
				0 { 'LOW' }
				1 { 'HIGH' }
				else { 'FLOATING' }
			}).str, 0)
			{
				s.state %= if s.tri_state { 3 } else { 2 }
				s.contact_point.set_output_state(mut app, match s.state {
					0 { .low }
					1 { .high }
					else { .floating }
				})
			}

			imgui.end_table()
		}
	}
	imgui.end()
}
