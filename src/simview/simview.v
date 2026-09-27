module simview

import data
import utils
import raylib as rl
import math.vec

// simview -------------------------------------------------------------------------------------------------------------
// this module is all about the drawing side of things
// it supplies all the objects that are drawable in the simulation space
// it also takes care of rendering those objects to the screen and drawing the background grid

pub fn draw_view(app data.App) {
	draw_grid(app)
	draw_selection(app)
	draw_components(app)
	draw_selected_component_outlines(app)
}

fn draw_components(app data.App) {
	// get the AABB for the current viewport
	view_aabb := utils.get_viewport_aabb(app)

	for comp in app.sim.components {
		// only draw components that are touching the current viewports aabb
		if utils.do_aabbs_intersect(view_aabb, comp.get_aabb()) {
			comp.draw(app)

			// if enabled: draw bounding boxes
			if app.view.debug.show_aabb {
				draw_aabb(app, comp.get_aabb(), data.aabb_color)
			}
		}
	}
}

fn draw_aabb(app data.App, aabb data.AABB, color rl.Color) {
	top_left := utils.worldspace_to_screenspace(app, vec.vec2[f32](aabb.x, aabb.y))
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
		top_left := utils.worldspace_to_screenspace(app, vec.vec2[f32](aabb.x, aabb.y))
		zoomed_unit := data.one_simspace_unit_in_px * app.view.zoom
		draw_marching_ants(app, rl.Rectangle{top_left.x, top_left.y, aabb.width * zoomed_unit, aabb.height * zoomed_unit},
			data.selection_color_low)
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
