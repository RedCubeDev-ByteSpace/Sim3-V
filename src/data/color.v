module data

import raylib

pub struct Color {
pub:
	r u8
	g u8
	b u8
	a u8
}

pub fn (c Color) to_rl() raylib.Color {
	return raylib.Color{
		r: c.r
		g: c.g
		b: c.b
		a: c.a
	}
}

pub fn Color.from_rl(c raylib.Color) Color {
	return Color{
		r: c.r
		g: c.g
		b: c.b
		a: c.a
	}
}
