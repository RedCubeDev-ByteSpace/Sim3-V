module input

import raylib as rl
import components
import data
import utils

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
	if rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_left))
		|| (rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_right))
		&& app.bench.placement.current_selected_component_type == .wire
		&& app.bench.placement.placed_wire_starting_point) {
		mouse_pos_in_world_space := data.screenspace_to_worldspace(app, app.input.mouse_pos)
		placement_pos := utils.roundificate_to_whole_point(mouse_pos_in_world_space)
		color := data.Color.from_rl(data.wire_colors[app.bench.placement.current_selected_color_idx])
		rotation := app.bench.placement.rotation.to_int()

		match app.bench.placement.current_selected_component_type {
			.none {}
			.switch {
				components.Switch.new(mut app,
					pos:   placement_pos
					rot:   rotation
					color: color
					state: false
				)
			}
			.fixed_contact {
				components.FixedContact.new(mut app,
					pos:   placement_pos
					rot:   rotation
					color: color
					state: false
				)
			}
			.clock {
				components.Clock.new(mut app,
					pos:       placement_pos
					rot:       rotation
					color:     color
					frequency: 1
				)
			}
			.led {
				components.LED.new(mut app,
					pos:   placement_pos
					rot:   rotation
					color: color
				)
			}
			.chip {
				components.Chip.new(mut app,
					pos:      placement_pos
					rot:      rotation
					color:    color
					chip_uid: app.bench.placement.current_selected_chip_uid
				)
			}
			.wire {
				if !app.bench.placement.placed_wire_starting_point {
					app.input.wire_place_start_pos = placement_pos
					app.bench.placement.placed_wire_starting_point = true
				} else {
					components.Wire.new(mut app,
						wire_from: app.input.wire_place_start_pos
						wire_to:   placement_pos
						color:     color
					)

					// if right mouse button -> continue on with the next wire segment
					if rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_right)) {
						app.input.wire_place_start_pos = placement_pos
						app.bench.placement.placed_wire_starting_point = true
					}
					// if left -> end placement
					else {
						app.bench.placement.placed_wire_starting_point = false
					}
				}
			}
			.bus {
				if !app.bench.placement.placed_wire_starting_point {
					app.input.wire_place_start_pos = placement_pos
					app.bench.placement.placed_wire_starting_point = true
				} else {
					components.Bus.new(mut app,
						wire_from: app.input.wire_place_start_pos
						wire_to:   placement_pos
						color:     color
					)
					app.bench.placement.placed_wire_starting_point = false
				}
			}
		}
		return true
	}

	return false
}
