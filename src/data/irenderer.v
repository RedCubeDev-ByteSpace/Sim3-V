module data

import raylib as rl
import chip_catalog
import math.vec

// IRenderer
// a common interface for drawing components to... whatever

pub interface IRenderer {
mut:
	draw_component_rectangle(init_x_f f32, init_y_f f32, unit f32, x f32, y f32, width f32, height f32, rot Rotation, color rl.Color)
	draw_contact_line(init_x_f f32, init_y_f f32, unit f32, from_x f32, from_y f32, to_x f32, to_y f32, rot Rotation, color rl.Color)
	draw_line(init_x_f f32, init_y_f f32, unit f32, from_x f32, from_y f32, to_x f32, to_y f32, thick f32, rot Rotation, color rl.Color)
	draw_direct_line(line_from vec.Vec2[int], line_to vec.Vec2[int], thickness f32, color rl.Color)
	draw_circle_filled(init_x_f f32, init_y_f f32, unit f32, x f32, y f32, radius f32, rot Rotation, color rl.Color)
	draw_circle_lines(init_x_f f32, init_y_f f32, unit f32, x f32, y f32, radius f32, rot Rotation, color rl.Color)
	draw_centered_text(init_x_f f32, init_y_f f32, unit f32, x f32, y f32, text string, font_size f32, font rl.Font, rot Rotation, color rl.Color)
	draw_centered_text_rotated(init_x_f f32, init_y_f f32, unit f32, x f32, y f32, text string, font_size f32, font rl.Font, rot Rotation, color rl.Color) rl.Rectangle
	draw_chip_pin(init_x_f f32, init_y_f f32, unit f32, x f32, y f32, contact_point ContactPoint, pin chip_catalog.PinEntry, dir_left bool, rot Rotation, color rl.Color)
	draw_rotated_triangle(x f32, y f32, size f32, rot Rotation, line_color rl.Color, fill_color rl.Color)
}
