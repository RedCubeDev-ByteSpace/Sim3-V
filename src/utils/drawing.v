module utils

import data
import raylib as rl
import fonts
import math.vec
import chip_catalog

pub fn draw_component_rectangle(init_x_f f32, init_y_f f32, unit f32, x f32, y f32, width f32, height f32, rot data.Rotation, color rl.Color) {
	init_x := int(init_x_f)
	init_y := int(init_y_f)

	sized_x := int(x * unit)
	sized_y := int(y * unit)
	sized_w := int(width * unit)
	sized_h := int(height * unit)

	mut rect := rl.Rectangle{}

	match rot {
		.up {
			rect = rl.Rectangle{
				x:      init_x + sized_x
				y:      init_y + sized_y
				width:  sized_w
				height: sized_h
			}
		}
		.down {
			rect = rl.Rectangle{
				x:      init_x - sized_x - sized_w
				y:      init_y - sized_y - sized_h
				width:  sized_w
				height: sized_h
			}
		}
		.right {
			rect = rl.Rectangle{
				x:      init_x - sized_y - sized_h
				y:      init_y + sized_x
				width:  sized_h
				height: sized_w
			}
		}
		.left {
			rect = rl.Rectangle{
				x:      init_x + sized_y
				y:      init_y - sized_x - sized_w
				width:  sized_h
				height: sized_w
			}
		}
	}

	rl.draw_rectangle_lines_ex(rect, data.component_line_thickness, color)
}

pub fn draw_contact_line(init_x_f f32, init_y_f f32, unit f32, from_x f32, from_y f32, to_x f32, to_y f32, rot data.Rotation, color rl.Color) {
	init_x := int(init_x_f)
	init_y := int(init_y_f)

	sized_from_x := int(from_x * unit)
	sized_from_y := int(from_y * unit)
	sized_to_x := int(to_x * unit)
	sized_to_y := int(to_y * unit)

	mut draw_from_x := 0
	mut draw_from_y := 0
	mut draw_to_x := 0
	mut draw_to_y := 0

	match rot {
		.up {
			draw_from_x = init_x + sized_from_x
			draw_from_y = init_y + sized_from_y
			draw_to_x = init_x + sized_to_x
			draw_to_y = init_y + sized_to_y
		}
		.down {
			draw_from_x = init_x - sized_from_x
			draw_from_y = init_y - sized_from_y
			draw_to_x = init_x - sized_to_x
			draw_to_y = init_y - sized_to_y
		}
		.right {
			draw_from_x = init_x - sized_from_y
			draw_from_y = init_y + sized_from_x
			draw_to_x = init_x - sized_to_y
			draw_to_y = init_y + sized_to_x
		}
		.left {
			draw_from_x = init_x + sized_from_y
			draw_from_y = init_y - sized_from_x
			draw_to_x = init_x + sized_to_y
			draw_to_y = init_y - sized_to_x
		}
	}

	rl.draw_line(draw_from_x, draw_from_y, draw_to_x, draw_to_y, color)
}

pub fn draw_circle_filled(init_x_f f32, init_y_f f32, unit f32, x f32, y f32, radius f32, rot data.Rotation, color rl.Color) {
	init_x := int(init_x_f)
	init_y := int(init_y_f)

	sized_x := int(x * unit)
	sized_y := int(y * unit)
	sized_radius := radius * unit

	mut draw_x := 0
	mut draw_y := 0

	match rot {
		.up {
			draw_x = init_x + sized_x
			draw_y = init_y + sized_y
		}
		.down {
			draw_x = init_x - sized_x
			draw_y = init_y - sized_y
		}
		.right {
			draw_x = init_x - sized_y
			draw_y = init_y + sized_x
		}
		.left {
			draw_x = init_x + sized_y
			draw_y = init_y - sized_x
		}
	}

	rl.draw_circle(draw_x, draw_y, sized_radius, color)
}

pub fn draw_circle_lines(init_x_f f32, init_y_f f32, unit f32, x f32, y f32, radius f32, rot data.Rotation, color rl.Color) {
	init_x := int(init_x_f)
	init_y := int(init_y_f)

	sized_x := int(x * unit)
	sized_y := int(y * unit)
	sized_radius := radius * unit

	mut draw_x := 0
	mut draw_y := 0

	match rot {
		.up {
			draw_x = init_x + sized_x
			draw_y = init_y + sized_y
		}
		.down {
			draw_x = init_x - sized_x
			draw_y = init_y - sized_y
		}
		.right {
			draw_x = init_x - sized_y
			draw_y = init_y + sized_x
		}
		.left {
			draw_x = init_x + sized_y
			draw_y = init_y - sized_x
		}
	}

	rl.draw_circle_lines(draw_x, draw_y, sized_radius, color)
}

pub fn draw_centered_text(app data.App, init_x_f f32, init_y_f f32, unit f32, x f32, y f32, text string, font_size f32, rot data.Rotation, color rl.Color) {
	init_x := int(init_x_f)
	init_y := int(init_y_f)

	sized_x := int(x * unit)
	sized_y := int(y * unit)

	mut draw_x := 0
	mut draw_y := 0

	match rot {
		.up {
			draw_x = init_x + sized_x
			draw_y = init_y + sized_y
		}
		.down {
			draw_x = init_x - sized_x
			draw_y = init_y - sized_y
		}
		.right {
			draw_x = init_x - sized_y
			draw_y = init_y + sized_x
		}
		.left {
			draw_x = init_x + sized_y
			draw_y = init_y - sized_x
		}
	}

	sized_font_size := int(font_size * unit)
	font := fonts.get_font_for_size(app, sized_font_size)
	text_size := rl.measure_text_ex(font, text, sized_font_size, 1)
	rl.draw_text_ex(font, text, rl.Vector2{
		x: draw_x - (text_size.x / 2)
		y: draw_y - (text_size.y / 2)
	}, sized_font_size, 1, color)
}

pub fn draw_centered_text_rotated(app data.App, init_x_f f32, init_y_f f32, unit f32, x f32, y f32, text string, font_size f32, rot data.Rotation, color rl.Color) rl.Rectangle {
	init_x := int(init_x_f)
	init_y := int(init_y_f)

	sized_x := int(x * unit)
	sized_y := int(y * unit)

	mut draw_x := 0
	mut draw_y := 0

	match rot {
		.up {
			draw_x = init_x + sized_x
			draw_y = init_y + sized_y
		}
		.down {
			draw_x = init_x - sized_x
			draw_y = init_y - sized_y
		}
		.right {
			draw_x = init_x - sized_y
			draw_y = init_y + sized_x
		}
		.left {
			draw_x = init_x + sized_y
			draw_y = init_y - sized_x
		}
	}

	sized_font_size := int(font_size * unit)
	font := fonts.get_font_for_size(app, sized_font_size)
	text_size := rl.measure_text_ex(font, text, sized_font_size, 1)

	rl.draw_text_pro(font, text, rl.Vector2{
		x: draw_x
		y: draw_y
	}, rl.Vector2{
		x: text_size.x / 2
		y: text_size.y / 2
	}, int(rot) * 90, sized_font_size, 1, color)

	return rl.Rectangle{
		x:      x
		y:      y
		width:  text_size.x / unit
		height: text_size.y / unit
	}
}

pub fn draw_chip_pin(init_x_f f32, init_y_f f32, unit f32, x f32, y f32, contact_point data.ContactPoint, pin chip_catalog.PinEntry, dir_left bool, rot data.Rotation, color rl.Color) {
	init_x := int(init_x_f)
	init_y := int(init_y_f)

	sized_x := int(x * unit)
	sized_y := int(y * unit)

	mut draw_x := 0
	mut draw_y := 0

	match rot {
		.up {
			draw_x = init_x + sized_x
			draw_y = init_y + sized_y
		}
		.down {
			draw_x = init_x - sized_x
			draw_y = init_y - sized_y
		}
		.right {
			draw_x = init_x - sized_y
			draw_y = init_y + sized_x
		}
		.left {
			draw_x = init_x + sized_y
			draw_y = init_y - sized_x
		}
	}

	pin_rotation := if dir_left { turn(rot) } else { invert_rotation(turn(rot)) }

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
		draw_rotated_triangle(draw_x, draw_y, data.contact_point_size * unit, pin_rotation,
			color, if contact_point.input_state == .high { color } else { rl.raywhite })
		return
	}

	// otherwise -> output
	draw_rotated_triangle(draw_x, draw_y, data.contact_point_size * unit, invert_rotation(pin_rotation),
		color, if contact_point.output_state == .high { color } else { rl.raywhite })
}

fn draw_rotated_triangle(x f32, y f32, size f32, rot data.Rotation, line_color rl.Color, fill_color rl.Color) {
	mut v1 := rl.Vector2{}
	mut v2 := rl.Vector2{}
	mut v3 := rl.Vector2{}

	match rot {
		.left {
			v1 = rl.Vector2{x - size, y}
			v2 = rl.Vector2{x + size, y + size}
			v3 = rl.Vector2{x + size, y - size}
		}
		.right {
			v1 = rl.Vector2{x + size, y}
			v2 = rl.Vector2{x - size, y - size}
			v3 = rl.Vector2{x - size, y + size}
		}
		.up {
			v1 = rl.Vector2{x, y - size}
			v2 = rl.Vector2{x - size, y + size}
			v3 = rl.Vector2{x + size, y + size}
		}
		.down {
			v1 = rl.Vector2{x, y + size}
			v2 = rl.Vector2{x + size, y - size}
			v3 = rl.Vector2{x - size, y - size}
		}
	}

	rl.draw_triangle(v1, v2, v3, fill_color)
	rl.draw_triangle_lines(v1, v2, v3, line_color)
}

fn invert_rotation(rot data.Rotation) data.Rotation {
	return match rot {
		.left { .right }
		.right { .left }
		.up { .down }
		.down { .up }
	}
}

fn turn(rot data.Rotation) data.Rotation {
	return match rot {
		.left { .up }
		.up { .right }
		.right { .down }
		.down { .left }
	}
}

pub fn get_aabb_offset_for_rotation(x f32, y f32, w f32, h f32, rot data.Rotation) vec.Vec2[f32] {
	match rot {
		.up {
			return vec.vec2(x, y)
		}
		.down {
			return vec.vec2(-x - w, -y - h)
		}
		.right {
			return vec.vec2(-y - h, x)
		}
		.left {
			return vec.vec2(y, -x - w)
		}
	}
}

pub fn translate_point(pos vec.Vec2[int], x int, y int, rot data.Rotation) (int, int) {
	match rot {
		.up {
			return pos.x + x, pos.y + y
		}
		.down {
			return pos.x - x, pos.y - y
		}
		.right {
			return pos.x - y, pos.y + x
		}
		.left {
			return pos.x + y, pos.y - x
		}
	}
}
