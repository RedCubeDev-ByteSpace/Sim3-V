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
	if app.mu.begin_window_ex('Debug Window', gg.Rect{10, 10, 200, 100}, .noclose) {
		app.mu.layout_row([-1], 0)

		camera_pos := app.view.camera_position.add(app.view.camera_offset.div_scalar(app.view.zoom * data.one_simspace_unit_in_px))
		app.mu.label('Camera: ${camera_pos.x:.2f}, ${camera_pos.y:.2f}')
		app.mu.label('Mouse: ${app.input.mouse_pos.x:.0}, ${app.input.mouse_pos.y:.0}')
		app.mu.label('Zoom: ${app.view.zoom}')
		app.mu.label('Zoom%: ${if app.view.zoom >= 1 {
			math.log(app.view.zoom) / math.log(12)
		} else {
			0
		}:.2}')

		app.mu.end_window()
	}
}
