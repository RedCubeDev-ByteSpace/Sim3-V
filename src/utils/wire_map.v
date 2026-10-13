module utils

import math.vec
import data

pub fn register_wire(mut app data.App, pos vec.Vec2[int], wire_handle data.ComponentHandle) {
	key := vec_to_str(pos)

	// if this position has no list yet -> create it
	if key !in app.sim.wire_positions {
		app.sim.wire_positions[key] = data.HandleList[data.ComponentHandle]{}
	}

	// add this wire to the list at this position
	app.sim.wire_positions[key].add(wire_handle)
}

pub fn unregister_wire(mut app data.App, pos vec.Vec2[int], wire_handle data.ComponentHandle) {
	key := vec_to_str(pos)

	if key !in app.sim.wire_positions {
		return
	}

	// remove this handle from the wire stack at this position
	app.sim.wire_positions[key].remove(wire_handle)

	// if there are no more wires left here -> clean up this map entry
	if app.sim.wire_positions[key].is_empty() {
		app.sim.wire_positions.delete(key)
	}
}

@[inline]
pub fn add_wire_branching_point(mut app data.App, wire_positions map[string]data.HandleList[data.ComponentHandle], pos string) {
	if wire_positions[pos].len() > 2 {
		wire := app.sim.components.get(wire_positions[pos].handles()[0])

		app.sim.wire_branching_points << data.WireBranchingPoint{
			pos:   str_to_vec(pos)
			color: wire.get_color()
		}
	}
}
