module utils

import data
import math.vec

pub fn register_contact_point(mut app data.App, pos vec.Vec2[int], cont_id i64) {
	key := vec_to_str(pos)

	// if this position has no list yet -> create it
	if key !in app.sim.contact_point_positions {
		app.sim.contact_point_positions[key] = []
	}

	// add this contact point to the list at this position
	app.sim.contact_point_positions[key] << cont_id
}

pub fn unregister_contact_point(mut app data.App, pos vec.Vec2[int], cont_id i64) {
	key := vec_to_str(pos)

	if key !in app.sim.contact_point_positions {
		return
	}

	// go through the list of registered contact points
	for i, cpid in app.sim.contact_point_positions[key] {
		if cpid != cont_id {
			continue
		}

		// delete this contact point
		app.sim.contact_point_positions[key].delete(i)

		// if there are no more contact points at this location
		// -> remove the list
		if app.sim.contact_point_positions[key].len == 0 {
			app.sim.contact_point_positions.delete(key)
		}

		return
	}

	panic('Could not delete contact point registration!')
}
