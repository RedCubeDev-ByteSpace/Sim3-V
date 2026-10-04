module data

import math.vec
import raylib as rl

pub interface IBaseCfg {
mut:
	get_top_left() vec.Vec2[int]
	get_color() rl.Color
	translate_by(v vec.Vec2[int])
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

pub fn (w WireBaseCfg) get_color() rl.Color {
	return w.color
}

pub fn (mut w WireBaseCfg) translate_by(v vec.Vec2[int]) {
	w.wire_from = w.wire_from.add(v)
	w.wire_to = w.wire_to.add(v)
}

pub struct ComponentBaseCfg {
pub:
	rot   Rotation
	color rl.Color
pub mut:
	pos vec.Vec2[int]
}

pub fn (c ComponentBaseCfg) get_top_left() vec.Vec2[int] {
	return c.pos
}

pub fn (c ComponentBaseCfg) get_color() rl.Color {
	return c.color
}

pub fn (mut c ComponentBaseCfg) translate_by(v vec.Vec2[int]) {
	c.pos = c.pos.add(v)
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

pub type ComponentCfg = WireCfg
	| BusCfg
	| SwitchCfg
	| FixedContactCfg
	| ClockCfg
	| LEDCfg
	| ChipCfg

pub fn (mut c ComponentCfg) get_top_left() vec.Vec2[int] {
	match mut c {
		WireCfg {
			return c.get_top_left()
		}
		BusCfg {
			return c.get_top_left()
		}
		SwitchCfg {
			return c.get_top_left()
		}
		FixedContactCfg {
			return c.get_top_left()
		}
		ClockCfg {
			return c.get_top_left()
		}
		LEDCfg {
			return c.get_top_left()
		}
		ChipCfg {
			return c.get_top_left()
		}
	}
}

pub fn (mut c ComponentCfg) get_color() rl.Color {
	match mut c {
		WireCfg {
			return c.get_color()
		}
		BusCfg {
			return c.get_color()
		}
		SwitchCfg {
			return c.get_color()
		}
		FixedContactCfg {
			return c.get_color()
		}
		ClockCfg {
			return c.get_color()
		}
		LEDCfg {
			return c.get_color()
		}
		ChipCfg {
			return c.get_color()
		}
	}
}

pub fn (mut c ComponentCfg) translate_by(v vec.Vec2[int]) {
	match mut c {
		WireCfg {
			c.translate_by(v)
		}
		BusCfg {
			c.translate_by(v)
		}
		SwitchCfg {
			c.translate_by(v)
		}
		FixedContactCfg {
			c.translate_by(v)
		}
		ClockCfg {
			c.translate_by(v)
		}
		LEDCfg {
			c.translate_by(v)
		}
		ChipCfg {
			c.translate_by(v)
		}
	}
}
