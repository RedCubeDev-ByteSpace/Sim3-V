module data

import raylib as rl

pub const background_color = rl.Color{230, 230, 230, 255}
pub const grid_color = rl.Color{0, 0, 0, 255}
pub const component_color = rl.Color{0, 0, 0, 255}
pub const aabb_color = rl.Color{255, 0, 0, 255}
pub const selection_color_high = rl.Color{0, 0, 0, 255}
pub const selection_color_low = rl.Color{38, 51, 82, 255}
pub const wire_error_color = rl.Color{255, 0, 0, 255}
pub const wire_colors = [
	rl.Color{84, 110, 122, 255}, // Slate Gray    #546E7A
	rl.Color{198, 40, 40, 255}, // Deep Red      #C62828
	rl.Color{239, 108, 0, 255}, // Burnt Orange  #EF6C00
	rl.Color{249, 168, 37, 255}, // Golden Yellow #F9A825
	rl.Color{46, 125, 50, 255}, // Emerald Green #2E7D32
	rl.Color{0, 137, 123, 255}, // Teal          #00897B
	rl.Color{21, 101, 192, 255}, // Royal Blue    #1565C0
	rl.Color{57, 73, 171, 255}, // Indigo        #3949AB
	rl.Color{142, 36, 170, 255}, // Violet        #8E24AA
]

pub fn get_low_color_from_high_color(color rl.Color) rl.Color {
	return rl.Color{
		r: u8(f32(color.r) * 0.5)
		g: u8(f32(color.g) * 0.5)
		b: u8(f32(color.b) * 0.5)
		a: color.a
	}
}
