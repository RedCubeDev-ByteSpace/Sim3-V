module renderers

import raylib as rl
import data
import chip_catalog
import utils
import math.vec

pub struct RaylibDirectRenderer {}

pub fn (mut r RaylibDirectRenderer) draw_component_rectangle(init_x_f f32, init_y_f f32, unit f32, x f32, y f32, width f32, height f32, rot data.Rotation, color rl.Color) {
	rect := get_component_rectangle_variables(init_x_f, init_y_f, unit, x, y, width, height,
		rot)
	rl.draw_rectangle_lines_ex(rect, data.component_line_thickness, color)
}

pub fn (mut r RaylibDirectRenderer) draw_contact_line(init_x_f f32, init_y_f f32, unit f32, from_x f32, from_y f32, to_x f32, to_y f32, rot data.Rotation, color rl.Color) {
	draw_from_x, draw_from_y, draw_to_x, draw_to_y := get_contact_line_variables(init_x_f,
		init_y_f, unit, from_x, from_y, to_x, to_y, rot)
	rl.draw_line(draw_from_x, draw_from_y, draw_to_x, draw_to_y, color)
}

pub fn (mut r RaylibDirectRenderer) draw_line(init_x_f f32, init_y_f f32, unit f32, from_x f32, from_y f32, to_x f32, to_y f32, thick f32, rot data.Rotation, color rl.Color) {
	draw_from_x, draw_from_y, draw_to_x, draw_to_y, sized_thick := get_line_variables(init_x_f,
		init_y_f, unit, from_x, from_y, to_x, to_y, thick, rot)
	rl.draw_line_ex(rl.Vector2{draw_from_x, draw_from_y}, rl.Vector2{draw_to_x, draw_to_y},
		sized_thick, color)
}

pub fn (mut r RaylibDirectRenderer) draw_direct_line(line_from vec.Vec2[int], line_to vec.Vec2[int], thickness f32, color rl.Color) {
	if thickness == 0 {
		rl.draw_line(line_from.x, line_from.y, line_to.x, line_to.y, color)
	} else {
		rl.draw_line_ex(utils.vi_to_vrl(line_from), utils.vi_to_vrl(line_to), thickness,
			color)
	}
}

pub fn (mut r RaylibDirectRenderer) draw_circle_filled(init_x_f f32, init_y_f f32, unit f32, x f32, y f32, radius f32, rot data.Rotation, color rl.Color) {
	draw_x, draw_y, sized_radius := get_circle_filled_variables(init_x_f, init_y_f, unit,
		x, y, radius, rot)
	rl.draw_circle(draw_x, draw_y, sized_radius, color)
}

pub fn (mut r RaylibDirectRenderer) draw_circle_lines(init_x_f f32, init_y_f f32, unit f32, x f32, y f32, radius f32, rot data.Rotation, color rl.Color) {
	draw_x, draw_y, sized_radius := get_circle_lines_variables(init_x_f, init_y_f, unit,
		x, y, radius, rot)
	rl.draw_circle_lines(draw_x, draw_y, sized_radius, color)
}

pub fn (mut r RaylibDirectRenderer) draw_centered_text(init_x_f f32, init_y_f f32, unit f32, x f32, y f32, text string, font_size f32, font rl.Font, rot data.Rotation, color rl.Color) {
	text_x, text_y := get_centered_text_variables(init_x_f, init_y_f, unit, x, y, rot)
	text_size := rl.measure_text_ex(font, text, font_size, 1)

	rl.draw_text_ex(font, text, rl.Vector2{
		x: text_x - (text_size.x / 2)
		y: text_y - (text_size.y / 2)
	}, font_size, 1, color)
}

pub fn (mut r RaylibDirectRenderer) draw_centered_text_rotated(init_x_f f32, init_y_f f32, unit f32, x f32, y f32, text string, font_size f32, font rl.Font, rot data.Rotation, color rl.Color) rl.Rectangle {
	draw_x, draw_y, rot_angle := get_centered_text_rotated_variables(init_x_f, init_y_f,
		unit, x, y, rot)
	text_size := rl.measure_text_ex(font, text, font_size, 1)

	rl.draw_text_pro(font, text, rl.Vector2{
		x: draw_x
		y: draw_y
	}, rl.Vector2{
		x: text_size.x / 2
		y: text_size.y / 2
	}, rot_angle, font_size, 1, color)

	return rl.Rectangle{
		x:      x
		y:      y
		width:  text_size.x / unit
		height: text_size.y / unit
	}
}

pub fn (mut r RaylibDirectRenderer) draw_chip_pin(init_x_f f32, init_y_f f32, unit f32, x f32, y f32, contact_point data.ContactPoint, pin chip_catalog.PinEntry, dir_left bool, rot data.Rotation, color rl.Color) {
	draw_x, draw_y, draw_rot, inverted_draw_rot := get_chip_pin_variables(init_x_f, init_y_f,
		unit, x, y, dir_left, rot)
	// what kind of pin is this?

	// power pins are just filled circles
	if pin.is_power {
		rl.draw_circle(draw_x, draw_y, data.contact_point_size * unit, color)
		return
	}

	// clock pins are empty circles
	if pin.is_clock {
		rl.draw_circle_lines(draw_x, draw_y, data.contact_point_size * unit, color)
		return
	}

	// floating pins are inputs
	if contact_point.output_state == .floating {
		r.draw_rotated_triangle(draw_x, draw_y, data.contact_point_size * unit, draw_rot,
			color, if contact_point.input_state == .high { color } else { rl.raywhite })
		return
	}

	// otherwise -> output
	r.draw_rotated_triangle(draw_x, draw_y, data.contact_point_size * unit, inverted_draw_rot,
		color, if contact_point.output_state == .high { color } else { rl.raywhite })
}

fn (mut r RaylibDirectRenderer) draw_rotated_triangle(x f32, y f32, size f32, rot data.Rotation, line_color rl.Color, fill_color rl.Color) {
	v1, v2, v3 := get_rotated_triangle_variables(x, y, size, rot)

	v1_rl, v2_rl, v3_rl := utils.vf_to_vrl(v1), utils.vf_to_vrl(v2), utils.vf_to_vrl(v3)

	rl.draw_triangle(v1_rl, v2_rl, v3_rl, fill_color)
	rl.draw_triangle_lines(v1_rl, v2_rl, v3_rl, line_color)
}
