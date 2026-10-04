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

pub fn str_to_vec(s string) vec.Vec2[int] {
	parts := s.split(';')
	return vec.Vec2[int]{
		x: parts[0].i32()
		y: parts[1].i32()
	}
}

pub fn vi_to_vf(v vec.Vec2[int]) vec.Vec2[f32] {
	return vec.Vec2[f32]{
		x: f32(v.x)
		y: f32(v.y)
	}
}

pub fn vf_to_vi(v vec.Vec2[f32]) vec.Vec2[int] {
	return vec.Vec2[int]{
		x: int(v.x)
		y: int(v.y)
	}
}
