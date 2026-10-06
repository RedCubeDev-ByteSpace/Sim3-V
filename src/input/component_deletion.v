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
		for mut comp in app.bench.selected_components {
			comp.on_delete(mut app)

			// look this component up in the main list and delete it
			for i, lookup in app.sim.components {
				if lookup.get_comp_id() == comp.get_comp_id() {
					app.sim.components.delete(i)
					break
				}
			}
		}
		app.bench.selected_components.clear()
		return true
	}

	return false
}
