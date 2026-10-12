module sim

import data
import raylib as rl

pub fn step_simulation(mut app data.App) {
	mut delta := rl.get_frame_time() / int(app.sim.steps_per_frame)

	// if the framerate drops below 60fps -> still assume that what we're running on to try and keep the sim accurate
	if delta > 1.0 / 60.0 {
		delta = 1.0 / 60.0
	}

	// reconstruct the wire meshes, if needed
	recalculate_wire_meshes(mut app)

	// always do at least one step of everything per frame
	app.sim.contact_point_output_changed = true

	for _ in 0 .. int(app.sim.steps_per_frame) {
		// step any steppable components that arent chips
		step_components(mut app, delta)

		// did no contact points change their output this cycle?
		// -> we're done
		if !app.sim.contact_point_output_changed {
			continue
		}
		app.sim.contact_point_output_changed = false

		// update add meshes
		update_wire_meshes(mut app)

		// step all chips
		step_chips(mut app)
	}
}

fn step_components(mut app data.App, delta f32) {
	for mut comp_handle in app.sim.component_views.other_steppables {
		mut comp := app.sim.components.get(comp_handle)
		comp.step(mut app, delta)
	}
}

fn step_chips(mut app data.App) {
	for mut comp_handle in app.sim.component_views.chips {
		mut comp := app.sim.components.get(comp_handle)
		comp.step(mut app, 0)
	}
}
