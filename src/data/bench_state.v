module data

pub enum BenchState {
	idle
	moving_view
	selecting
	moving_components
	moving_wire
	placing_component
}

pub enum SelectedComponentType {
	none
	wire
	bus
	switch
	fixed_contact
	clock
	led
	chip
}
