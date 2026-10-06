module input

import raylib as rl
import data
import math.vec

pub fn handle_input(mut app data.App) {
	// first: share our current cursor position with microui and check if it wants to capture our input
	app.mu.update_mouse_position()
	if app.mu.wants_input_capture() && app.bench.bench_state != .moving_view
		&& app.bench.bench_state != .selecting {
		// if so: pass anything and everything else on to microui
		app.mu.handle_input_event()

		// important! keep track of if this was a mouse down
		// if so -> microui needs a mouse up after a mouse down but it wont always automatically be routed there because
		// if you close a window its input capture will immediately end without waiting for the release
		if rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_left)) {
			app.input.mui_needs_mouse_up = true
		}
		if rl.is_mouse_button_released(int(rl.MouseButton.mouse_button_left)) {
			app.input.mui_needs_mouse_up = false
		}

		return
	}

	if rl.is_mouse_button_released(int(rl.MouseButton.mouse_button_left))
		&& app.input.mui_needs_mouse_up {
		app.input.mui_needs_mouse_up = false
		app.mu.handle_input_event()
		return
	}

	// otherwise: treat it as input for the simview

	mouse_pos := rl.get_mouse_position()
	app.input.mouse_pos = vec.vec2[f32](mouse_pos.x, mouse_pos.y)

	// are we trying to place a component?
	if handle_component_placement(mut app) {
		return
	}

	// are we trying to copy or paste?
	if handle_copy_paste(mut app) {
		return
	}

	// are we trying to place down a blueprint?
	if handle_blueprint_placement(mut app) {
		return
	}

	// are we trying to interact with a component?
	if handle_component_interaction(mut app) {
		return
	}

	// is this event something about the movement of the view?
	if handle_simview_movement(mut app) {
		return
	}

	// is this movement a zoom in or out?
	if handle_simview_zoom(mut app) {
		return
	}

	// are we trying to delete selected components?
	if handle_component_deletion(mut app) {
		return
	}

	// are we trying to move something?
	if handle_component_move(mut app) {
		return
	}

	// are we trying to move part of a wire?
	if handle_wire_move(mut app) {
		return
	}

	// are we trying to move a wire?
	if handle_component_move(mut app) {
		return
	}

	// are we trying to select something?
	if handle_rectangle_select(mut app) {
		return
	}
}
