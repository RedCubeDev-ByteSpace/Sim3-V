module utils

import math.vec
import data

pub fn worldspace_to_screenspace(app data.App, world_space vec.Vec2[f32]) vec.Vec2[f32] {
	return world_space.mul_scalar[f32](data.one_simspace_unit_in_px * app.view.zoom).add(app.view.camera_offset)
}

pub fn screenspace_to_worldspace(app data.App, screen_space vec.Vec2[f32]) vec.Vec2[f32] {
	return screen_space.sub(app.view.camera_offset).div_scalar(data.one_simspace_unit_in_px * app.view.zoom)
}
