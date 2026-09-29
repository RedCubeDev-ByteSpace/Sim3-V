module utils

import math.vec
import data

pub fn register_wire(mut app data.App, pos vec.Vec2[int], wire_comp_id i64) {
	key := vec_to_str(pos)

	// if this position has no list yet -> create it
	if key !in app.sim.wire_positions {
		app.sim.wire_positions[key] = []
	}

	// add this wire to the list at this position
	app.sim.wire_positions[key] << wire_comp_id

	println("registered wire at '${key}' (now ${app.sim.wire_positions[key].len})")
}

pub fn unregister_wire(mut app data.App, pos vec.Vec2[int], wire_comp_id i64) {
	key := vec_to_str(pos)

	if key !in app.sim.wire_positions {
		return
	}

	// go through the list of registered wires
	for i, wcid in app.sim.wire_positions[key] {
		if wcid != wire_comp_id {
			continue
		}

		// delete this wire
		app.sim.wire_positions[key].delete(i)
		println("unregistered wire at '${key}' (now ${app.sim.wire_positions[key].len})")
		return
	}

	panic('Could not delete wire registration!')
}
