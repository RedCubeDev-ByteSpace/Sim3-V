module renderers

import raylib as rl
import data
import math.vec

pub fn get_component_rectangle_variables(init_x_f f32, init_y_f f32, unit f32, x f32, y f32, width f32, height f32, rot data.Rotation) rl.Rectangle {
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

	return rect
}

pub fn get_contact_line_variables(init_x_f f32, init_y_f f32, unit f32, from_x f32, from_y f32, to_x f32, to_y f32, rot data.Rotation) (int, int, int, int) {
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

	return draw_from_x, draw_from_y, draw_to_x, draw_to_y
}

pub fn get_line_variables(init_x_f f32, init_y_f f32, unit f32, from_x f32, from_y f32, to_x f32, to_y f32, thick f32, rot data.Rotation) (int, int, int, int, f32) {
	init_x := int(init_x_f)
	init_y := int(init_y_f)

	sized_from_x := int(from_x * unit)
	sized_from_y := int(from_y * unit)
	sized_to_x := int(to_x * unit)
	sized_to_y := int(to_y * unit)

	sized_thick := thick * unit

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

	return draw_from_x, draw_from_y, draw_to_x, draw_to_y, sized_thick
}

pub fn get_circle_filled_variables(init_x_f f32, init_y_f f32, unit f32, x f32, y f32, radius f32, rot data.Rotation) (int, int, f32) {
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

	return draw_x, draw_y, sized_radius
}

pub fn get_circle_lines_variables(init_x_f f32, init_y_f f32, unit f32, x f32, y f32, radius f32, rot data.Rotation) (int, int, f32) {
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

	return draw_x, draw_y, sized_radius
}

pub fn get_centered_text_variables(init_x_f f32, init_y_f f32, unit f32, x f32, y f32, rot data.Rotation) (f32, f32) {
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

	return draw_x, draw_y
}

pub fn get_centered_text_rotated_variables(init_x_f f32, init_y_f f32, unit f32, x f32, y f32, rot data.Rotation) (int, int, int) {
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

	return draw_x, draw_y, int(rot) * 90
}

pub fn get_chip_pin_variables(init_x_f f32, init_y_f f32, unit f32, x f32, y f32, dir_left bool, rot data.Rotation) (int, int, data.Rotation, data.Rotation) {
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

	return draw_x, draw_y, pin_rotation, invert_rotation(pin_rotation)
}

fn get_rotated_triangle_variables(x f32, y f32, size f32, rot data.Rotation) (vec.Vec2[f32], vec.Vec2[f32], vec.Vec2[f32]) {
	mut v1 := vec.Vec2[f32]{}
	mut v2 := vec.Vec2[f32]{}
	mut v3 := vec.Vec2[f32]{}

	match rot {
		.left {
			v1 = vec.Vec2[f32]{x - size, y}
			v2 = vec.Vec2[f32]{x + size, y + size}
			v3 = vec.Vec2[f32]{x + size, y - size}
		}
		.right {
			v1 = vec.Vec2[f32]{x + size, y}
			v2 = vec.Vec2[f32]{x - size, y - size}
			v3 = vec.Vec2[f32]{x - size, y + size}
		}
		.up {
			v1 = vec.Vec2[f32]{x, y - size}
			v2 = vec.Vec2[f32]{x - size, y + size}
			v3 = vec.Vec2[f32]{x + size, y + size}
		}
		.down {
			v1 = vec.Vec2[f32]{x, y + size}
			v2 = vec.Vec2[f32]{x + size, y - size}
			v3 = vec.Vec2[f32]{x - size, y - size}
		}
	}

	return v1, v2, v3
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
