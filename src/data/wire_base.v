module data

import math.vec
import raylib as rl

pub struct WireBase {
mut:
	// base component properties
	comp_id               i64
	comp_name             string
	wire_from             vec.Vec2[int]
	wire_to               vec.Vec2[int]
	offset                vec.Vec2[int] = vec.vec2[int](0, 0)
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

pub fn (w WireBase) get_position() vec.Vec2[int] {
	return w.wire_from
}

pub fn (mut w WireBase) set_position(pos vec.Vec2[int]) {
	// update position of both wire ends
	delta := pos - w.wire_from
	w.wire_from = pos
	w.wire_to = w.wire_to + delta
}

pub fn (w WireBase) get_offset() vec.Vec2[int] {
	return w.offset
}

pub fn (mut w WireBase) set_offset(offset vec.Vec2[int]) {
	w.offset = offset
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
	mut x1 := f32(w.wire_from.x)
	mut y1 := f32(w.wire_from.y)
	mut x2 := f32(w.wire_to.x)
	mut y2 := f32(w.wire_to.y)

	if x1 > x2 {
		x1, x2 = x2, x1
	}

	if y1 > y2 {
		y1, y2 = y2, y1
	}

	return AABB{
		x:      int(x1 - aabb_padding + w.offset.x)
		y:      int(y1 - aabb_padding + w.offset.y)
		width:  int(x2 - x1 + aabb_padding * 2)
		height: int(y2 - y1 + aabb_padding * 2)
	}
}

pub fn (w WireBase) hit_test(pos vec.Vec2[f32]) bool {
	return is_point_inside_aabb(w.get_aabb(), pos)
}

pub fn (mut w WireBase) on_move(mut app App) {}

pub fn (mut w WireBase) on_moved(mut app App) {}

pub fn (mut w WireBase) interact() {}

pub fn (mut w WireBase) open_component_window() {
	w.component_window_open = true
}

pub fn (mut w WireBase) draw_component_window(mut app App) {}
