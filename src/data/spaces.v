module data

import math.vec
import raylib as rl

// worldspace_to_screenspace
// converts the coordinates of a point in world space into coordinates of that point in screen space
@[inline]
pub fn worldspace_to_screenspace[T](app &App, world_space vec.Vec2[T]) vec.Vec2[T] {
	ws_x_f32 := f32(world_space.x)
	ws_y_f32 := f32(world_space.y)

	zoomed_unit := one_simspace_unit_in_px * app.view.zoom

	cx := (ws_x_f32 + app.view.camera_position.x) * zoomed_unit + app.view.camera_offset.x
	cy := (ws_y_f32 + app.view.camera_position.y) * zoomed_unit + app.view.camera_offset.y

	return vec.vec2[T](T(cx), T(cy))
}

// worldspace_to_previous_screenspace
// converts the coordinates of a point in world space into coordinates of that point in the screen space of the
// previous frame
@[inline]
pub fn worldspace_to_previous_screenspace[T](app &App, world_space vec.Vec2[T]) vec.Vec2[T] {
	ws_x_f32 := f32(world_space.x)
	ws_y_f32 := f32(world_space.y)

	zoomed_unit := one_simspace_unit_in_px * app.view.grid.prev_zoom

	cx := (ws_x_f32 + app.view.grid.prev_camera_position.x) * zoomed_unit +
		app.view.grid.prev_camera_offset.x
	cy := (ws_y_f32 + app.view.grid.prev_camera_position.y) * zoomed_unit +
		app.view.grid.prev_camera_offset.y

	return vec.vec2[T](T(cx), T(cy))
}

// screenspace_to_worldspace
// converts the coordinates of a point on the screen into coordinates of that point in world space
@[inline]
pub fn screenspace_to_worldspace[T](app &App, screen_space vec.Vec2[T]) vec.Vec2[T] {
	scs_x_f32 := f32(screen_space.x)
	scs_y_f32 := f32(screen_space.y)

	zoomed_unit := one_simspace_unit_in_px * app.view.zoom

	cx := (scs_x_f32 - app.view.camera_offset.x) / zoomed_unit - app.view.camera_position.x
	cy := (scs_y_f32 - app.view.camera_offset.y) / zoomed_unit - app.view.camera_position.y

	return vec.vec2[T](T(cx), T(cy))
}

@[inline]
pub fn rect_worldspace_to_screenspace(app &App, world_space rl.Rectangle) rl.Rectangle {
	c := screenspace_to_worldspace(app, vec.vec2[f32](world_space.x, world_space.y))
	zoomed_unit := one_simspace_unit_in_px * app.view.zoom
	return rl.Rectangle{
		x:      c.x
		y:      c.y
		width:  world_space.width * zoomed_unit
		height: world_space.height * zoomed_unit
	}
}
