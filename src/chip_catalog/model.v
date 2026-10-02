module chip_catalog

pub struct ChipEntry {
pub:
	unique_id   string @[required]
	name        string @[required]
	description string
	pins        []PinEntry  @[required]
	script      ScriptEntry @[required]
pub mut:
	group          string
	origin_catalog string @[skip]
}

pub struct PinEntry {
pub:
	label         string @[required]
	is_power      bool
	is_active_low bool
}

pub struct ScriptEntry {
	source    string @[required]
	has_state bool   @[required]
}
