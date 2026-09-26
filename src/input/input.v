module input

import gg
import data
import math.vec
import utils
import math

pub fn handle_input(evt gg.Event, mut app data.App) {
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

	// pass anything else on to microui
	app.mu.handle_input_event(evt)
}

pub fn handle_simview_movement(evt gg.Event, mut app data.App) bool {
	// when we're not already moving the view and the user pressed their right mouse button
	// -> start a new view movement
	if !app.input.is_moving_view && evt.typ == .mouse_down && evt.mouse_button == .right {
		// set the view movement flag and remember where the move started
		app.input.is_moving_view = true
		app.input.view_moving_start_pos = vec.Vec2[f32]{
			x: evt.mouse_x
			y: evt.mouse_y
		}

		// dont process any input after this
		return true
	}

	// alternatively:
	// if we're already moving the view...
	if app.input.is_moving_view {
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

			app.input.is_moving_view = false

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

pub fn handle_simview_zoom(evt gg.Event, mut app data.App) bool {
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
