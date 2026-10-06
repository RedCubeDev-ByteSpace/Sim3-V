module input

import raylib as rl
import data
import math
import math.vec
import utils

fn handle_simview_movement(mut app data.App) bool {
	// when we're not already moving the view and the user pressed their right mouse button
	// -> start a new view movement
	if (app.bench.bench_state == .idle || app.bench.bench_state == .placing_component
		|| app.bench.bench_state == .pasting_components)
		&& (rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_right))
		|| rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_middle))) {
		// remember the current state so we can return to it later
		app.bench.return_after_move_bench_state = app.bench.bench_state

		// set the view movement flag and remember where the move started
		app.bench.bench_state = .moving_view
		app.input.view_moving_start_pos = app.input.mouse_pos

		// dont process any input after this
		return true
	}

	// alternatively:
	// if we're already moving the view...
	if app.bench.bench_state == .moving_view {
		// ... and theres a mouse movement -> recalculate the view offset
		// remember the last offset for drawing grid movement trails
		app.view.grid.draw_grid_movement_trails = true
		app.view.grid.prev_camera_offset = app.view.camera_offset

		// update the camera offset
		app.view.camera_offset = vec.Vec2[f32]{
			x: app.input.mouse_pos.x - app.input.view_moving_start_pos.x
			y: app.input.mouse_pos.y - app.input.view_moving_start_pos.y
		}

		// ... and the user has stopped pressing the button -> apply the offset onto the actual camera position
		if rl.is_mouse_button_released(int(rl.MouseButton.mouse_button_right))
			|| rl.is_mouse_button_released(int(rl.MouseButton.mouse_button_middle)) {
			app.view.camera_position = app.view.camera_position.add(app.view.camera_offset.div_scalar[f32](app.view.zoom * data.one_simspace_unit_in_px))
			app.view.camera_offset.zero()

			app.bench.bench_state = app.bench.return_after_move_bench_state

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

fn handle_simview_zoom(mut app data.App) bool {
	scroll := rl.get_mouse_wheel_move_v().y
	if scroll == 0 {
		return false
	}

	if scroll > 0 {
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
	mouse_pos_in_world_space_before_zoom := data.screenspace_to_worldspace(app, app.input.mouse_pos)

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

	mouse_pos_in_world_space_after_zoom := data.screenspace_to_worldspace(app, app.input.mouse_pos)

	// adjust the camera position to zoom into where the cursor is positioned
	app.view.camera_position = app.view.camera_position.add(mouse_pos_in_world_space_after_zoom.sub(mouse_pos_in_world_space_before_zoom))
}
