module utils

import data
import math.vec

pub fn toggle_component_placement(mut app data.App, component data.SelectedComponentType) {
	if app.bench.placement.current_selected_component_type == component {
		app.bench.placement.current_selected_component_type = .none
		app.bench.bench_state = .idle
	} else {
		app.bench.placement.current_selected_component_type = component
		app.bench.bench_state = .placing_component

		if component == .wire || component == .bus {
			app.bench.placement.placed_wire_starting_point = false
		}
	}
}

pub fn exit_component_placement(mut app data.App) {
	app.bench.placement.current_selected_component_type = .none
	app.bench.bench_state = .idle
}

pub fn add_component(mut app data.App, component data.IComponent) {
	app.sim.components[component.get_comp_id()] = component
}

// this is required because C will always round towards zero
// it stinkificates.
pub fn roundificate_to_whole_point(pos vec.Vec2[f32]) vec.Vec2[int] {
	mut rounded_x := 0
	mut rounded_y := 0

	if pos.x > 0 {
		rounded_x = int(pos.x + 0.5)
	} else if pos.x < 0 {
		rounded_x = int(pos.x - 0.5)
	}

	if pos.y > 0 {
		rounded_y = int(pos.y + 0.5)
	} else if pos.y < 0 {
		rounded_y = int(pos.y - 0.5)
	}

	return vec.Vec2[int]{
		x: rounded_x
		y: rounded_y
	}
}
