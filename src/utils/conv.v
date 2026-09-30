module utils

import math.vec
import data
import raylib

pub fn get_drawing_variables(app data.App, c data.ComponentBase) (vec.Vec2[f32], f32) {
	pos := c.get_position().add(c.get_offset())
	top_left := data.worldspace_to_screenspace(app, vec.vec2[f32](pos.x, pos.y))
	zoomed_unit := data.one_simspace_unit_in_px * app.view.zoom
	return top_left, zoomed_unit
}

pub fn vec_to_rl[T](v vec.Vec2[T]) raylib.Vector2 {
	return raylib.Vector2{
		x: f32(v.x)
		y: f32(v.y)
	}
}

pub fn vec_to_str(v vec.Vec2[int]) string {
	return '${v.x};${v.y}'
}
