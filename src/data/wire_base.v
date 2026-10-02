module data

import math.vec
import raylib as rl

pub interface IWireBase {
	get_base() WireBase
}

@[heap]
pub struct WireBase {
mut:
	// base component properties
	comp_id               i64
	comp_name             string
	wire_from             vec.Vec2[int]
	wire_to               vec.Vec2[int]
	offset_from           vec.Vec2[int] = vec.vec2[int](0, 0)
	offset_to             vec.Vec2[int] = vec.vec2[int](0, 0)
	color                 rl.Color
	component_window_open bool
}

pub fn WireBase.new(mut app App, wire_from vec.Vec2[int], wire_to vec.Vec2[int], color rl.Color) WireBase {
	return WireBase{
		comp_id:   app.sim.global_id_counter++
		wire_from: wire_from
		wire_to:   wire_to
		color:     color
	}
}

pub fn (c WireBase) get_comp_id() i64 {
	return c.comp_id
}

pub fn (c WireBase) get_base() WireBase {
	return c
}

pub fn (w WireBase) get_wire_from() vec.Vec2[int] {
	return w.wire_from
}

pub fn (mut w WireBase) set_wire_from(pos vec.Vec2[int]) {
	w.wire_from = pos
}

pub fn (w WireBase) get_wire_to() vec.Vec2[int] {
	return w.wire_to
}

pub fn (mut w WireBase) set_wire_to(pos vec.Vec2[int]) {
	w.wire_to = pos
}

pub fn (w WireBase) get_offset_from() vec.Vec2[int] {
	return w.offset_from
}

pub fn (mut w WireBase) set_offset_from(offset vec.Vec2[int]) {
	w.offset_from = offset
}

pub fn (w WireBase) get_offset_to() vec.Vec2[int] {
	return w.offset_to
}

pub fn (mut w WireBase) set_offset_to(offset vec.Vec2[int]) {
	w.offset_to = offset
}

pub fn (mut w WireBase) set_offset(offset vec.Vec2[int]) {
	w.offset_from = offset
	w.offset_to = offset
}

pub fn (mut w WireBase) translate_by_offset() {
	w.wire_from = w.wire_from.add(w.offset_from)
	w.wire_to = w.wire_to.add(w.offset_to)
	w.offset_from = vec.vec2[int](0, 0)
	w.offset_to = vec.vec2[int](0, 0)
}

pub fn (w WireBase) get_rotation() Rotation {
	return .up
}

pub fn (mut w WireBase) set_rotation(rot Rotation) {}

pub fn (w WireBase) get_color() rl.Color {
	return w.color
}

pub fn (mut w WireBase) set_color(color rl.Color) {
	w.color = color
}

pub fn (w WireBase) get_aabb() AABB {
	mut x1 := f32(w.wire_from.x + w.offset_from.x)
	mut y1 := f32(w.wire_from.y + w.offset_from.y)
	mut x2 := f32(w.wire_to.x + w.offset_to.x)
	mut y2 := f32(w.wire_to.y + w.offset_to.y)

	if x1 > x2 {
		x1, x2 = x2, x1
	}

	if y1 > y2 {
		y1, y2 = y2, y1
	}

	return AABB{
		x:      x1 - aabb_padding
		y:      y1 - aabb_padding
		width:  x2 - x1 + aabb_padding * 2
		height: y2 - y1 + aabb_padding * 2
	}
}

pub fn (w WireBase) get_from_aabb() AABB {
	return AABB{
		x:      f32(w.wire_from.x) - aabb_padding
		y:      f32(w.wire_from.y) - aabb_padding
		width:  aabb_padding * 2
		height: aabb_padding * 2
	}
}

pub fn (w WireBase) get_to_aabb() AABB {
	return AABB{
		x:      f32(w.wire_to.x) - aabb_padding
		y:      f32(w.wire_to.y) - aabb_padding
		width:  aabb_padding * 2
		height: aabb_padding * 2
	}
}

pub fn (w WireBase) hit_test(pos vec.Vec2[f32]) bool {
	return is_point_inside_aabb(w.get_aabb(), pos)
}

pub fn (mut w WireBase) on_move(mut app App) {}

pub fn (mut w WireBase) on_moved(mut app App) {}

pub fn (w WireBase) has_interaction() bool {
	return false
}

pub fn (mut w WireBase) interact() {}

pub fn (mut w WireBase) open_component_window() {
	w.component_window_open = true
}

pub fn (mut w WireBase) draw_component_window(mut app App) {}
