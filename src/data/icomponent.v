module data

import math.vec
import raylib as rl

pub interface IComponent {
	get_cfg() IComponentCfg

	get_comp_id() i64
	get_aabb() AABB
	hit_test(pos vec.Vec2[f32]) bool
	get_rotation() Rotation
	get_color() rl.Color

	has_interaction() bool
	has_step() bool

	draw(app App)
mut:
	set_offset(offset vec.Vec2[int])
	set_offset_from(offset vec.Vec2[int])
	set_offset_to(offset vec.Vec2[int])
	translate_by_offset()

	set_rotation(rot Rotation)
	set_color(color rl.Color)

	on_move(mut app App)
	on_moved(mut app App)
	on_delete(mut app App)

	interact()
	open_component_window()
	draw_component_window(mut app App)
	step(app App)
}
