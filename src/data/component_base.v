module data

import math.vec
import raylib as rl

@[heap]
pub struct ComponentBase {
mut:
	// base component properties
	comp_id               i64
	comp_name             string
	pos                   vec.Vec2[int]
	aabb_offset           vec.Vec2[f32] = vec.vec2[f32](0, 0)
	offset                vec.Vec2[int] = vec.vec2[int](0, 0)
	size                  vec.Vec2[int]
	rotation              Rotation
	color                 rl.Color
	has_interaction       bool
	component_window_open bool
}

pub fn ComponentBase.new(mut app App, pos vec.Vec2[int], size vec.Vec2[int], rot Rotation, color rl.Color, has_interaction bool) ComponentBase {
	return ComponentBase{
		comp_id:         app.sim.global_id_counter++
		pos:             pos
		size:            size
		rotation:        rot
		color:           color
		has_interaction: has_interaction
	}
}

pub fn (c ComponentBase) get_comp_id() i64 {
	return c.comp_id
}

pub fn (c ComponentBase) get_position() vec.Vec2[int] {
	return c.pos
}

pub fn (mut c ComponentBase) set_position(pos vec.Vec2[int]) {
	c.pos = pos
}

pub fn (c ComponentBase) get_offset() vec.Vec2[int] {
	return c.offset
}

pub fn (mut c ComponentBase) set_offset(offset vec.Vec2[int]) {
	c.offset = offset
}

pub fn (mut c ComponentBase) set_offset_from(offset vec.Vec2[int]) {}

pub fn (mut c ComponentBase) set_offset_to(offset vec.Vec2[int]) {}

pub fn (mut c ComponentBase) translate_by_offset() {
	c.pos = c.pos.add(c.offset)
	c.offset = vec.vec2[int](0, 0)
}

pub fn (c ComponentBase) get_rotation() Rotation {
	return c.rotation
}

pub fn (mut c ComponentBase) set_rotation(rot Rotation) {
	c.rotation = rot
}

pub fn (c ComponentBase) get_color() rl.Color {
	return c.color
}

pub fn (mut c ComponentBase) set_color(color rl.Color) {
	c.color = color
}

pub fn (c ComponentBase) get_aabb() AABB {
	return AABB{
		x:      f32(c.pos.x + c.offset.x) + c.aabb_offset.x - aabb_padding
		y:      f32(c.pos.y + c.offset.y) + c.aabb_offset.y - aabb_padding
		width:  f32(c.size.x) + aabb_padding * 2
		height: f32(c.size.y) + aabb_padding * 2
	}
}

pub fn (c ComponentBase) hit_test(pos vec.Vec2[f32]) bool {
	return is_point_inside_aabb(c.get_aabb(), pos)
}

pub fn (mut c ComponentBase) on_move(mut app App) {}

pub fn (mut c ComponentBase) on_moved(mut app App) {}

pub fn (c ComponentBase) has_interaction() bool {
	return c.has_interaction
}

pub fn (mut c ComponentBase) interact() {}

pub fn (mut c ComponentBase) open_component_window() {
	c.component_window_open = true
}

pub fn (mut c ComponentBase) draw_component_window(mut app App) {}
