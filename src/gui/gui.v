module gui

import gg
import data
import math

pub fn draw_ui(mut app data.App) {
	app.mu.begin()

	draw_debug_panel(mut app)

	app.mu.end()
	app.mu.render()
}

fn draw_debug_panel(mut app data.App) {
	if app.mu.begin_window_ex('Debug Window', gg.Rect{10, 10, 200, 135}, .noclose) {
		app.mu.layout_row([-1], 0)

		camera_pos := app.view.camera_position.add(app.view.camera_offset.div_scalar(app.view.zoom * data.one_simspace_unit_in_px))
		app.mu.label('MUi Input Capture: ${if app.mu.wants_input_capture() { 'yes' } else { 'no' }}')
		app.mu.label('Camera: ${camera_pos.x:.2f}, ${camera_pos.y:.2f}')
		app.mu.label('Mouse: ${app.input.mouse_pos.x:.0}, ${app.input.mouse_pos.y:.0}')
		app.mu.label('Zoom: ${app.view.zoom}')
		app.mu.label('Zoom%: ${if app.view.zoom >= 1 {
			math.log(app.view.zoom) / math.log(12)
		} else {
			0
		}:.2}')

		app.mu.layout_row([-1], 2)
		app.mu.layout_next()
		app.mu.layout_row([1, -1], 0)
		app.mu.layout_next()
		app.mu.checkbox('Draw AABBs', app.view.debug.show_aabb)

		app.mu.end_window()
	}

	// keep the window on the top right of the screen
	window_size := app.gg.window_size()
	mut debug_window_rect := app.mu.get_container_rect('Debug Window')
	debug_window_rect.x = window_size.width - debug_window_rect.width - 10
	debug_window_rect.y = 10
	app.mu.set_container_rect('Debug Window', debug_window_rect)
}
