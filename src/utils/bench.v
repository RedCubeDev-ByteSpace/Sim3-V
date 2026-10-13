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

pub fn add_component(mut app data.App, component data.IComponent) data.ComponentHandle {
	handle := app.sim.components.add(component)

	// -----------------------------------------------------------------------------------------------------------------
	// also add this component to all relevant views
	is_wire := component is data.IWireBase

	// if this is a wire...
	if is_wire {
		// sort it into the wire list
		app.sim.component_views.wires.add(handle)
		return handle
	} else {
		// otherwise: sort it into the non-wire list
		app.sim.component_views.non_wires.add(handle)
	}

	// keep track of any chip components because they may be skipped when stepping the sim for performance reasons
	if component.is_chip() {
		app.sim.component_views.chips.add(handle)
		return handle
	}

	// also separately keep track of components that have a step() function
	if component.has_step() {
		app.sim.component_views.other_steppables.add(handle)
	}

	return handle
}

pub fn remove_component(mut app data.App, component data.IComponent) {
	handle := component.get_handle()
	app.sim.components.remove(handle)

	// make sure it gets removed from any views
	app.sim.component_views.wires.remove(handle)
	app.sim.component_views.non_wires.remove(handle)
	app.sim.component_views.chips.remove(handle)
	app.sim.component_views.other_steppables.remove(handle)
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
