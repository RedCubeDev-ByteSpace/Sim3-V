module sim

import data
import components

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
	mut current_contact_point_positions := app.sim.contact_point_positions.clone()
	mut wires_to_visit_queue := []i64{}
	mut visited_wires := []i64{}

	for {
		// if there are no (more) wires to go through -> we're done
		if current_wire_positions.len == 0 {
			return
		}

		mut wire_mesh_wire_ids := []i64{}
		mut wire_mesh_contact_point_ids := []i64{}

		// start with the current first entry in the positions map
		first_key := current_wire_positions.keys()[0]
		wires_to_visit_queue << current_wire_positions[first_key]
		current_wire_positions.delete(first_key)

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
			wire_mesh_wire_ids << wire.comp_id

			// add any wires it was connected to
			if wire.wire_from_pos in current_wire_positions {
				wires_to_visit_queue << current_wire_positions[wire.wire_from_pos]
				current_wire_positions.delete(wire.wire_from_pos)
			}
			if wire.wire_to_pos in current_wire_positions {
				wires_to_visit_queue << current_wire_positions[wire.wire_to_pos]
				current_wire_positions.delete(wire.wire_to_pos)
			}

			// are there any contact points at this position?
			if wire.wire_from_pos in current_contact_point_positions {
				wire_mesh_contact_point_ids << current_contact_point_positions[wire.wire_from_pos]
				current_contact_point_positions.delete(wire.wire_from_pos)
			}
			if wire.wire_to_pos in current_contact_point_positions {
				wire_mesh_contact_point_ids << current_contact_point_positions[wire.wire_to_pos]
				current_contact_point_positions.delete(wire.wire_to_pos)
			}
		}

		if wire_mesh_wire_ids.len > 0 {
			// translate all contact point ids into real references
			mut contact_points := []&data.ContactPoint{}
			for cont_id in wire_mesh_contact_point_ids {
				contact_points << app.sim.contact_point_table[cont_id]
			}

			// if theres no more wires to connect to this mesh
			// -> the mesh is finishes, add it to the list
			app.sim.wire_meshes << data.WireMesh{
				wires:          wire_mesh_wire_ids
				contact_points: contact_points
			}
		}
	}
}

pub fn update_wire_meshes(mut app data.App) {
	// go through each wire mesh
	for mut mesh in app.sim.wire_meshes {
		mut wire_mesh_state := data.WireState.error

		// tally up the output states of all connected contact points
		mut num_contacts_low := 0
		mut num_contacts_high := 0
		mut num_contacts_floating := 0

		for contact_point in mesh.contact_points {
			match contact_point.output_state {
				.low {
					num_contacts_low++
				}
				.high {
					num_contacts_high++
				}
				.floating {
					num_contacts_floating++
				}
			}
		}

		// figure out what state the wire mesh should have

		// if theres nothing connected
		if num_contacts_low + num_contacts_high + num_contacts_floating == 0 {
			// -> wire should be low
			wire_mesh_state = .low
		}
		// if one or more contacts are high and none are low
		else if num_contacts_high > 0 && num_contacts_low == 0 {
			// -> wire should be high
			wire_mesh_state = .high
		}
		// if one or more contacts are low and none are high
		else if num_contacts_low > 0 && num_contacts_high == 0 {
			// -> wire should be low
			wire_mesh_state = .low
		}
		// if there are contacts that are high and contacts that are low
		// -> this is a dead short! not fantastic!!
		else if num_contacts_low > 0 && num_contacts_high == 0 {
			wire_mesh_state = .error
		}
		// if all connection points are floating (probably because theyre inputs)
		// -> this is also bad! it should be grounded
		else if num_contacts_floating == mesh.contact_points.len {
			wire_mesh_state = .error
		}

		// distribute the new wire mesh state to all connected contacts
		for mut contact in mesh.contact_points {
			contact.input_state = wire_mesh_state
		}

		// distribute the new wire mesh state to all wires inside this mesh for drawing
		for wire_id in mesh.wires {
			mut comp := app.sim.wire_table[wire_id].component
			if mut comp is components.Wire {
				comp.set_state(wire_mesh_state)
			}
		}
	}
}
