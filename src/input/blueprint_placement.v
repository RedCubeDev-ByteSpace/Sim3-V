module input

import raylib as rl
import cfg_utils
import data

fn handle_blueprint_placement(mut app data.App) bool {
	if app.bench.bench_state != .placing_blueprint {
		return false
	}

	// if ESC is pressed while pasting -> exit the paste mode
	if rl.is_key_pressed(int(rl.KeyboardKey.key_escape)) {
		app.bench.bench_state = .idle
		return true
	}

	// if R is pressed while placing -> rotate the components
	if rl.is_key_pressed(int(rl.KeyboardKey.key_q)) {
		cfg_utils.rotate_cfgs(mut app.bench.blueprints.current_blueprint_cfgs)
		return true
	}

	// if the left mouse button was clicked -> paste!
	if rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_left)) {
		cfg_utils.place_components_from_cfg(mut app, mut app.bench.blueprints.current_blueprint_cfgs)
		app.bench.bench_state = .idle
		return true
	}

	return false
}
