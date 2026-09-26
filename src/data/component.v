module data

import math.vec
import gg

pub type AABB = gg.Rect

pub interface IComponent {
	get_position() vec.Vec2[int]
	get_offset() vec.Vec2[int]
	get_aabb() AABB
	get_rotation() Rotation
	get_color() gg.Color

	draw(app App)
mut:
	set_position(pos vec.Vec2[int])
	set_offset(pos vec.Vec2[int])
	set_rotation(rot Rotation)
	set_color(color gg.Color)
}

pub struct ComponentBase {
mut:
	// base component properties
	pos      vec.Vec2[int]
	offset   vec.Vec2[int] = vec.vec2[int](0, 0)
	size     vec.Vec2[int]
	rotation Rotation
	color    gg.Color
}

pub fn ComponentBase.new(pos vec.Vec2[int], size vec.Vec2[int], rot Rotation, color gg.Color) ComponentBase {
	return ComponentBase{
		pos:      pos
		size:     size
		rotation: rot
		color:    color
	}
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

pub fn (c ComponentBase) get_rotation() Rotation {
	return c.rotation
}

pub fn (mut c ComponentBase) set_rotation(rot Rotation) {
	c.rotation = rot
}

pub fn (c ComponentBase) get_color() gg.Color {
	return c.color
}

pub fn (mut c ComponentBase) set_color(color gg.Color) {
	c.color = color
}

pub fn (c ComponentBase) get_aabb() AABB {
	return AABB{
		x:      f32(c.pos.x + c.offset.x) - 0.2
		y:      f32(c.pos.y + c.offset.y) - 0.2
		width:  f32(c.size.x) + 0.4
		height: f32(c.size.y) + 0.4
	}
}
