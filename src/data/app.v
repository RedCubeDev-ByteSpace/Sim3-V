module data

import microui
import gg
import math.vec

pub const one_simspace_unit_in_px = 20

// App -----------------------------------------------------------------------------------------------------------------
// keeps track of all the state used in this application
pub struct App {
pub mut:
	gg &gg.Context = unsafe { nil }
	mu microui.Context

	// view ------------------------------------------------------------------------------------------------------------
	// everything concerning the current view on the simspace
	view struct {
	pub mut:
		camera_position vec.Vec2[f32] = vec.Vec2[f32]{0, 0}
		camera_offset   vec.Vec2[f32] = vec.Vec2[f32]{0, 0}
		zoom            f32           = 1
	}

	// input -----------------------------------------------------------------------------------------------------------
	// anything and everything concerning input
	input struct {
	pub mut:
		mouse_pos vec.Vec2[f32]

		is_moving_view        bool = false
		view_moving_start_pos vec.Vec2[f32]
	}
}
