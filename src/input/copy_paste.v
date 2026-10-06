module input

import raylib as rl
import cfg_utils
import data

fn handle_copy_paste(mut app data.App) bool {
	// did the user press ctrl + c?
	if rl.is_key_pressed(int(rl.KeyboardKey.key_c))
		&& (rl.is_key_down(int(rl.KeyboardKey.key_left_control))
		|| rl.is_key_down(int(rl.KeyboardKey.key_right_control))) {
		// is there anything selected?
		if app.bench.selected_components.len == 0 {
			return false // nope -> keep the clipboard as is
		}

		// otherwise:
		// clear the current clip board
		app.bench.clipboard.current_clip_board.clear()

		// get the cfgs of all currently selected components and store them in the clipboard
		for comp in app.bench.selected_components {
			app.bench.clipboard.current_clip_board << comp.get_cfg()
		}

		cfg_utils.normalize_cfgs(mut app.bench.clipboard.current_clip_board)

		return true
	}

	// did the user press ctrl + v?
	if app.bench.bench_state == .idle && rl.is_key_pressed(int(rl.KeyboardKey.key_v))
		&& (rl.is_key_down(int(rl.KeyboardKey.key_left_control))
		|| rl.is_key_down(int(rl.KeyboardKey.key_right_control))) {
		// is there anything in the clipboard?
		if app.bench.clipboard.current_clip_board.len == 0 {
			return false
		}

		// clear any selections
		app.bench.selected_components.clear()

		// draw the preview and let the user place the components
		app.bench.bench_state = .pasting_components

		return true
	}

	if app.bench.bench_state == .pasting_components {
		// if ESC is pressed while pasting -> exit the paste mode
		if rl.is_key_pressed(int(rl.KeyboardKey.key_escape)) {
			app.bench.bench_state = .idle
			return true
		}

		// if R is pressed while placing -> rotate the components
		if rl.is_key_pressed(int(rl.KeyboardKey.key_q)) {
			cfg_utils.rotate_cfgs(mut app.bench.clipboard.current_clip_board)
			return true
		}

		// if the left mouse button was clicked -> paste!
		if rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_left)) {
			cfg_utils.place_components_from_cfg(mut app, mut app.bench.clipboard.current_clip_board)
			app.bench.bench_state = .idle
			return true
		}
	}

	return false
}
