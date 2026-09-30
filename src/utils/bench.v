module utils

import data

pub fn toggle_component_placement(mut app data.App, component data.SelectedComponentType) {
	if app.bench.placement.selected_component_type == component {
		app.bench.placement.selected_component_type = .none
		app.bench.bench_state = .idle
	} else {
		app.bench.placement.selected_component_type = component
		app.bench.bench_state = .placing_component
	}
}

pub fn exit_component_placement(mut app data.App) {
	app.bench.placement.selected_component_type = .none
	app.bench.bench_state = .idle
}
