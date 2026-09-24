module input

import gg
import data
import math.vec
import utils

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

	mouse_pos_in_world_space_before_zoom := utils.screenspace_to_worldspace(app, app.input.mouse_pos)
	if evt.scroll_y > 0 {
		app.view.zoom *= 1.01
	} else {
		app.view.zoom *= 0.99
	}
	mouse_pos_in_world_space_after_zoom := utils.screenspace_to_worldspace(app, app.input.mouse_pos)

	// adjust the camera position to zoom into where the cursor is positioned
	app.view.camera_position = app.view.camera_position.add(mouse_pos_in_world_space_after_zoom.sub(mouse_pos_in_world_space_before_zoom))

	return true
}
