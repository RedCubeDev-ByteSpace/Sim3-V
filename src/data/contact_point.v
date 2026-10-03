module data

pub enum ContactPointState {
	low
	high
	floating
}

pub struct ContactPoint {
pub:
	cont_id i64
pub mut:
	label        string
	output_state ContactPointState
	input_state  WireState
}

pub fn ContactPoint.new(mut app App, state ContactPointState) ContactPoint {
	return ContactPoint{
		cont_id:      app.sim.global_contact_point_counter++
		output_state: state
	}
}
