module utils

import data
import math.vec

pub fn add_contact_point(mut app data.App, contact_point &data.ContactPoint) data.ContactPointHandle {
	return app.sim.contact_points.add(contact_point)
}

pub fn register_contact_point(mut app data.App, x int, y int, mut contact_point data.ContactPoint) {
	key := vec_to_str(vec.vec2(x, y))

	// if this position has no list yet -> create it
	if key !in app.sim.contact_point_positions {
		app.sim.contact_point_positions[key] = data.HandleList[data.ContactPointHandle]{}
	}

	// add this contact point to the list at this position
	app.sim.contact_point_positions[key].add(contact_point.contact_handle)

	// remember this location for later
	contact_point.pos_key = key
}

pub fn unregister_contact_point(mut app data.App, mut contact_point data.ContactPoint) {
	key := contact_point.pos_key

	if key !in app.sim.contact_point_positions {
		return
	}

	// remove this handle from the list
	app.sim.contact_point_positions[key].remove(contact_point.contact_handle)

	// if there are no more handles here -> remove the map entry
	if app.sim.contact_point_positions[key].is_empty() {
		app.sim.contact_point_positions.delete(key)
	}

	// clear the position stored in the contact point, shouldn't be necessary but lets do it anyway
	contact_point.pos_key = ''
}
