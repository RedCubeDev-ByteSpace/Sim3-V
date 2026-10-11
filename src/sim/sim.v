module sim

import data
import raylib as rl

pub fn step_simulation(mut app data.App) {
	delta := rl.get_frame_time() / int(app.sim.steps_per_frame)

	for _ in 0 .. int(app.sim.steps_per_frame) {
		// reconstruct the wire meshes, if needed
		recalculate_wire_meshes(mut app)

		// update add meshes
		update_wire_meshes(mut app)

		// step all components
		step_components(mut app, delta)
	}
}

fn step_components(mut app data.App, delta f32) {
	for mut comp_handle in app.sim.component_views.steppable_components {
		mut comp := app.sim.components.get(comp_handle)
		comp.step(app, delta)
	}
}
