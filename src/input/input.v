module input

import gg
import data
import math.vec
import utils
import math

pub fn handle_input(evt gg.Event, mut app data.App) {
	// first: share our current cursor position with microui and check if it wants to capture our input
	app.mu.update_mouse_position(evt)
	if app.mu.wants_input_capture() && app.bench.bench_state != .moving_view
		&& app.bench.bench_state != .selecting {
		// if so: pass anything and everything else on to microui
		app.mu.handle_input_event(evt)
		return
	}

	// otherwise: treat it as input for the simview

	if evt.typ == .mouse_move {
		app.input.mouse_pos = vec.vec2[f32](evt.mouse_x, evt.mouse_y)
	}

	// first: is this event something about the movement of the view?
	if handle_simview_movement(evt, mut app) {
		return
	}

	// second: is this movement a zoom in or out?
	if handle_simview_zoom(evt, mut app) {
		return
	}

	// third: are we trying to move something?
	if handle_component_move(evt, mut app) {
		return
	}

	// fourth: are we trying to select something?
	if handle_rectangle_select(evt, mut app) {
		return
	}
}

fn handle_simview_movement(evt gg.Event, mut app data.App) bool {
	// when we're not already moving the view and the user pressed their right mouse button
	// -> start a new view movement
	if app.bench.bench_state == .idle && evt.typ == .mouse_down && evt.mouse_button == .right {
		// set the view movement flag and remember where the move started
		app.bench.bench_state = .moving_view
		app.input.view_moving_start_pos = vec.Vec2[f32]{
			x: evt.mouse_x
			y: evt.mouse_y
		}

		// dont process any input after this
		return true
	}

	// alternatively:
	// if we're already moving the view...
	if app.bench.bench_state == .moving_view {
		// ... and theres a mouse movement -> recalculate the view offset
		if evt.typ == .mouse_move {
			// remember the last offset for drawing grid movement trails
			app.view.grid.draw_grid_movement_trails = true
			app.view.grid.prev_camera_offset = app.view.camera_offset

			// update the camera offset
			app.view.camera_offset = vec.Vec2[f32]{
				x: evt.mouse_x - app.input.view_moving_start_pos.x
				y: evt.mouse_y - app.input.view_moving_start_pos.y
			}

			// dont process any input after this
			return true
		}

		// ... and the user has stopped pressing the button -> apply the offset onto the actual camera position
		if evt.typ == .mouse_up && evt.mouse_button == .right {
			app.view.camera_position = app.view.camera_position.add(app.view.camera_offset.div_scalar[f32](app.view.zoom * data.one_simspace_unit_in_px))
			app.view.camera_offset.zero()

			app.bench.bench_state = .idle

			// stop any grid movement trails
			app.view.grid.draw_grid_movement_trails = false
			app.view.grid.prev_camera_offset = app.view.camera_offset
			app.view.grid.prev_camera_position = app.view.camera_position

			// dont process any input after this
			return true
		}
	}

	return false
}

fn handle_simview_zoom(evt gg.Event, mut app data.App) bool {
	// make sure this is a scroll event
	if evt.typ != .mouse_scroll {
		return false
	}

	if evt.scroll_y > 0 {
		new_zoom := app.input.target_zoom * 1.5
		if new_zoom < data.max_zoom {
			app.input.target_zoom = new_zoom
		}
	} else {
		if app.input.target_zoom > data.min_zoom {
			app.input.target_zoom /= 1.5
		}
	}

	return true
}

pub fn sync_zoom(mut app data.App) {
	if app.view.zoom == app.input.target_zoom {
		// nothing to do!
		return
	}

	// remember the previous zoom and camera position for grid movement trails
	app.view.grid.draw_grid_movement_trails = true
	app.view.grid.prev_camera_position = app.view.camera_position
	app.view.grid.prev_zoom = app.view.zoom

	// otherwise: lerp the zoom towards the target
	mouse_pos_in_world_space_before_zoom := utils.screenspace_to_worldspace(app, app.input.mouse_pos)

	app.view.zoom = utils.lerp(app.view.zoom, app.input.target_zoom, 0.2)

	// are we close enough to the real value?
	if math.abs(app.view.zoom - app.input.target_zoom) <= data.zoom_lerp_cutoff {
		// stop lerping -> just jump to the real value
		app.view.zoom = app.input.target_zoom
	}

	// are we close enough to the real value to stop grid movement trails?
	// (because it looks weird if they go on for too long)
	if app.view.grid.draw_grid_movement_trails
		&& math.abs(app.view.zoom - app.input.target_zoom) <= data.zoom_trail_cutoff {
		// stop any movement tails
		app.view.grid.draw_grid_movement_trails = false
	}

	mouse_pos_in_world_space_after_zoom := utils.screenspace_to_worldspace(app, app.input.mouse_pos)

	// adjust the camera position to zoom into where the cursor is positioned
	app.view.camera_position = app.view.camera_position.add(mouse_pos_in_world_space_after_zoom.sub(mouse_pos_in_world_space_before_zoom))
}

fn handle_component_move(evt gg.Event, mut app data.App) bool {
	// is the bench current unused, this is a mouse down AND we're currently hovering a selected component?
	// -> begin selection
	if app.bench.bench_state == .idle && evt.typ == .mouse_down && evt.mouse_button == .left {
		mouse_pos_in_world_space := utils.screenspace_to_worldspace(app, app.input.mouse_pos)
		for comp in app.bench.selected_components {
			if !utils.is_point_inside_aabb(comp.get_aabb(), mouse_pos_in_world_space) {
				continue
			}

			// remember the starting point of the move
			app.input.component_move_start_pos = mouse_pos_in_world_space
			app.bench.bench_state = .moving_components

			return true
		}
	}

	// if we're current in a move -> recalculate all component's offsets
	if app.bench.bench_state == .moving_components && evt.typ == .mouse_move {
		mouse_pos_in_world_space := utils.screenspace_to_worldspace(app, app.input.mouse_pos)
		new_offset := mouse_pos_in_world_space.sub(app.input.component_move_start_pos)

		for mut comp in app.bench.selected_components {
			comp.set_offset(vec.vec2[int](int(new_offset.x), int(new_offset.y)))
		}

		return true
	}

	// if we're currently moving and theres a mouse up -> end and commit movement
	if app.bench.bench_state == .moving_components && evt.typ == .mouse_up
		&& evt.mouse_button == .left {
		for mut comp in app.bench.selected_components {
			// add the offest onto the position and reset it
			comp.set_position(comp.get_position().add(comp.get_offset()))
			comp.set_offset(vec.vec2[int](0, 0))
		}

		app.bench.bench_state = .idle
		return true
	}

	return false
}

fn handle_rectangle_select(evt gg.Event, mut app data.App) bool {
	// is the bench current unused and this is a mouse down?
	// -> begin selection
	if app.bench.bench_state == .idle && evt.typ == .mouse_down && evt.mouse_button == .left {
		app.bench.bench_state = .selecting
		app.input.selecting_start_pos = app.input.mouse_pos

		return true
	}

	// if we're currently selecting and theres a mouse up -> end selecting
	if app.bench.bench_state == .selecting && evt.typ == .mouse_up && evt.mouse_button == .left {
		// clear the selection list
		app.bench.selected_components = []

		// add all components inside the selected area
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

		start_pos_world_space := utils.screenspace_to_worldspace(app, vec.vec2[f32](x1,
			y1))
		end_pos_world_space := utils.screenspace_to_worldspace(app, vec.vec2[f32](x2,
			y2))

		selection_aabb := data.AABB{
			x:      start_pos_world_space.x
			y:      start_pos_world_space.y
			width:  end_pos_world_space.x - start_pos_world_space.x
			height: end_pos_world_space.y - start_pos_world_space.y
		}

		for comp in app.sim.components {
			if utils.is_aabb_inside_aabb(selection_aabb, comp.get_aabb()) {
				app.bench.selected_components << comp
			}
		}

		app.bench.bench_state = .idle
		return true
	}

	return false
}
