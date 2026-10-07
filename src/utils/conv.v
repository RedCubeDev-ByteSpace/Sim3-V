module utils

import math.vec
import data
import raylib as rl

pub fn get_drawing_variables(app data.App, c data.ComponentBase) (vec.Vec2[f32], f32) {
	pos := c.get_position().add(c.get_offset())
	top_left := data.worldspace_to_screenspace(app, vec.vec2[f32](pos.x, pos.y))
	zoomed_unit := data.one_simspace_unit_in_px * app.view.zoom
	return top_left, zoomed_unit
}

pub fn get_render_rect_in_screenspace(app data.App, render_rect rl.Rectangle) rl.Rectangle {
	top_left := data.worldspace_to_screenspace(app, vec.vec2[f32](render_rect.x, render_rect.y))
	zoomed_unit := f32(data.one_simspace_unit_in_px) * app.view.zoom
	return rl.Rectangle{
		x:      top_left.x
		y:      top_left.y
		width:  render_rect.width * zoomed_unit
		height: render_rect.height * zoomed_unit
	}
}

pub fn get_zoomed_render_rect(render_rect rl.Rectangle, zoom f32) (int, int) {
	render_width := int(render_rect.width * data.one_simspace_unit_in_px * zoom)
	render_height := int(render_rect.height * data.one_simspace_unit_in_px * zoom)
	return render_width, render_height
}

pub fn get_render_origin_and_zoom(render_offset vec.Vec2[f32], raw_zoom f32) (vec.Vec2[f32], f32) {
	return render_offset.mul_scalar(-(data.one_simspace_unit_in_px * raw_zoom)).add(vec.vec2[f32](data.render_cache_margin_px,
		data.render_cache_margin_px)), data.one_simspace_unit_in_px * raw_zoom
}

pub fn vec_to_rl[T](v vec.Vec2[T]) rl.Vector2 {
	return rl.Vector2{
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

pub fn vrl_to_vf(v rl.Vector2) vec.Vec2[f32] {
	return vec.Vec2[f32]{
		x: f32(v.x)
		y: f32(v.y)
	}
}

pub fn vf_to_vrl(v vec.Vec2[f32]) rl.Vector2 {
	return rl.Vector2{
		x: f32(v.x)
		y: f32(v.y)
	}
}

pub fn vi_to_vrl(v vec.Vec2[int]) rl.Vector2 {
	return rl.Vector2{
		x: f32(v.x)
		y: f32(v.y)
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
