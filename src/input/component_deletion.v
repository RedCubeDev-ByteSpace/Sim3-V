module input

import raylib as rl
import data

fn handle_component_deletion(mut app data.App) bool {
	if app.bench.selected_components.len == 0 {
		return false
	}

	// allow both DEL and Backspace for deleting components
	if rl.is_key_pressed(int(rl.KeyboardKey.key_delete))
		|| rl.is_key_pressed(int(rl.KeyboardKey.key_backspace)) {
		for mut comp_handle in app.bench.selected_components {
			mut comp := app.sim.components.get(comp_handle)
			comp.on_delete(mut app)
			app.sim.components.remove(comp_handle)
		}
		app.bench.selected_components.clear()
		return true
	}

	return false
}
