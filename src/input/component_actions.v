module input

import raylib as rl
import data

fn handle_component_interaction(mut app data.App) bool {
	// is the workbench currently unused and theres been a mouse click...
	if app.bench.bench_state == .idle
		&& rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_left)) {
		// ... check if we've clicked on a component
		mouse_pos_in_world_space := data.screenspace_to_worldspace(app, app.input.mouse_pos)
		for mut comp in app.sim.components.values() {
			if !comp.has_interaction() {
				continue
			}

			// if yes AND component is not currectly selected -> interact
			if comp.hit_test(mouse_pos_in_world_space) && comp !in app.bench.selected_components {
				comp.interact()
				return true
			}
		}
	}

	// is the workbench currently unused and theres been a RIGHT mouse click...
	if app.bench.bench_state == .idle
		&& rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_right)) {
		// ... check if we've clicked on a component
		mouse_pos_in_world_space := data.screenspace_to_worldspace(app, app.input.mouse_pos)
		for mut comp in app.sim.components.values() {
			// if yes AND component is not currectly selected -> open component window
			if comp.hit_test(mouse_pos_in_world_space) && comp !in app.bench.selected_components {
				comp.open_component_window()
				return true
			}
		}
	}

	return false
}
