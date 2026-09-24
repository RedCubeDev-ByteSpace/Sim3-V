module simview

import data
import gg
import math
import utils

pub fn draw_grid(app data.App) {
	zoom := app.view.zoom
	zoomed_grid_spacing := data.one_simspace_unit_in_px * zoom
	camera_pos := utils.worldspace_to_screenspace(app, app.view.camera_position)

	window_size := app.gg.window_size()

	// draw all vertical grid lines
	num_vertical_lines := int(window_size.width / zoomed_grid_spacing) + 2
	x_offset := math.fmod(camera_pos.x, zoomed_grid_spacing)

	for ix in 0 .. num_vertical_lines {
		x := ix * zoomed_grid_spacing + x_offset
		app.gg.draw_line(int(x), 0, int(x), window_size.height, grid_color)
	}

	// draw all horizontal grid lines
	num_horizontal_lines := int(window_size.height / zoomed_grid_spacing) + 2
	y_offset := math.fmod(camera_pos.y, zoomed_grid_spacing)

	for iy in 0 .. num_horizontal_lines {
		y := iy * zoomed_grid_spacing + y_offset
		app.gg.draw_line(0, int(y), window_size.width, int(y), grid_color)
	}
}
