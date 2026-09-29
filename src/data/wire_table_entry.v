module data

pub struct WireTableEntry {
pub:
	comp_id       i64
	component     &IComponent
	wire_from_pos string
	wire_to_pos   string
}
