module data

import microui
import math.vec

pub const one_simspace_unit_in_px = 20
pub const component_line_thickness = 2
pub const zoom_lerp_cutoff = 0.001
pub const zoom_trail_cutoff = 0.005
pub const max_zoom = 12
pub const min_zoom = 0.2
pub const step_marching_ants_every_frames = 3
pub const marching_ants_segment_size = 6

// App -----------------------------------------------------------------------------------------------------------------
// keeps track of all the state used in this application
pub struct App {
pub mut:
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
		mouse_pos                vec.Vec2[f32]
		view_moving_start_pos    vec.Vec2[f32]
		selecting_start_pos      vec.Vec2[f32]
		component_move_start_pos vec.Vec2[f32]
		mui_needs_mouse_up       bool

		target_zoom f32 = 1
	}

	// sim -------------------------------------------------------------------------------------------------------------
	// everything concerning the simulation
	sim struct {
	pub mut:
		global_id_counter            i64
		wire_mesh_recalc_needed      bool         = false
		components                   []IComponent = []
		wire_table                   map[i64]WireTableEntry // comp_id -> wire
		wire_positions               map[string][]i64       // vec2 -> comp_id
		wire_meshes                  []WireMesh = []
		global_contact_point_counter i64
		contact_point_table          map[i64]&ContactPoint
		contact_point_positions      map[string][]i64
	}

	// bench -----------------------------------------------------------------------------------------------------------
	// everything concerning the circuit workbench
	bench struct {
	pub mut:
		bench_state                  BenchState
		current_selected_color_idx   int
		selected_components          []IComponent = []
		marching_ants_starting_point int
		marching_ants_frame_counter  int
	}

	// fonts -----------------------------------------------------------------------------------------------------------
	// preloaded fonts for different use cases and sizes
	fonts struct {
	pub mut:
		fonts []microui.SizedFont
	}
}
