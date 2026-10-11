module data

pub enum ContactPointState {
	low
	high
	floating
}

pub struct ContactPoint {
mut:
	output_state ContactPointState
pub:
	cont_id i64
pub mut:
	label       string
	input_state WireState
}

pub fn ContactPoint.new(mut app App, state ContactPointState) ContactPoint {
	return ContactPoint{
		cont_id:      app.sim.global_contact_point_counter++
		output_state: state
	}
}

pub fn (c ContactPoint) get_output_state() ContactPointState {
	return c.output_state
}

pub fn (mut c ContactPoint) set_output_state(mut app App, state ContactPointState) {
	if c.output_state != state {
		app.sim.contact_point_output_changed = true
	}

	c.output_state = state
}
