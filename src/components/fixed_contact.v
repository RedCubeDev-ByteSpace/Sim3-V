module components

import data
import math.vec
import raylib as rl
import utils
import imgui

@[heap]
struct FixedContact {
	data.ComponentBase
mut:
	// properties for this fixed contact component
	state         bool
	contact_point data.ContactPoint
}

pub fn FixedContact.new(mut app data.App, cfg data.FixedContactCfg) FixedContact {
	// initialize a new component with all its unique data
	mut c := FixedContact{
		state: cfg.state
	}

	// initialize the component base with all the standardized data
	c.ComponentBase = data.ComponentBase.new(mut app, cfg.pos, vec.vec2[int](1, 1), data.Rotation.from_int(cfg.rot),
		cfg.color.to_rl())

	// add this wire to the global component list
	c.comp_handle = utils.add_component(mut app, c)
	app.sim.wire_mesh_recalc_needed = true

	// create a dummy name for this component
	c.comp_name = 'Fixed Contact (${c.comp_handle.id}:${c.comp_handle.gen})'

	// calculate where this components bounding box is based on its rotation
	c.aabb_offset = utils.get_aabb_offset_for_rotation(-0.5, -1.5, 1, 1, data.Rotation.from_int(cfg.rot))

	// create a new contact point where wires can connect to
	c.contact_point = data.ContactPoint.new(mut app, if cfg.state { .high } else { .low })
	c.contact_point.contact_handle = utils.add_contact_point(mut app, c.contact_point)
	utils.register_contact_point(mut app, c.pos.x, c.pos.y, mut c.contact_point)

	// done :)
	return c
}

pub fn (f FixedContact) get_cfg() data.ComponentCfg {
	return data.FixedContactCfg{
		pos:   f.pos
		rot:   f.rotation.to_int()
		color: data.Color.from_rl(f.color)
		state: f.state
	}
}

pub fn (mut f FixedContact) on_move(mut app data.App) {
	utils.unregister_contact_point(mut app, mut f.contact_point)
}

pub fn (mut f FixedContact) on_moved(mut app data.App) {
	utils.register_contact_point(mut app, f.pos.x, f.pos.y, mut f.contact_point)
	app.sim.wire_mesh_recalc_needed = true
}

pub fn (mut f FixedContact) on_delete(mut app data.App) {
	utils.unregister_contact_point(mut app, mut f.contact_point)
	app.sim.contact_points.remove(f.contact_point.contact_handle)
	app.sim.wire_mesh_recalc_needed = true
	utils.remove_component(mut app, f)
}

fn (f &FixedContact) draw(mut app data.App) {
	contact_point, zoomed_unit := utils.get_drawing_variables(app, f.ComponentBase)
	FixedContact.draw(mut app.renderers.raylib_direct_renderer, app, contact_point, zoomed_unit,
		f.color, f.state, f.rotation)
}

pub fn FixedContact.draw(mut renderer data.IRenderer, app &data.App, contact_point vec.Vec2[f32], zoomed_unit f32, color rl.Color, state bool, rot data.Rotation) {
	low_color := data.get_low_color_from_high_color(color)
	draw_color := if state { color } else { low_color }

	renderer.draw_circle_lines(contact_point.x, contact_point.y, zoomed_unit, 0, 0, data.contact_point_size,
		rot, draw_color)

	renderer.draw_contact_line(contact_point.x, contact_point.y, zoomed_unit, 0, 0, 0,
		-0.5, rot, draw_color)

	renderer.draw_component_rectangle(contact_point.x, contact_point.y, zoomed_unit, -0.5,
		-1.5, 1, 1, rot, draw_color)

	state_label := if state { '1' } else { '0' }
	renderer.draw_centered_text(contact_point.x, contact_point.y, zoomed_unit, 0, -1,
		state_label, app.fonts.fixed_contact_label_font_size, app.fonts.fixed_contact_label_font,
		rot, draw_color)
}

fn (mut f FixedContact) draw_component_window(mut app data.App) {
	if !f.component_window_open {
		return
	}

	pos_in_screen_space := data.worldspace_to_screenspace(app, f.pos)
	imgui.set_next_window_pos(imgui.ImVec2{pos_in_screen_space.x, pos_in_screen_space.y},
		int(imgui.Cond_.appearing), imgui.ImVec2{})

	if utils.gui_begin_component_window(f, 'Fixed Contact', f.component_window_open) {
		if utils.gui_begin_comp_layout_table(50, 100) {
			imgui.table_next_row(0, 0)

			imgui.table_set_column_index(0)
			utils.gui_do_label('Name')

			imgui.table_set_column_index(1)
			f.comp_name = utils.gui_do_text_input(mut app, '##name_input', f.comp_name)

			imgui.table_next_row(0, 0)

			imgui.table_set_column_index(0)
			utils.gui_do_label('State')

			imgui.table_set_column_index(1)
			if imgui.checkbox(c'##state_check', f.state) {
				f.contact_point.set_output_state(mut app, if f.state { .high } else { .low })
			}

			imgui.end_table()
		}
	}
	imgui.end()
}
