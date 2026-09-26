module utils

import math.vec
import data
import gg

// worldspace_to_screenspace
// converts the coordinates of a point in world space into coordinates of that point in screen space
pub fn worldspace_to_screenspace[T](app data.App, world_space vec.Vec2[T]) vec.Vec2[T] {
	world_space_f32 := vec.vec2[f32](f32(world_space.x), f32(world_space.y))
	c := world_space_f32.add[f32](app.view.camera_position).mul_scalar[f32](data.one_simspace_unit_in_px * app.view.zoom).add(app.view.camera_offset)
	return vec.vec2[T](T(c.x), T(c.y))
}

// worldspace_to_previous_screenspace
// converts the coordinates of a point in world space into coordinates of that point in the screen space of the
// previous frame
pub fn worldspace_to_previous_screenspace[T](app data.App, world_space vec.Vec2[T]) vec.Vec2[T] {
	world_space_f32 := vec.vec2[f32](f32(world_space.x), f32(world_space.y))
	c := world_space_f32.add[f32](app.view.grid.prev_camera_position).mul_scalar[f32](data.one_simspace_unit_in_px * app.view.grid.prev_zoom).add(app.view.grid.prev_camera_offset)
	return vec.vec2[T](T(c.x), T(c.y))
}

// screenspace_to_worldspace
// converts the coordinates of a point on the screen into coordinates of that point in world space
pub fn screenspace_to_worldspace[T](app data.App, screen_space vec.Vec2[T]) vec.Vec2[T] {
	screen_space_f32 := vec.vec2[f32](f32(screen_space.x), f32(screen_space.y))
	c := screen_space_f32.sub(app.view.camera_offset).div_scalar[f32](data.one_simspace_unit_in_px * app.view.zoom).sub(app.view.camera_position)
	return vec.vec2[T](T(c.x), T(c.y))
}

pub fn get_drawing_variables(app data.App, c data.ComponentBase) (vec.Vec2[f32], f32) {
	pos := c.get_position()
	top_left := worldspace_to_screenspace(app, vec.vec2[f32](pos.x, pos.y))
	zoomed_unit := data.one_simspace_unit_in_px * app.view.zoom
	return top_left, zoomed_unit
}
