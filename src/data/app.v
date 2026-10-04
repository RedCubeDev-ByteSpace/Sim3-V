module data

import microui
import math.vec
import raylib as rl
import chip_catalog

pub const one_simspace_unit_in_px = 20
pub const component_line_thickness = 2
pub const contact_point_size = 0.1
pub const zoom_lerp_cutoff = 0.001
pub const zoom_trail_cutoff = 0.005
pub const max_zoom = 12
pub const min_zoom = 0.2
pub const aabb_padding = 0.2
pub const step_marching_ants_every_frames = 3
pub const marching_ants_segment_size = 6

// App -----------------------------------------------------------------------------------------------------------------
// keeps track of all the state used in this application
@[heap]
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
			show_aabb     bool
			show_contacts bool
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
		wire_move_start_pos      vec.Vec2[f32]
		wire_place_start_pos     vec.Vec2[int]
		mui_needs_mouse_up       bool

		target_zoom f32 = 1
	}

	// sim -------------------------------------------------------------------------------------------------------------
	// everything concerning the simulation
	sim struct {
	pub mut:
		global_id_counter            i64
		wire_mesh_recalc_needed      bool
		components                   map[i64]IComponent
		wire_positions               map[string][]i64 // vec2 -> comp_id
		wire_meshes                  []WireMesh = []
		global_contact_point_counter i64
		contact_point_table          map[i64]&ContactPoint
		contact_point_positions      map[string][]i64
		wire_branching_points        []WireBranchingPoint = []
	}

	// bench -----------------------------------------------------------------------------------------------------------
	// everything concerning the circuit workbench
	bench struct {
	pub mut:
		bench_state                   BenchState
		return_after_move_bench_state BenchState
		selected_components           []IComponent = []
		marching_ants_starting_point  int
		marching_ants_frame_counter   int

		wire_moving struct {
		pub mut:
			wire_id        i64
			wire_end       WireEnd
			draw_hover_box bool
		}

		placement struct {
		pub mut:
			current_selected_color_idx      int
			current_selected_chip_uid       string
			current_selected_component_type SelectedComponentType
			rotation                        Rotation

			placed_wire_starting_point bool
		}

		clipboard struct {
		pub mut:
			current_clip_board []ComponentCfg
		}

		blueprints struct {
		pub mut:
			current_blueprint_cfgs []ComponentCfg
		}
	}

	// catalog ---------------------------------------------------------------------------------------------------------
	// everything concerning the catalog of chips that can be used in a simulation
	catalog struct {
	pub mut:
		chips  map[string]chip_catalog.ChipEntry
		groups map[string][]string
	}

	// storage ---------------------------------------------------------------------------------------------------------
	// everything concerning the saving and loading of things
	storage struct {
	pub mut:
		data_directory string

		has_blueprints_directory bool
		blueprints_directory     string

		blueprints struct {
		pub mut:
			blueprint_dir BlueprintDirectory

			gui struct {
			pub mut:
				is_showing_new_blueprint_dialog bool
				has_set_dialog_size             bool

				new_blueprint_name string
				new_blueprint_path string
			}
		}
	}

	// fonts -----------------------------------------------------------------------------------------------------------
	// preloaded fonts for different use cases and sizes
	fonts struct {
	pub mut:
		fonts []microui.SizedFont

		last_zoom f32

		chip_label_font      rl.Font
		chip_label_font_size f32

		chip_pin_label_font      rl.Font
		chip_pin_label_font_size f32

		fixed_contact_label_font      rl.Font
		fixed_contact_label_font_size f32
	}
}
