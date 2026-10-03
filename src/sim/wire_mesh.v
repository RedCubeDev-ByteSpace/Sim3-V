module sim

import data
import components
import utils
import raylib as rl

fn recalculate_wire_meshes(mut app data.App) {
	if !app.sim.wire_mesh_recalc_needed {
		return
	}

	// reset the flag
	app.sim.wire_mesh_recalc_needed = false

	// firstly: clear out all previously generated wire meshes
	// when this function is called something in the simulation space has changes and its no longer accurate
	app.sim.wire_meshes.clear()
	app.sim.wire_branching_points.clear()

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

		// find a starting wire for mesh building
		for wire_stack in current_wire_positions.values() {
			wires := wire_stack.filter(app.sim.components[it] is components.Wire)
			if wires.len > 0 {
				wires_to_visit_queue << wires[0]
				break
			}
		}

		// no starting point found -> nothing we can do
		if wires_to_visit_queue.len == 0 {
			return
		}

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
			wire := app.sim.components[wire_comp_id]

			// skip any busses, they're not real wires (posers)
			if wire is components.Bus {
				continue
			}

			if wire is components.Wire {
				// add this element to our current wire mesh
				wire_mesh_wire_ids << wire.get_comp_id()

				// add any wires it was connected to
				wire_from := utils.vec_to_str(wire.get_wire_from())
				wire_to := utils.vec_to_str(wire.get_wire_to())
				if wire_from in current_wire_positions {
					// if there are more than two wires at this location -> add a connection marker
					utils.add_wire_branching_point(mut app, current_wire_positions, wire_from)

					wires_to_visit_queue << resolve_any_busses(app, current_wire_positions[wire_from],
						wire_comp_id)
					current_wire_positions.delete(wire_from)
				}
				if wire_to in current_wire_positions {
					// if there are more than two wires at this location -> add a connection marker
					utils.add_wire_branching_point(mut app, current_wire_positions, wire_to)

					wires_to_visit_queue << resolve_any_busses(app, current_wire_positions[wire_to],
						wire_comp_id)
					current_wire_positions.delete(wire_to)
				}

				// are there any contact points at this position?
				if wire_from in current_contact_point_positions {
					wire_mesh_contact_point_ids << current_contact_point_positions[wire_from]
					current_contact_point_positions.delete(wire_from)
				}
				if wire_to in current_contact_point_positions {
					wire_mesh_contact_point_ids << current_contact_point_positions[wire_to]
					current_contact_point_positions.delete(wire_to)
				}
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

fn resolve_any_busses(app data.App, wire_ids []i64, entry_wire i64) []i64 {
	// first: filter out all non busses, we will pass these right through
	mut wires := wire_ids.filter(app.sim.components[it] is components.Wire)

	// then: filter out all busses
	busses := wire_ids.filter(app.sim.components[it] is components.Bus)

	// resolve all wires of the same color that are connected to this bus
	color := app.sim.components[entry_wire].get_color()
	for bus_id in busses {
		wires << get_bus_endpoints_for_color(app, bus_id, color)
	}

	return wires
}

fn get_bus_endpoints_for_color(app data.App, initial_bus_id i64, wire_color rl.Color) []i64 {
	mut busses_to_visit := [initial_bus_id]
	mut visited_busses := []i64{}
	mut wires_found := []i64{}

	for busses_to_visit.len > 0 {
		// dequeue this bus
		bus_id := busses_to_visit[0]
		busses_to_visit.delete(0)

		// skip any busses we've looked at before
		if bus_id in visited_busses {
			continue
		}
		visited_busses << bus_id

		// is this bus segment connected to any other bus segments?
		bus := app.sim.components[bus_id]

		if bus is components.Bus {
			mut wires_to_look_through := []i64{}
			if utils.vec_to_str(bus.get_wire_from()) in app.sim.wire_positions {
				wires_to_look_through << app.sim.wire_positions[utils.vec_to_str(bus.get_wire_from())]
			}
			if utils.vec_to_str(bus.get_wire_to()) in app.sim.wire_positions {
				wires_to_look_through << app.sim.wire_positions[utils.vec_to_str(bus.get_wire_to())]
			}

			for wire in wires_to_look_through {
				if wire == bus_id {
					continue
				}

				comp := app.sim.components[wire]

				// is this an actual real real life legit wire?
				if comp is components.Wire {
					// if so: does it match the color we're looking for?
					if comp.get_color() == wire_color {
						wires_found << wire
					}
				}

				// if this isnt actually a wire but a lame old bus -> add it to the list to visit later
				if comp is components.Bus {
					busses_to_visit << wire
				}
			}
		}
	}

	return wires_found
}

fn update_wire_meshes(mut app data.App) {
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
			mut comp := app.sim.components[wire_id]
			if mut comp is components.Wire {
				comp.set_state(wire_mesh_state)
			}
		}
	}
}
