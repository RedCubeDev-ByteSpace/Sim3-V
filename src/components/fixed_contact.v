module components

import data
import math.vec
import raylib as rl
import utils

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
		cfg.color.to_rl(), false)

	// create a dummy name for this component
	c.comp_name = 'Fixed Contact ${c.comp_id}'

	// calculate where this components bounding box is based on its rotation
	c.aabb_offset = utils.get_aabb_offset_for_rotation(-0.5, -1.5, 1, 1, data.Rotation.from_int(cfg.rot))

	// create a new contact point where wires can connect to
	c.contact_point = data.ContactPoint.new(mut app, if cfg.state { .high } else { .low })
	app.sim.contact_point_table[c.contact_point.cont_id] = &c.contact_point
	utils.register_contact_point(mut app, c.pos, c.contact_point.cont_id)

	// add this wire to the global component list
	utils.add_component(mut app, c)
	app.sim.wire_mesh_recalc_needed = true

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
	utils.unregister_contact_point(mut app, f.pos, f.contact_point.cont_id)
}

pub fn (mut f FixedContact) on_moved(mut app data.App) {
	utils.register_contact_point(mut app, f.pos, f.contact_point.cont_id)
	app.sim.wire_mesh_recalc_needed = true
}

pub fn (mut f FixedContact) on_delete(mut app data.App) {
	utils.unregister_contact_point(mut app, f.pos, f.contact_point.cont_id)
	app.sim.contact_point_table.delete(f.contact_point.cont_id)
	app.sim.wire_mesh_recalc_needed = true
}

fn (f &FixedContact) draw(app data.App) {
	contact_point, zoomed_unit := utils.get_drawing_variables(app, f.ComponentBase)
	FixedContact.draw(app, contact_point, zoomed_unit, f.color, f.state, f.rotation)
}

pub fn FixedContact.draw(app data.App, contact_point vec.Vec2[f32], zoomed_unit f32, color rl.Color, state bool, rot data.Rotation) {
	low_color := data.get_low_color_from_high_color(color)
	draw_color := if state { color } else { low_color }

	rl.draw_circle_lines(int(contact_point.x), int(contact_point.y), int(zoomed_unit / 4),
		draw_color)

	utils.draw_contact_line(contact_point.x, contact_point.y, zoomed_unit, 0, 0, 0, -0.5,
		rot, draw_color)

	utils.draw_component_rectangle(contact_point.x, contact_point.y, zoomed_unit, -0.5,
		-1.5, 1, 1, rot, draw_color)

	state_label := if state { '1' } else { '0' }
	utils.draw_centered_text(app, contact_point.x, contact_point.y, zoomed_unit, 0, -1,
		state_label, app.fonts.fixed_contact_label_font_size, app.fonts.fixed_contact_label_font,
		rot, draw_color)
}

fn (mut f FixedContact) draw_component_window(mut app data.App) {
	if !f.component_window_open {
		return
	}

	pos_in_screen_space := data.worldspace_to_screenspace(app, f.pos)
	if app.mu.begin_window_ex_bool_controlled('Fixed Contact (id: ${f.comp_id})', rl.Rectangle{pos_in_screen_space.x, pos_in_screen_space.y, 200, 85},
		.noscroll | .noresize, f.component_window_open)
	{
		app.mu.layout_row([50, -1], 0)

		app.mu.label('Name')
		app.mu.textbox(f.comp_name)

		app.mu.label('State')
		if app.mu.checkbox('', f.state) {
			f.contact_point.output_state = if f.state { .high } else { .low }
		}

		app.mu.end_window_bool_controlled(f.component_window_open)
	}
}
