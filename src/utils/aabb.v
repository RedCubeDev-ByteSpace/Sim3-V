module utils

import gg
import math.vec
import data

pub fn get_viewport_aabb(app data.App) data.AABB {
	screen_size := app.gg.window_size()
	top_left := screenspace_to_worldspace(app, vec.vec2[f32](0, 0))
	bottom_right := screenspace_to_worldspace(app, vec.vec2[f32](screen_size.width, screen_size.height))

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
