module data

pub enum ContactPointState {
	low
	high
	floating
}

pub struct ContactPoint {
	output_state ContactPointState
	input_state  WireState
}
