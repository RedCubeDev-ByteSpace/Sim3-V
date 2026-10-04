module simview

import data
import utils
import raylib as rl
import math.vec
import components

// simview -------------------------------------------------------------------------------------------------------------
// this module is all about the drawing side of things
// it supplies all the objects that are drawable in the simulation space
// it also takes care of rendering those objects to the screen and drawing the background grid

pub fn draw_view(app data.App) {
	draw_grid(app)
	draw_selection(app)
	draw_wires(app)
	draw_components(app)
	draw_wire_branching_points(app)
	draw_selected_component_outlines(app)
	draw_wire_movement_handles(app)
	draw_preview_of_component_being_placed(app)
	draw_preview_of_components_being_pasted(app)
	draw_preview_of_blueprint_being_placed(app)
	draw_contact_points(app)
}

fn draw_wires(app data.App) {
	// get the AABB for the current viewport
	view_aabb := data.get_viewport_aabb(app)

	for comp in app.sim.components.values() {
		if comp is data.IWireBase {
		} else {
			continue
		}

		// only draw components that are touching the current viewports aabb
		if data.do_aabbs_intersect(view_aabb, comp.get_aabb()) {
			comp.draw(app)

			// if enabled: draw bounding boxes
			if app.view.debug.show_aabb {
				draw_aabb(app, comp.get_aabb(), data.aabb_color)
			}
		}
	}
}

fn draw_components(app data.App) {
	// get the AABB for the current viewport
	view_aabb := data.get_viewport_aabb(app)

	for comp in app.sim.components.values() {
		if comp is data.IWireBase {
			continue
		}

		// only draw components that are touching the current viewports aabb
		if data.do_aabbs_intersect(view_aabb, comp.get_aabb()) {
			comp.draw(app)

			// if enabled: draw bounding boxes
			if app.view.debug.show_aabb {
				draw_aabb(app, comp.get_aabb(), data.aabb_color)
			}
		}
	}
}

fn draw_wire_branching_points(app data.App) {
	for marker in app.sim.wire_branching_points {
		marker_pos := data.worldspace_to_screenspace(app, marker.pos)

		rl.draw_circle(marker_pos.x, marker_pos.y, app.view.zoom * 3, marker.color)
	}
}

fn draw_aabb(app data.App, aabb data.AABB, color rl.Color) {
	top_left := data.worldspace_to_screenspace(app, vec.vec2[f32](aabb.x, aabb.y))
	zoomed_unit := data.one_simspace_unit_in_px * app.view.zoom
	rl.draw_rectangle_lines(int(top_left.x), int(top_left.y), int(aabb.width * zoomed_unit),
		int(aabb.height * zoomed_unit), color)
}

fn draw_selection(app data.App) {
	if app.bench.bench_state != .selecting {
		return
	}

	mut x1 := app.input.selecting_start_pos.x
	mut y1 := app.input.selecting_start_pos.y
	mut x2 := app.input.mouse_pos.x
	mut y2 := app.input.mouse_pos.y

	// make sure x1, y1 is always the top left corner
	if y1 > y2 {
		y1, y2 = y2, y1
	}
	if x1 > x2 {
		x1, x2 = x2, x1
	}

	draw_marching_ants(app, rl.Rectangle{x1, y1, x2 - x1, y2 - y1}, data.selection_color_high)
}

fn draw_selected_component_outlines(app data.App) {
	for comp in app.bench.selected_components {
		aabb := comp.get_aabb()
		top_left := data.worldspace_to_screenspace(app, vec.vec2[f32](aabb.x, aabb.y))
		zoomed_unit := data.one_simspace_unit_in_px * app.view.zoom
		draw_marching_ants(app, rl.Rectangle{top_left.x, top_left.y, aabb.width * zoomed_unit, aabb.height * zoomed_unit},
			data.selection_color_low)
	}
}

fn draw_wire_movement_handles(app data.App) {
	if !app.bench.wire_moving.draw_hover_box {
		return
	}

	wire := app.sim.components[app.bench.wire_moving.wire_id]
	if wire is data.IWireBase {
		base := wire.get_base()
		rect_world := if app.bench.wire_moving.wire_end == .from {
			base.get_from_aabb()
		} else {
			base.get_to_aabb()
		}
		offset := if app.bench.wire_moving.wire_end == .from {
			base.get_offset_from()
		} else {
			base.get_offset_to()
		}
		offset_rect_world := rl.Rectangle{
			...rect_world
			x: rect_world.x + offset.x
			y: rect_world.y + offset.y
		}

		rect_screen := data.rect_worldspace_to_screenspace(app, offset_rect_world)
		rl.draw_rectangle_lines_ex(rect_screen, 1, data.wire_handle_color)
	}
}

pub fn step_marching_ants(mut app data.App) {
	app.bench.marching_ants_frame_counter++
	if app.bench.marching_ants_frame_counter == data.step_marching_ants_every_frames {
		app.bench.marching_ants_starting_point++
		app.bench.marching_ants_starting_point = app.bench.marching_ants_starting_point % (data.marching_ants_segment_size * 2)
		app.bench.marching_ants_frame_counter = 0
	}
}

fn draw_marching_ants(app data.App, rect rl.Rectangle, color rl.Color) {
	// draw the rectangle in the low color as the base
	mut offset := app.bench.marching_ants_starting_point
	offset = draw_marching_ants_line(app, color, offset, int(rect.x), int(rect.x + rect.width),
		int(rect.y), false, false)
	offset = draw_marching_ants_line(app, color, offset, int(rect.y), int(rect.y + rect.height),
		int(rect.x + rect.width), true, true)
	offset = draw_marching_ants_line(app, color, offset, int(rect.x), int(rect.x + rect.width),
		int(rect.y + rect.height), false, false)
	draw_marching_ants_line(app, color, offset, int(rect.y), int(rect.y + rect.height),
		int(rect.x), true, true)
}

fn draw_marching_ants_line(app data.App, color rl.Color, off int, s int, e int, level int, vertical bool, reverse bool) int {
	mut start := s
	mut end := e
	if start > end {
		start, end = end, start
	}

	offset := if !reverse { off } else { data.marching_ants_segment_size * 2 - 1 - off }

	mut active := if offset < data.marching_ants_segment_size { true } else { false }
	if !active {
		if !vertical {
			rl.draw_line(start, level, start + offset % data.marching_ants_segment_size,
				level, color)
		} else {
			rl.draw_line(level, start, level, start + offset % data.marching_ants_segment_size,
				color)
		}
	}

	start += offset % data.marching_ants_segment_size
	num_segments := int((end - start) / data.marching_ants_segment_size)
	for i in 0 .. num_segments {
		if active {
			if !vertical {
				rl.draw_line(start + data.marching_ants_segment_size * i, level, start +
					data.marching_ants_segment_size * (i + 1), level, color)
			} else {
				rl.draw_line(level, start + data.marching_ants_segment_size * i, level,
					start + data.marching_ants_segment_size * (i + 1), color)
			}
		}
		active = !active
	}

	if active {
		if !vertical {
			rl.draw_line(start + data.marching_ants_segment_size * num_segments, level,
				start + data.marching_ants_segment_size * num_segments +
				int(end - start) % data.marching_ants_segment_size, level, color)
		} else {
			rl.draw_line(level, start + data.marching_ants_segment_size * num_segments,
				level, start + data.marching_ants_segment_size * num_segments +
				int(end - start) % data.marching_ants_segment_size, color)
		}
	}

	return (int(end - start) % data.marching_ants_segment_size) + if !reverse {
		if active {
			0
		} else {
			data.marching_ants_segment_size
		}
	} else {
		if active {
			data.marching_ants_segment_size
		} else {
			0
		}
	}
}

fn draw_preview_of_component_being_placed(app data.App) {
	if app.bench.placement.current_selected_component_type == .none {
		return
	}

	// figure out where to draw this preview of a component
	mouse_pos_world_space := data.screenspace_to_worldspace(app, app.input.mouse_pos)
	comp_pos_screen_space := data.worldspace_to_screenspace(app, utils.roundificate_to_whole_point(mouse_pos_world_space))

	// prepare the variables needed for drawing any components
	pos := vec.vec2(f32(comp_pos_screen_space.x), f32(comp_pos_screen_space.y))
	zoomed_unit := data.one_simspace_unit_in_px * app.view.zoom
	color := rl.Color{
		...data.wire_colors[app.bench.placement.current_selected_color_idx]
		a: 150
	}

	// draw the preview using the components static draw function
	match app.bench.placement.current_selected_component_type {
		.none {}
		.switch {
			components.Switch.draw(pos, zoomed_unit, color, false, app.bench.placement.rotation)
		}
		.fixed_contact {
			components.FixedContact.draw(app, pos, zoomed_unit, color, false, app.bench.placement.rotation)
		}
		.clock {
			components.Clock.draw(pos, zoomed_unit, color, 0, 0, app.bench.placement.rotation)
		}
		.led {
			components.LED.draw(pos, zoomed_unit, color, false, app.bench.placement.rotation)
		}
		.chip {
			components.Chip.draw(app, pos, zoomed_unit, color, app.bench.placement.rotation,
				app.bench.placement.current_selected_chip_uid, []data.ContactPoint{})
		}
		.wire, .bus {
			if !app.bench.placement.placed_wire_starting_point {
				rl.draw_circle_lines(comp_pos_screen_space.x, comp_pos_screen_space.y,
					5, color)
			} else {
				start_pos := data.worldspace_to_screenspace(app, app.input.wire_place_start_pos)
				rl.draw_line_ex(rl.Vector2{
					x: start_pos.x
					y: start_pos.y
				}, rl.Vector2{
					x: pos.x
					y: pos.y
				}, 2, color)
			}
		}
	}
}

fn draw_preview_of_components_being_pasted(app data.App) {
	if app.bench.bench_state != .pasting_components {
		return
	}

	// draw the preview using the components static draw function
	for cfg in app.bench.clipboard.current_clip_board {
		color := rl.Color{
			...cfg.as_interface().get_color()
			a: 150
		}

		draw_component_from_cfg(app, cfg, color)
	}
}

fn draw_preview_of_blueprint_being_placed(app data.App) {
	if app.bench.bench_state != .placing_blueprint {
		return
	}

	// draw the preview using the components static draw function
	for cfg in app.bench.blueprints.current_blueprint_cfgs {
		color := rl.Color{
			...cfg.as_interface().get_color()
			a: 150
		}

		draw_component_from_cfg(app, cfg, color)
	}
}

fn draw_component_from_cfg(app data.App, cfg data.ComponentCfg, color rl.Color) {
	// figure out where to draw this preview of a component
	mouse_pos_world_space := data.screenspace_to_worldspace(app, app.input.mouse_pos)
	comp_pos_screen_space := data.worldspace_to_screenspace(app, utils.roundificate_to_whole_point(mouse_pos_world_space))

	// prepare the variables needed for drawing any components
	pos := vec.vec2(f32(comp_pos_screen_space.x), f32(comp_pos_screen_space.y))
	zoomed_unit := data.one_simspace_unit_in_px * app.view.zoom

	match cfg {
		data.SwitchCfg {
			offset := utils.vi_to_vf(cfg.pos).mul_scalar(zoomed_unit)
			components.Switch.draw(pos.add(offset), zoomed_unit, color, cfg.state, data.Rotation.from_int(cfg.rot))
		}
		data.FixedContactCfg {
			offset := utils.vi_to_vf(cfg.pos).mul_scalar(zoomed_unit)
			components.FixedContact.draw(app, pos.add(offset), zoomed_unit, color, cfg.state,
				data.Rotation.from_int(cfg.rot))
		}
		data.ClockCfg {
			offset := utils.vi_to_vf(cfg.pos).mul_scalar(zoomed_unit)
			components.Clock.draw(pos.add(offset), zoomed_unit, color, 0, cfg.ticks_max,
				data.Rotation.from_int(cfg.rot))
		}
		data.LEDCfg {
			offset := utils.vi_to_vf(cfg.pos).mul_scalar(zoomed_unit)
			components.LED.draw(pos.add(offset), zoomed_unit, color, false, data.Rotation.from_int(cfg.rot))
		}
		data.ChipCfg {
			offset := utils.vi_to_vf(cfg.pos).mul_scalar(zoomed_unit)
			components.Chip.draw(app, pos.add(offset), zoomed_unit, color, data.Rotation.from_int(cfg.rot),
				cfg.chip_uid, []data.ContactPoint{})
		}
		data.WireCfg {
			wire_from := utils.vi_to_vf(cfg.wire_from).mul_scalar(zoomed_unit)
			wire_to := utils.vi_to_vf(cfg.wire_to).mul_scalar(zoomed_unit)
			components.Wire.draw(utils.vf_to_vi(wire_from.add(pos)), utils.vf_to_vi(wire_to.add(pos)),
				app.view.zoom, .low, color)
		}
		data.BusCfg {
			wire_from := utils.vi_to_vf(cfg.wire_from).mul_scalar(zoomed_unit)
			wire_to := utils.vi_to_vf(cfg.wire_to).mul_scalar(zoomed_unit)
			components.Bus.draw(utils.vf_to_vi(wire_from.add(pos)), utils.vf_to_vi(wire_to.add(pos)),
				app.view.zoom, color)
		}
	}
}

fn draw_contact_points(app data.App) {
	if !app.view.debug.show_contacts {
		return
	}

	for point_key in app.sim.contact_point_positions.keys() {
		pos := utils.str_to_vec(point_key)
		screen_pos := data.worldspace_to_screenspace(app, pos)
		rl.draw_circle(screen_pos.x, screen_pos.y, 5, data.aabb_color)
	}
}
