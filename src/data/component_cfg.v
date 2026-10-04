module data

import math.vec
import raylib as rl

pub interface IComponentCfg {
	get_top_left() vec.Vec2[int]
	get_bottom_right() vec.Vec2[int]
	get_color() rl.Color
mut:
	translate_by(v vec.Vec2[int])
	rotate(width int, height int)
}

pub struct WireBaseCfg {
pub:
	color rl.Color
pub mut:
	wire_from vec.Vec2[int]
	wire_to   vec.Vec2[int]
}

pub fn (w WireBaseCfg) get_top_left() vec.Vec2[int] {
	x1 := w.wire_from.x
	y1 := w.wire_from.y
	x2 := w.wire_to.x
	y2 := w.wire_to.y
	return vec.Vec2[int]{
		x: if x1 < x2 { x1 } else { x2 }
		y: if y1 < y2 { y1 } else { y2 }
	}
}

pub fn (w WireBaseCfg) get_bottom_right() vec.Vec2[int] {
	x1 := w.wire_from.x
	y1 := w.wire_from.y
	x2 := w.wire_to.x
	y2 := w.wire_to.y
	return vec.Vec2[int]{
		x: if x1 > x2 { x1 } else { x2 }
		y: if y1 > y2 { y1 } else { y2 }
	}
}

pub fn (w WireBaseCfg) get_color() rl.Color {
	return w.color
}

pub fn (mut w WireBaseCfg) translate_by(v vec.Vec2[int]) {
	w.wire_from = w.wire_from.add(v)
	w.wire_to = w.wire_to.add(v)
}

pub fn (mut w WireBaseCfg) rotate(width int, height int) {
	w.wire_from = vec.vec2(height - w.wire_from.y, w.wire_from.x)
	w.wire_to = vec.vec2(height - w.wire_to.y, w.wire_to.x)
}

pub struct ComponentBaseCfg {
pub:
	color rl.Color
pub mut:
	pos vec.Vec2[int]
	rot Rotation
}

pub fn (c ComponentBaseCfg) get_top_left() vec.Vec2[int] {
	return c.pos
}

pub fn (c ComponentBaseCfg) get_bottom_right() vec.Vec2[int] {
	return c.pos
}

pub fn (c ComponentBaseCfg) get_color() rl.Color {
	return c.color
}

pub fn (mut c ComponentBaseCfg) translate_by(v vec.Vec2[int]) {
	c.pos = c.pos.add(v)
}

pub fn (mut c ComponentBaseCfg) rotate(width int, height int) {
	c.pos = vec.vec2(height - c.pos.y, c.pos.x)

	c.rot = match c.rot {
		.left { .up }
		.up { .right }
		.right { .down }
		.down { .left }
	}
}

// ---------------------------------------------------------------------------------------------------------------------

@[params]
pub struct BusCfg {
	WireBaseCfg
}

@[params]
pub struct WireCfg {
	WireBaseCfg
}

@[params]
pub struct SwitchCfg {
	ComponentBaseCfg
pub:
	state bool
}

@[params]
pub struct FixedContactCfg {
	ComponentBaseCfg
pub:
	state bool
}

@[params]
pub struct ClockCfg {
	ComponentBaseCfg
pub:
	ticks_max int
}

@[params]
pub struct LEDCfg {
	ComponentBaseCfg
}

@[params]
pub struct ChipCfg {
	ComponentBaseCfg
pub:
	chip_uid string
}
