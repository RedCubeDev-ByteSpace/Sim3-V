module input

import raylib as rl
import data
import math.vec
import imgui

pub fn handle_input(mut app data.App) {
	// first: is imgui capturing input right now?
	// -> if so, ignore it
	io := imgui.get_io_nil()
	if io.WantCaptureMouse || io.WantCaptureKeyboard {
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
