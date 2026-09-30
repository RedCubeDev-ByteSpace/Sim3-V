module data

import math.vec
import raylib as rl

pub interface IComponent {
	get_position() vec.Vec2[int]
	get_offset() vec.Vec2[int]
	get_aabb() AABB
	hit_test(pos vec.Vec2[f32]) bool
	get_rotation() Rotation
	get_color() rl.Color

	draw(app App)
mut:
	set_position(pos vec.Vec2[int])
	set_offset(pos vec.Vec2[int])
	set_rotation(rot Rotation)
	set_color(color rl.Color)

	on_move(mut app App)
	on_moved(mut app App)

	interact()
	open_component_window()
	draw_component_window(mut app App)
}
