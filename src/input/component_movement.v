module input

import raylib as rl
import utils
import data
import math.vec

fn handle_component_move(mut app data.App) bool {
	// is the bench current unused, this is a mouse down AND we're currently hovering a selected component?
	// -> begin moving the selected components
	if app.bench.bench_state == .idle
		&& rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_left)) {
		mouse_pos_in_world_space := data.screenspace_to_worldspace(app, app.input.mouse_pos)
		for comp in app.bench.selected_components {
			if !comp.hit_test(mouse_pos_in_world_space) {
				continue
			}

			// remember the starting point of the move
			app.input.component_move_start_pos = mouse_pos_in_world_space
			app.bench.bench_state = .moving_components

			return true
		}
	}

	// if we're current in a move -> recalculate all component's offsets
	if app.bench.bench_state == .moving_components {
		mouse_pos_in_world_space := data.screenspace_to_worldspace(app, app.input.mouse_pos)
		new_offset := mouse_pos_in_world_space.sub(app.input.component_move_start_pos)

		for mut comp in app.bench.selected_components {
			comp.set_offset(vec.vec2[int](int(new_offset.x), int(new_offset.y)))
		}
	}

	// if we're currently moving and theres a mouse up -> end and commit movement
	if app.bench.bench_state == .moving_components
		&& rl.is_mouse_button_released(int(rl.MouseButton.mouse_button_left)) {
		for mut comp in app.bench.selected_components {
			// prepare the component for its move
			comp.on_move(mut app)

			// add the offest onto the position and reset it
			comp.translate_by_offset()

			// inform the component that its been moved
			comp.on_moved(mut app)
		}

		app.bench.bench_state = .idle
		return true
	}

	return false
}

fn handle_wire_move(mut app data.App) bool {
	mouse_pos_in_world_space := data.screenspace_to_worldspace(app, app.input.mouse_pos)

	// when the bench isnt busy right now
	// -> check if we're hovering a wire movement handle
	if app.bench.bench_state == .idle {
		app.bench.wire_moving.draw_hover_box = false

		// are we currently hovering a movement box of a wire?
		for wire in app.sim.components.values() {
			// dont target any wires that are already selected, moving the entire wire takes precedence over moving only
			// one of its points
			if wire in app.bench.selected_components {
				continue
			}

			if wire is data.IWireBase {
				base := wire.get_base()

				// if the mouse cursor is inside the "from" movement handle
				if data.is_point_inside_aabb(base.get_from_aabb(), mouse_pos_in_world_space) {
					// -> draw a box around it
					app.bench.wire_moving.wire_id = base.get_comp_id()
					app.bench.wire_moving.wire_end = .from
					app.bench.wire_moving.draw_hover_box = true
					break
				}

				// if the mouse cursor is inside the "to" movement handle
				if data.is_point_inside_aabb(base.get_to_aabb(), mouse_pos_in_world_space) {
					// -> draw a box around it
					app.bench.wire_moving.wire_id = base.get_comp_id()
					app.bench.wire_moving.wire_end = .to
					app.bench.wire_moving.draw_hover_box = true
					break
				}
			}
		}
	}

	// is the bench current unused, this is a mouse down AND we're currently hovering a wire handle
	// -> begin moving the wire end
	if app.bench.bench_state == .idle
		&& rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_left))
		&& app.bench.wire_moving.draw_hover_box {
		// remember the starting point of the move
		app.input.wire_move_start_pos = mouse_pos_in_world_space
		app.bench.bench_state = .moving_wire

		return true
	}

	// if we're current in a move -> recalculate the wire ends offset
	if app.bench.bench_state == .moving_wire {
		new_offset_f := mouse_pos_in_world_space.sub(app.input.wire_move_start_pos)
		new_offset := utils.roundificate_to_whole_point(new_offset_f)

		mut comp := app.sim.components[app.bench.wire_moving.wire_id]
		match app.bench.wire_moving.wire_end {
			.from {
				comp.set_offset_from(new_offset)
			}
			.to {
				comp.set_offset_to(new_offset)
			}
		}
	}

	// if we're currently moving and theres a mouse up -> end and commit movement
	if app.bench.bench_state == .moving_wire
		&& rl.is_mouse_button_released(int(rl.MouseButton.mouse_button_left)) {
		mut comp := app.sim.components[app.bench.wire_moving.wire_id]

		// prepare the component for its move
		comp.on_move(mut app)

		// add the offest onto the position and reset it
		comp.translate_by_offset()

		// inform the component that its been moved
		comp.on_moved(mut app)

		app.bench.bench_state = .idle
		return true
	}

	return false
}
