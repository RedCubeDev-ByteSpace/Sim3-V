module components

import data
import math.vec
import raylib as rl
import utils
import render_cache
import fonts

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

	// -----------------------------------------------------------------------------------------------------------------

	// initialize the component base with all the standardized data
	c.ComponentBase = data.ComponentBase.new(mut app, cfg.pos, vec.vec2[int](1, 1), data.Rotation.from_int(cfg.rot),
		cfg.color.to_rl(), false)

	// create a dummy name for this component
	c.comp_name = 'Fixed Contact ${c.comp_id}'

	// calculate where this components bounding box is based on its rotation
	c.aabb_offset = utils.get_aabb_offset_for_rotation(-0.5, -1.5, 1, 1, data.Rotation.from_int(cfg.rot))

	// -----------------------------------------------------------------------------------------------------------------

	// create a new contact point where wires can connect to
	c.contact_point = data.ContactPoint.new(mut app, if cfg.state { .high } else { .low })
	app.sim.contact_point_table[c.contact_point.cont_id] = &c.contact_point
	utils.register_contact_point(mut app, c.pos, c.contact_point.cont_id)

	// add this wire to the global component list
	utils.add_component(mut app, c)
	app.sim.wire_mesh_recalc_needed = true

	// -----------------------------------------------------------------------------------------------------------------

	// set up the render settings for caching
	c.render_size, c.render_offset = utils.get_render_rect_for_rotation(-0.5, -1.5, vec.Vec2[f32]{1, 2},
		c.rotation)

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

fn (f &FixedContact) draw(mut app data.App) {
	if !app.renderers.use_render_cache {
		contact_point, zoomed_unit := utils.get_drawing_variables(app, f.ComponentBase)
		FixedContact.draw(mut app.renderers.raylib_direct_renderer, contact_point, zoomed_unit,
			f.color, app.fonts.fixed_contact_label_font, app.fonts.fixed_contact_label_font_size,
			f.state, f.rotation)
		return
	}

	// -----------------------------------------------------------------------------------------------------------------
	// Render caching

	raw_zoom := app.input.target_zoom

	// what texture would we need?
	cache_key := 'FC_${raw_zoom:.1f}_${int(f.rotation)}_${f.color.r},${f.color.g},${f.color.b},${f.color.a}_${f.state}'

	// does the texture we need exist already?
	if render_cache.has_cache(app, cache_key) {
		// draw it!
		render_cache.draw_from_cache(app, cache_key, utils.get_render_rect_in_screenspace(app,
			f.get_rendering_rect()), 1)
		return
	}

	// otherwise: create a cache
	render_width, render_height := utils.get_zoomed_render_rect(f.get_rendering_rect(),
		raw_zoom)
	t := render_cache.begin_cache(app, render_width, render_height)

	origin, zoomed_unit := utils.get_render_origin_and_zoom(f.render_offset, raw_zoom)
	font_size := zoomed_unit * 0.75
	font := fonts.get_font_for_size(app, int(font_size))
	FixedContact.draw(mut app.renderers.raylib_direct_renderer, origin, zoomed_unit, f.color,
		font, font_size, f.state, f.rotation)

	render_cache.end_cache(mut app, cache_key, t)

	// and then draw it
	render_cache.draw_from_cache(app, cache_key, utils.get_render_rect_in_screenspace(app,
		f.get_rendering_rect()), 1)
}

pub fn FixedContact.draw(mut renderer data.IRenderer, contact_point vec.Vec2[f32], zoomed_unit f32, color rl.Color, font rl.Font, font_size f32, state bool, rot data.Rotation) {
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
		state_label, font_size, font, rot, draw_color)
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
