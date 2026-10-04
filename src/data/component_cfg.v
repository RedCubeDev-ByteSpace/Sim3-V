module data

import math.vec
import raylib as rl
import x.json2
import v2.gen.v

pub interface IComponentCfg {
	get_top_left() vec.Vec2[int]
	get_bottom_right() vec.Vec2[int]
	get_color() rl.Color
mut:
	translate_by(vector vec.Vec2[int])
	rotate(width int, height int)
}

pub struct WireBaseCfg {
pub:
	color Color
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
	return w.color.to_rl()
}

pub fn (mut w WireBaseCfg) translate_by(vector vec.Vec2[int]) {
	w.wire_from = w.wire_from.add(vector)
	w.wire_to = w.wire_to.add(vector)
}

pub fn (mut w WireBaseCfg) rotate(width int, height int) {
	w.wire_from = vec.vec2(height - w.wire_from.y, w.wire_from.x)
	w.wire_to = vec.vec2(height - w.wire_to.y, w.wire_to.x)
}

pub struct ComponentBaseCfg {
pub:
	color Color
pub mut:
	pos vec.Vec2[int]
	rot int
}

pub fn (c ComponentBaseCfg) get_top_left() vec.Vec2[int] {
	return c.pos
}

pub fn (c ComponentBaseCfg) get_bottom_right() vec.Vec2[int] {
	return c.pos
}

pub fn (c ComponentBaseCfg) get_color() rl.Color {
	return c.color.to_rl()
}

pub fn (mut c ComponentBaseCfg) translate_by(vector vec.Vec2[int]) {
	c.pos = c.pos.add(vector)
}

pub fn (mut c ComponentBaseCfg) rotate(width int, height int) {
	c.pos = vec.vec2(height - c.pos.y, c.pos.x)

	c.rot++
	c.rot %= 4
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

// ---------------------------------------------------------------------------------------------------------------------
pub type ComponentCfg = BusCfg
	| WireCfg
	| SwitchCfg
	| FixedContactCfg
	| ClockCfg
	| LEDCfg
	| ChipCfg

pub fn (c ComponentCfg) as_interface() IComponentCfg {
	match c {
		BusCfg { return c }
		WireCfg { return c }
		SwitchCfg { return c }
		FixedContactCfg { return c }
		ClockCfg { return c }
		LEDCfg { return c }
		ChipCfg { return c }
	}
}

pub fn (c ComponentCfg) to_json2() json2.Any {
	mut obj := map[string]json2.Any{}

	// generate the json encoding relaying logic at compile time
	$for var in ComponentCfg.variants {
		if c is var {
			// encode the components data
			obj = json2.map_from(c)
			dump(obj)

			// inject the objects type name for decoding later
			obj['_type'] = typeof(c).name
		}
	}
	return obj
}
