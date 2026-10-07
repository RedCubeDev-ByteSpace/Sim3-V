module components

import raylib as rl
import math.vec
import data
import utils
import render_cache

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

	// -----------------------------------------------------------------------------------------------------------------

	// initialize the component base with all the standardized data
	l.ComponentBase = data.ComponentBase.new(mut app, cfg.pos, vec.vec2[int](2, 2), data.Rotation.from_int(cfg.rot),
		cfg.color.to_rl(), false)

	// create a dummy name for this component
	l.comp_name = 'LED ${l.comp_id}'

	// calculate where this components bounding box is based on its rotation
	l.aabb_offset = utils.get_aabb_offset_for_rotation(-1, -3, 2, 2, data.Rotation.from_int(cfg.rot))

	// -----------------------------------------------------------------------------------------------------------------

	// create a new contact point where wires can connect to
	l.contact_point = data.ContactPoint.new(mut app, .floating)
	app.sim.contact_point_table[l.contact_point.cont_id] = &l.contact_point
	utils.register_contact_point(mut app, l.pos, l.contact_point.cont_id)

	// add this wire to the global component list
	utils.add_component(mut app, l)
	app.sim.wire_mesh_recalc_needed = true

	// -----------------------------------------------------------------------------------------------------------------

	// set up the render settings for caching
	l.render_size, l.render_offset = utils.get_render_rect_for_rotation(-1, -3, vec.Vec2[f32]{2, 4},
		l.rotation)

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

fn (l &LED) draw(mut app data.App) {
	if !app.renderers.use_render_cache {
		contact_point, zoomed_unit := utils.get_drawing_variables(app, l.ComponentBase)
		LED.draw(mut app.renderers.raylib_direct_renderer, contact_point, zoomed_unit,
			l.color, l.contact_point.input_state == .high, l.rotation)

		return
	}

	// -----------------------------------------------------------------------------------------------------------------
	// Render caching

	raw_zoom := app.input.target_zoom

	// what texture would we need?
	cache_key := 'LE_${raw_zoom:.1f}_${int(l.rotation)}_${l.color.r},${l.color.g},${l.color.b},${l.color.a}_${l.contact_point.input_state == .high}'

	// does the texture we need exist already?
	if render_cache.has_cache(app, cache_key) {
		// draw it!
		render_cache.draw_from_cache(app, cache_key, utils.get_render_rect_in_screenspace(app,
			l.get_rendering_rect()), 1)
		return
	}

	// otherwise: create a cache
	render_width, render_height := utils.get_zoomed_render_rect(l.get_rendering_rect(),
		raw_zoom)
	t := render_cache.begin_cache(app, render_width, render_height)

	origin, zoomed_unit := utils.get_render_origin_and_zoom(l.render_offset, raw_zoom)
	LED.draw(mut app.renderers.raylib_direct_renderer, origin, zoomed_unit, l.color, l.contact_point.input_state == .high,
		l.rotation)

	render_cache.end_cache(mut app, cache_key, t)

	// and then draw it
	render_cache.draw_from_cache(app, cache_key, utils.get_render_rect_in_screenspace(app,
		l.get_rendering_rect()), 1)
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
	if app.mu.begin_window_ex_bool_controlled('Switch (id: ${l.comp_id})', rl.Rectangle{pos_in_screen_space.x, pos_in_screen_space.y, 200, 85},
		.noscroll | .noresize, l.component_window_open)
	{
		app.mu.layout_row([50, -1], 0)

		app.mu.label('Name')
		app.mu.textbox(l.comp_name)

		app.mu.end_window_bool_controlled(l.component_window_open)
	}
}
