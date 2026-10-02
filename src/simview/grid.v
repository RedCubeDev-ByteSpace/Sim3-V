module simview

import raylib as rl
import data
import math
import utils
import math.vec

pub fn draw_grid(app data.App) {
	zoom := app.view.zoom

	if zoom < 0.4 {
		return
	}

	zoomed_grid_spacing := data.one_simspace_unit_in_px * zoom
	camera_pos := app.view.camera_position.mul_scalar(data.one_simspace_unit_in_px * app.view.zoom).add(app.view.camera_offset)

	window_width := rl.get_screen_width()
	window_height := rl.get_screen_height()

	// how many vertical grid lines can we fit?
	num_vertical_lines := int(window_width / zoomed_grid_spacing) + 2
	x_offset := math.fmod(camera_pos.x, zoomed_grid_spacing)

	// how many horizontal grid lines can we fit?
	num_horizontal_lines := int(window_height / zoomed_grid_spacing) + 2
	y_offset := math.fmod(camera_pos.y, zoomed_grid_spacing)

	// calculate a color for the grid based on the zoom level
	grid_color := rl.Color{
		...data.grid_color
		// when zoomed in: keep the alpha of 180
		// when zoomed out: reduce the alpha based on the zoom
		a: u8(128 * if zoom > 1 { 1 } else { zoom })
	}

	// calculate a color for the grids movement trails based on the zoom level
	zoom_percentage := math.log(app.view.zoom) / math.log(12)
	grid_trail_color := rl.Color{
		...data.grid_color
		a: u8(150 * zoom_percentage)
	}

	// draw a grid of dots
	for ix in 0 .. num_vertical_lines {
		x := f32(ix * zoomed_grid_spacing + x_offset)

		for iy in 0 .. num_horizontal_lines {
			y := f32(iy * zoomed_grid_spacing + y_offset)

			rl.draw_pixel(int(x), int(y), grid_color)

			// if we're zoomed in and grid movement trails are enabled
			// -> draw them!
			if zoom > 1 && app.view.grid.draw_grid_movement_trails {
				pixel_pos_in_world_space := data.screenspace_to_worldspace(app, vec.vec2(x,
					y))
				pixel_pos_in_prev_screen_space := data.worldspace_to_previous_screenspace(app,
					pixel_pos_in_world_space)

				// draw a line between this grid points position in this frame and where it would have been in the last
				// frame
				rl.draw_line(int(x), int(y), int(pixel_pos_in_prev_screen_space.x), int(pixel_pos_in_prev_screen_space.y),
					grid_trail_color)
			}
		}
	}
}
