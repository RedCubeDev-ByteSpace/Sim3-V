module simview

import data
import math
import utils

pub fn draw_grid(app data.App) {
	zoom := app.view.zoom
	zoomed_grid_spacing := data.one_simspace_unit_in_px * zoom
	camera_pos := app.view.camera_position.mul_scalar(data.one_simspace_unit_in_px * app.view.zoom).add(app.view.camera_offset)

	window_size := app.gg.window_size()

	// how many vertical grid lines can we fit?
	num_vertical_lines := int(window_size.width / zoomed_grid_spacing) + 2
	x_offset := math.fmod(camera_pos.x, zoomed_grid_spacing)

	// how many horizontal grid lines can we fit?
	num_horizontal_lines := int(window_size.height / zoomed_grid_spacing) + 2
	y_offset := math.fmod(camera_pos.y, zoomed_grid_spacing)

	// draw a grid of dots
	for ix in 0 .. num_vertical_lines {
		x := f32(ix * zoomed_grid_spacing + x_offset)

		for iy in 0 .. num_horizontal_lines {
			y := f32(iy * zoomed_grid_spacing + y_offset)

			app.gg.draw_pixel(x, y, data.grid_color)
		}
	}
}
