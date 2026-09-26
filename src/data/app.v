module data

import microui
import gg
import math.vec

pub const one_simspace_unit_in_px = 20
pub const zoom_lerp_cutoff = 0.001
pub const zoom_trail_cutoff = 0.005
pub const max_zoom = 12
pub const min_zoom = 0.2

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

		grid struct {
		pub mut:
			draw_grid_movement_trails bool
			prev_camera_position      vec.Vec2[f32] = vec.Vec2[f32]{0, 0}
			prev_camera_offset        vec.Vec2[f32] = vec.Vec2[f32]{0, 0}
			prev_zoom                 f32           = 1
		}

		debug struct {
		pub mut:
			show_aabb bool
		}
	}

	// input -----------------------------------------------------------------------------------------------------------
	// anything and everything concerning input
	input struct {
	pub mut:
		mouse_pos vec.Vec2[f32]

		is_moving_view        bool
		view_moving_start_pos vec.Vec2[f32]

		target_zoom f32 = 1
	}

	// sim -------------------------------------------------------------------------------------------------------------
	// everything concerning the simulation
	sim struct {
	pub mut:
		components []IComponent = []
	}

	// bench -----------------------------------------------------------------------------------------------------------
	// everything concerning the circuit workbench
	bench struct {
	pub mut:
		current_selected_color_idx int
	}
}
