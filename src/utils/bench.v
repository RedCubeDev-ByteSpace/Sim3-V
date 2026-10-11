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

pub fn add_component(mut app data.App, component data.IComponent) data.SlotMapHandle {
	handle := app.sim.components.add(component)

	// also add this component to all relevant views
	is_wire := component is data.IWireBase

	// if this is a wire...
	if is_wire {
		// add to the wire list
		app.sim.component_views.wires << handle
		return handle
	} else {
		// otherwise: add to the non-wire list
		app.sim.component_views.non_wires << handle
	}

	// keep track of any chip components because they may be stepped through separately
	if component.is_chip() {
		app.sim.component_views.chips << handle
		return handle
	}

	// also separately keep track of components that have a step() function
	if component.has_step() {
		app.sim.component_views.other_steppables << handle
	}

	return handle
}

pub fn remove_component(mut app data.App, component data.IComponent) {
	handle := component.get_handle()
	app.sim.components.remove(handle)

	// also add this component to all relevant views
	is_wire := component is data.IWireBase

	// if this is a wire...
	if is_wire {
		// remove it from the wire view
		for i, wire_handle in app.sim.component_views.wires {
			if wire_handle == handle {
				app.sim.component_views.wires.delete(i)
				return
			}
		}

		return
	} else {
		// otherwise: remove it from the non-wire view
		for i, comp_handle in app.sim.component_views.non_wires {
			if comp_handle == handle {
				app.sim.component_views.non_wires.delete(i)
				break
			}
		}
	}

	if component.is_chip() {
		for i, comp_handle in app.sim.component_views.chips {
			if comp_handle == handle {
				app.sim.component_views.chips.delete(i)
				return
			}
		}
	}
	// if this has a step function -> remove it from the step view
	else if component.has_step() {
		for i, comp_handle in app.sim.component_views.other_steppables {
			if comp_handle == handle {
				app.sim.component_views.other_steppables.delete(i)
				return
			}
		}
	}
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
