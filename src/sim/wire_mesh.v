module sim

import data

pub fn recalculate_wire_meshes(mut app data.App) {
	if !app.sim.wire_mesh_recalc_needed {
		return
	}

	// reset the flag
	app.sim.wire_mesh_recalc_needed = false

	// firstly: clear out all previously generated wire meshes
	// when this function is called something in the simulation space has changes and its no longer accurate
	app.sim.wire_meshes.clear()

	// -----------------------------------------------------------------------------------------------------------------
	// then: regenerate it

	mut current_wire_positions := app.sim.wire_positions.clone()
	mut wires_to_visit_queue := []i64{}
	mut visited_wires := []i64{}

	for {
		// if there are no (more) wires to go through -> we're done
		if current_wire_positions.len == 0 {
			dump(app.sim.wire_meshes)
			return
		}

		// start with the current first entry in the positions map
		first_key := current_wire_positions.keys()[0]
		wires_to_visit_queue << current_wire_positions[first_key]
		current_wire_positions.delete(first_key)

		mut wire_mesh_members := []i64{}

		// go through the wires_to_visit_queue until theres nothing left
		for wires_to_visit_queue.len > 0 {
			// dequeue the first element in the queue
			wire_comp_id := wires_to_visit_queue[0]
			wires_to_visit_queue.delete(0)

			// have we already looked at this wire?
			if wire_comp_id in visited_wires {
				continue
			}

			// make sure we wont visit this wire twice
			visited_wires << wire_comp_id

			// get the wire table entry for this wire
			wire := app.sim.wire_table[wire_comp_id]

			// add this element to our current wire mesh
			wire_mesh_members << wire.comp_id

			// add any wires it was connected to
			if wire.wire_from_pos in current_wire_positions {
				wires_to_visit_queue << current_wire_positions[wire.wire_from_pos]
				current_wire_positions.delete(wire.wire_from_pos)
			}
			if wire.wire_to_pos in current_wire_positions {
				wires_to_visit_queue << current_wire_positions[wire.wire_to_pos]
				current_wire_positions.delete(wire.wire_to_pos)
			}
		}

		if wire_mesh_members.len > 0 {
			// if theres no more wires to connect to this mesh
			// -> the mesh is finishes, add it to the list
			app.sim.wire_meshes << data.WireMesh{
				wires: wire_mesh_members
			}
		}
	}
}
