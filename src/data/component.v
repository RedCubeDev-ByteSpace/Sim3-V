module data

import math.vec
import raylib as rl

pub type AABB = C.Rectangle

pub interface IComponent {
	get_position() vec.Vec2[int]
	get_offset() vec.Vec2[int]
	get_aabb() AABB
	get_rotation() Rotation
	get_color() rl.Color

	draw(app App)
mut:
	set_position(pos vec.Vec2[int])
	set_offset(pos vec.Vec2[int])
	set_rotation(rot Rotation)
	set_color(color rl.Color)

	on_move()
	on_moved()

	interact()
	open_component_window()
	draw_component_window(mut app App)
}

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
	component_window_open bool
}

pub fn ComponentBase.new(mut app App, pos vec.Vec2[int], size vec.Vec2[int], rot Rotation, color rl.Color) ComponentBase {
	return ComponentBase{
		comp_id:  app.sim.global_id_counter++
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

pub fn (c ComponentBase) get_color() rl.Color {
	return c.color
}

pub fn (mut c ComponentBase) set_color(color rl.Color) {
	c.color = color
}

pub fn (c ComponentBase) get_aabb() AABB {
	return AABB{
		x:      f32(c.pos.x + c.offset.x) + c.aabb_offset.x - 0.2
		y:      f32(c.pos.y + c.offset.y) + c.aabb_offset.y - 0.2
		width:  f32(c.size.x) + 0.4
		height: f32(c.size.y) + 0.4
	}
}

pub fn (mut c ComponentBase) on_move() {}

pub fn (mut c ComponentBase) on_moved() {}

pub fn (mut c ComponentBase) interact() {}

pub fn (mut c ComponentBase) open_component_window() {
	c.component_window_open = true
}

pub fn (mut c ComponentBase) draw_component_window(mut app App) {}
