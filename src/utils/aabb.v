module utils

import raylib as rl
import math.vec
import data

pub fn get_viewport_aabb(app data.App) data.AABB {
	screen_width := rl.get_screen_width()
	screen_height := rl.get_screen_height()
	top_left := screenspace_to_worldspace(app, vec.vec2[f32](0, 0))
	bottom_right := screenspace_to_worldspace(app, vec.vec2[f32](screen_width, screen_height))

	return data.AABB{
		x:      top_left.x
		y:      top_left.y
		width:  bottom_right.x - top_left.x
		height: bottom_right.y - top_left.y
	}
}

pub fn do_aabbs_intersect(a data.AABB, b data.AABB) bool {
	return a.x < b.x + b.width && a.x + a.width > b.x && a.y < b.y + b.height
		&& a.y + a.height > b.y
}

pub fn is_aabb_inside_aabb(outer data.AABB, inner data.AABB) bool {
	return inner.x > outer.x && inner.x + inner.width < outer.x + outer.width && inner.y > outer.y
		&& inner.y + inner.height < outer.y + outer.height
}

pub fn is_point_inside_aabb(outer data.AABB, point vec.Vec2[f32]) bool {
	return point.x > outer.x && point.x < outer.x + outer.width && point.y > outer.y
		&& point.y < outer.y + outer.height
}
