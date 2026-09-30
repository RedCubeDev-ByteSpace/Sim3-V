module data

import math.vec
import raylib as rl

// worldspace_to_screenspace
// converts the coordinates of a point in world space into coordinates of that point in screen space
pub fn worldspace_to_screenspace[T](app App, world_space vec.Vec2[T]) vec.Vec2[T] {
	world_space_f32 := vec.vec2[f32](f32(world_space.x), f32(world_space.y))
	c := world_space_f32.add[f32](app.view.camera_position).mul_scalar[f32](one_simspace_unit_in_px * app.view.zoom).add(app.view.camera_offset)
	return vec.vec2[T](T(c.x), T(c.y))
}

// worldspace_to_previous_screenspace
// converts the coordinates of a point in world space into coordinates of that point in the screen space of the
// previous frame
pub fn worldspace_to_previous_screenspace[T](app App, world_space vec.Vec2[T]) vec.Vec2[T] {
	world_space_f32 := vec.vec2[f32](f32(world_space.x), f32(world_space.y))
	c := world_space_f32.add[f32](app.view.grid.prev_camera_position).mul_scalar[f32](one_simspace_unit_in_px * app.view.grid.prev_zoom).add(app.view.grid.prev_camera_offset)
	return vec.vec2[T](T(c.x), T(c.y))
}

// screenspace_to_worldspace
// converts the coordinates of a point on the screen into coordinates of that point in world space
pub fn screenspace_to_worldspace[T](app App, screen_space vec.Vec2[T]) vec.Vec2[T] {
	screen_space_f32 := vec.vec2[f32](f32(screen_space.x), f32(screen_space.y))
	c := screen_space_f32.sub(app.view.camera_offset).div_scalar[f32](one_simspace_unit_in_px * app.view.zoom).sub(app.view.camera_position)
	return vec.vec2[T](T(c.x), T(c.y))
}

pub fn rect_worldspace_to_screenspace(app App, world_space rl.Rectangle) rl.Rectangle {
	world_space_f32 := vec.vec2(world_space.x, world_space.y)
	c := world_space_f32.add[f32](app.view.camera_position).mul_scalar[f32](one_simspace_unit_in_px * app.view.zoom).add(app.view.camera_offset)
	return rl.Rectangle{
		x:      c.x
		y:      c.y
		width:  world_space.width * one_simspace_unit_in_px * app.view.zoom
		height: world_space.height * one_simspace_unit_in_px * app.view.zoom
	}
}
