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
	switch
	fixed_contact
}
