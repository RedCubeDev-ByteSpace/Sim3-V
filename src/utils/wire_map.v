module utils

import math.vec
import data

pub fn register_wire(mut app data.App, pos vec.Vec2[int], wire_handle data.SlotMapHandle) {
	key := vec_to_str(pos)

	// if this position has no list yet -> create it
	if key !in app.sim.wire_positions {
		app.sim.wire_positions[key] = []
	}

	// add this wire to the list at this position
	app.sim.wire_positions[key] << wire_handle
}

pub fn unregister_wire(mut app data.App, pos vec.Vec2[int], wire_handle data.SlotMapHandle) {
	key := vec_to_str(pos)

	if key !in app.sim.wire_positions {
		return
	}

	// go through the list of registered wires
	for i, handle in app.sim.wire_positions[key] {
		if handle != wire_handle {
			continue
		}

		// delete this wire
		app.sim.wire_positions[key].delete(i)

		// if there are no more wires at this location
		// -> remove the list
		if app.sim.wire_positions[key].len == 0 {
			app.sim.wire_positions.delete(key)
		}

		return
	}

	panic('Could not delete wire registration!')
}

@[inline]
pub fn add_wire_branching_point(mut app data.App, wire_positions map[string][]data.SlotMapHandle, pos string) {
	if wire_positions[pos].len > 2 {
		wire := app.sim.components.get(wire_positions[pos][0])

		app.sim.wire_branching_points << data.WireBranchingPoint{
			pos:   str_to_vec(pos)
			color: wire.get_color()
		}
	}
}
