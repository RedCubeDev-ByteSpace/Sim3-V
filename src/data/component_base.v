module data

import math.vec
import raylib as rl

pub struct ComponentBase {
mut:
	// base component properties
	comp_handle           ComponentHandle
	comp_name             string
	pos                   vec.Vec2[int]
	aabb_offset           vec.Vec2[f32] = vec.vec2[f32](0, 0)
	offset                vec.Vec2[int] = vec.vec2[int](0, 0)
	size                  vec.Vec2[int]
	rotation              Rotation
	color                 rl.Color
	has_interaction       bool
	has_step              bool
	is_chip               bool
	component_window_open bool
}

pub fn ComponentBase.new(mut app App, pos vec.Vec2[int], size vec.Vec2[int], rot Rotation, color rl.Color) ComponentBase {
	return ComponentBase{
		pos:      pos
		size:     size
		rotation: rot
		color:    color
	}
}

pub fn ComponentBase.new_interactable(mut app App, pos vec.Vec2[int], size vec.Vec2[int], rot Rotation, color rl.Color) ComponentBase {
	return ComponentBase{
		pos:             pos
		size:            size
		rotation:        rot
		color:           color
		has_interaction: true
	}
}

pub fn ComponentBase.new_steppable(mut app App, pos vec.Vec2[int], size vec.Vec2[int], rot Rotation, color rl.Color, has_interaction bool) ComponentBase {
	return ComponentBase{
		pos:             pos
		size:            size
		rotation:        rot
		color:           color
		has_step:        true
		has_interaction: has_interaction
	}
}

pub fn ComponentBase.new_chip(mut app App, pos vec.Vec2[int], size vec.Vec2[int], rot Rotation, color rl.Color) ComponentBase {
	return ComponentBase{
		pos:      pos
		size:     size
		rotation: rot
		color:    color
		has_step: true
		is_chip:  true
	}
}

pub fn (c ComponentBase) get_handle() ComponentHandle {
	return c.comp_handle
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
		width:
			f32(if c.rotation == .left || c.rotation == .right { c.size.x } else { c.size.y }) +
			aabb_padding * 2
		height:
			f32(if c.rotation == .left || c.rotation == .right { c.size.y } else { c.size.x }) +
			aabb_padding * 2
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

pub fn (c ComponentBase) is_chip() bool {
	return c.is_chip
}

pub fn (c ComponentBase) has_step() bool {
	return c.has_step
}

pub fn (mut c ComponentBase) interact(mut app App) {}

pub fn (mut c ComponentBase) step(mut app App, delta f32) {}

pub fn (mut c ComponentBase) open_component_window() {
	c.component_window_open = true
}

pub fn (mut c ComponentBase) draw_component_window(mut app App) {}
