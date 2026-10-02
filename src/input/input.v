module input

import raylib as rl
import data
import math.vec
import utils
import math
import components

pub fn handle_input(mut app data.App) {
	// first: share our current cursor position with microui and check if it wants to capture our input
	app.mu.update_mouse_position()
	if app.mu.wants_input_capture() && app.bench.bench_state != .moving_view
		&& app.bench.bench_state != .selecting {
		// if so: pass anything and everything else on to microui
		app.mu.handle_input_event()

		// important! keep track of if this was a mouse down
		// if so -> microui needs a mouse up after a mouse down but it wont always automatically be routed there because
		// if you close a window its input capture will immediately end without waiting for the release
		if rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_left)) {
			app.input.mui_needs_mouse_up = true
		}
		if rl.is_mouse_button_released(int(rl.MouseButton.mouse_button_left)) {
			app.input.mui_needs_mouse_up = false
		}

		return
	}

	if rl.is_mouse_button_released(int(rl.MouseButton.mouse_button_left))
		&& app.input.mui_needs_mouse_up {
		app.input.mui_needs_mouse_up = false
		app.mu.handle_input_event()
		return
	}

	// otherwise: treat it as input for the simview

	mouse_pos := rl.get_mouse_position()
	app.input.mouse_pos = vec.vec2[f32](mouse_pos.x, mouse_pos.y)

	// are we trying to interact with a component?
	if handle_component_interaction(mut app) {
		return
	}

	// is this event something about the movement of the view?
	if handle_simview_movement(mut app) {
		return
	}

	// is this movement a zoom in or out?
	if handle_simview_zoom(mut app) {
		return
	}

	// are we trying to place a component?
	if handle_component_placement(mut app) {
		return
	}

	// are we trying to delete selected components?
	if handle_component_deletion(mut app) {
		return
	}

	// are we trying to move something?
	if handle_component_move(mut app) {
		return
	}

	// are we trying to move part of a wire?
	if handle_wire_move(mut app) {
		return
	}

	// are we trying to move a wire?
	if handle_component_move(mut app) {
		return
	}

	// are we trying to select something?
	if handle_rectangle_select(mut app) {
		return
	}
}

fn handle_component_interaction(mut app data.App) bool {
	// is the workbench currently unused and theres been a mouse click...
	if app.bench.bench_state == .idle
		&& rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_left)) {
		// ... check if we've clicked on a component
		mouse_pos_in_world_space := data.screenspace_to_worldspace(app, app.input.mouse_pos)
		for mut comp in app.sim.components.values() {
			if !comp.has_interaction() {
				continue
			}

			// if yes AND component is not currectly selected -> interact
			if comp.hit_test(mouse_pos_in_world_space) && comp !in app.bench.selected_components {
				comp.interact()
				return true
			}
		}
	}

	// is the workbench currently unused and theres been a RIGHT mouse click...
	if app.bench.bench_state == .idle
		&& rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_right)) {
		// ... check if we've clicked on a component
		mouse_pos_in_world_space := data.screenspace_to_worldspace(app, app.input.mouse_pos)
		for mut comp in app.sim.components.values() {
			// if yes AND component is not currectly selected -> open component window
			if comp.hit_test(mouse_pos_in_world_space) && comp !in app.bench.selected_components {
				comp.open_component_window()
				return true
			}
		}
	}

	return false
}

fn handle_simview_movement(mut app data.App) bool {
	// when we're not already moving the view and the user pressed their right mouse button
	// -> start a new view movement
	if (app.bench.bench_state == .idle || app.bench.bench_state == .placing_component)
		&& rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_right)) {
		// set the view movement flag and remember where the move started
		app.bench.bench_state = .moving_view
		app.input.view_moving_start_pos = app.input.mouse_pos

		// dont process any input after this
		return true
	}

	// alternatively:
	// if we're already moving the view...
	if app.bench.bench_state == .moving_view {
		// ... and theres a mouse movement -> recalculate the view offset
		// remember the last offset for drawing grid movement trails
		app.view.grid.draw_grid_movement_trails = true
		app.view.grid.prev_camera_offset = app.view.camera_offset

		// update the camera offset
		app.view.camera_offset = vec.Vec2[f32]{
			x: app.input.mouse_pos.x - app.input.view_moving_start_pos.x
			y: app.input.mouse_pos.y - app.input.view_moving_start_pos.y
		}

		// ... and the user has stopped pressing the button -> apply the offset onto the actual camera position
		if rl.is_mouse_button_released(int(rl.MouseButton.mouse_button_right)) {
			app.view.camera_position = app.view.camera_position.add(app.view.camera_offset.div_scalar[f32](app.view.zoom * data.one_simspace_unit_in_px))
			app.view.camera_offset.zero()

			if app.bench.placement.current_selected_component_type != .none {
				app.bench.bench_state = .placing_component
			} else {
				app.bench.bench_state = .idle
			}

			// stop any grid movement trails
			app.view.grid.draw_grid_movement_trails = false
			app.view.grid.prev_camera_offset = app.view.camera_offset
			app.view.grid.prev_camera_position = app.view.camera_position

			// dont process any input after this
			return true
		}
	}

	return false
}

fn handle_simview_zoom(mut app data.App) bool {
	scroll := rl.get_mouse_wheel_move_v().y
	if scroll == 0 {
		return false
	}

	if scroll > 0 {
		new_zoom := app.input.target_zoom * 1.5
		if new_zoom < data.max_zoom {
			app.input.target_zoom = new_zoom
		}
	} else {
		if app.input.target_zoom > data.min_zoom {
			app.input.target_zoom /= 1.5
		}
	}

	return true
}

pub fn sync_zoom(mut app data.App) {
	if app.view.zoom == app.input.target_zoom {
		// nothing to do!
		return
	}

	// remember the previous zoom and camera position for grid movement trails
	app.view.grid.draw_grid_movement_trails = true
	app.view.grid.prev_camera_position = app.view.camera_position
	app.view.grid.prev_zoom = app.view.zoom

	// otherwise: lerp the zoom towards the target
	mouse_pos_in_world_space_before_zoom := data.screenspace_to_worldspace(app, app.input.mouse_pos)

	app.view.zoom = utils.lerp(app.view.zoom, app.input.target_zoom, 0.2)

	// are we close enough to the real value?
	if math.abs(app.view.zoom - app.input.target_zoom) <= data.zoom_lerp_cutoff {
		// stop lerping -> just jump to the real value
		app.view.zoom = app.input.target_zoom
	}

	// are we close enough to the real value to stop grid movement trails?
	// (because it looks weird if they go on for too long)
	if app.view.grid.draw_grid_movement_trails
		&& math.abs(app.view.zoom - app.input.target_zoom) <= data.zoom_trail_cutoff {
		// stop any movement tails
		app.view.grid.draw_grid_movement_trails = false
	}

	mouse_pos_in_world_space_after_zoom := data.screenspace_to_worldspace(app, app.input.mouse_pos)

	// adjust the camera position to zoom into where the cursor is positioned
	app.view.camera_position = app.view.camera_position.add(mouse_pos_in_world_space_after_zoom.sub(mouse_pos_in_world_space_before_zoom))
}

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

fn handle_rectangle_select(mut app data.App) bool {
	// is the bench current unused and this is a mouse down?
	// -> begin selection
	if app.bench.bench_state == .idle
		&& rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_left)) {
		app.bench.bench_state = .selecting
		app.input.selecting_start_pos = app.input.mouse_pos

		return true
	}

	// if we're currently selecting and theres a mouse up -> end selecting
	if app.bench.bench_state == .selecting
		&& rl.is_mouse_button_released(int(rl.MouseButton.mouse_button_left)) {
		// clear the selection list
		app.bench.selected_components = []

		// add all components inside the selected area
		mut x1 := app.input.selecting_start_pos.x
		mut y1 := app.input.selecting_start_pos.y
		mut x2 := app.input.mouse_pos.x
		mut y2 := app.input.mouse_pos.y

		// make sure x1, y1 is always the top left corner
		if y1 > y2 {
			y1, y2 = y2, y1
		}
		if x1 > x2 {
			x1, x2 = x2, x1
		}

		start_pos_world_space := data.screenspace_to_worldspace(app, vec.vec2[f32](x1,
			y1))
		end_pos_world_space := data.screenspace_to_worldspace(app, vec.vec2[f32](x2, y2))

		selection_aabb := data.AABB{
			x:      start_pos_world_space.x
			y:      start_pos_world_space.y
			width:  end_pos_world_space.x - start_pos_world_space.x
			height: end_pos_world_space.y - start_pos_world_space.y
		}

		for comp in app.sim.components.values() {
			if data.is_aabb_inside_aabb(selection_aabb, comp.get_aabb()) {
				app.bench.selected_components << comp
			}
		}

		app.bench.bench_state = .idle
		return true
	}

	return false
}

fn handle_component_placement(mut app data.App) bool {
	if app.bench.bench_state != .placing_component {
		return false
	}

	// if ESC is pressed while placing -> exit the placement mode
	if rl.is_key_pressed(int(rl.KeyboardKey.key_escape)) {
		utils.exit_component_placement(mut app)
		return true
	}

	// if R is pressed while placing -> rotate the component
	if rl.is_key_pressed(int(rl.KeyboardKey.key_q)) {
		app.bench.placement.rotation = match app.bench.placement.rotation {
			.left { .up }
			.up { .right }
			.right { .down }
			.down { .left }
		}
		return true
	}

	// if the left mouse button was pressed -> place the component
	if rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_left)) {
		mouse_pos_in_world_space := data.screenspace_to_worldspace(app, app.input.mouse_pos)
		placement_pos := utils.roundificate_to_whole_point(mouse_pos_in_world_space)
		color := data.wire_colors[app.bench.placement.current_selected_color_idx]
		rotation := app.bench.placement.rotation

		match app.bench.placement.current_selected_component_type {
			.none {}
			.switch {
				components.Switch.new(mut app, placement_pos, rotation, color, false)
			}
			.fixed_contact {
				components.FixedContact.new(mut app, placement_pos, rotation, color, false)
			}
			.led {
				components.LED.new(mut app, placement_pos, rotation, color)
			}
			.chip {}
			.wire {
				if !app.bench.placement.placed_wire_starting_point {
					app.input.wire_place_start_pos = placement_pos
					app.bench.placement.placed_wire_starting_point = true
				} else {
					components.Wire.new(mut app, app.input.wire_place_start_pos, placement_pos,
						color)
					app.bench.placement.placed_wire_starting_point = false
				}
			}
			.bus {
				if !app.bench.placement.placed_wire_starting_point {
					app.input.wire_place_start_pos = placement_pos
					app.bench.placement.placed_wire_starting_point = true
				} else {
					components.Bus.new(mut app, app.input.wire_place_start_pos, placement_pos,
						color)
					app.bench.placement.placed_wire_starting_point = false
				}
			}
		}
	}

	return true
}

fn handle_component_deletion(mut app data.App) bool {
	if app.bench.selected_components.len == 0 {
		return false
	}

	// allow both DEL and Backspace for deleting components
	if rl.is_key_pressed(int(rl.KeyboardKey.key_delete))
		|| rl.is_key_pressed(int(rl.KeyboardKey.key_backspace)) {
		for mut comp in app.bench.selected_components {
			comp.on_delete(mut app)

			// look this component up in the main list and delete it
			for i, lookup in app.sim.components {
				if lookup.get_comp_id() == comp.get_comp_id() {
					app.sim.components.delete(i)
					break
				}
			}
		}
		app.bench.selected_components.clear()
		return true
	}

	return false
}
