module sim

import data

pub fn step_simulation(mut app data.App) {
	// reconstruct the wire meshes, if needed
	recalculate_wire_meshes(mut app)

	// update add meshes
	update_wire_meshes(mut app)

	// step all components
	step_components(mut app)
}

fn step_components(mut app data.App) {
	for mut comp in app.sim.components.values() {
		if !comp.has_step() {
			continue
		}

		comp.step()
	}
}
