module input

import raylib as rl
import data
import math.vec

fn handle_rectangle_select(mut app data.App) bool {
	// is the bench current unused and this is a mouse down?
	// -> begin selection
	if app.bench.bench_state == .idle
		&& rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_left)) {
		app.bench.bench_state = .selecting
		app.input.selecting_start_pos = app.input.mouse_pos

		return true
	}

	// if we're currently selecting and theres a mouse up -> end selecting
	if app.bench.bench_state == .selecting
		&& rl.is_mouse_button_released(int(rl.MouseButton.mouse_button_left)) {
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

		start_pos_world_space := data.screenspace_to_worldspace(app, vec.vec2[f32](x1,
			y1))
		end_pos_world_space := data.screenspace_to_worldspace(app, vec.vec2[f32](x2, y2))

		selection_aabb := data.AABB{
			x:      start_pos_world_space.x
			y:      start_pos_world_space.y
			width:  end_pos_world_space.x - start_pos_world_space.x
			height: end_pos_world_space.y - start_pos_world_space.y
		}

		for comp in app.sim.components.values() {
			if data.do_aabbs_intersect(selection_aabb, comp.get_aabb()) {
				app.bench.selected_components << comp
			}
		}

		app.bench.bench_state = .idle
		return true
	}

	return false
}
