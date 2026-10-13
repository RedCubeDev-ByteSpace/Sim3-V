module data

pub struct IntChipProperty {
pub:
	name string
pub mut:
	value i32
}

pub struct IntegerSliderChipProperty {
pub:
	name string
	min  int
	max  int
pub mut:
	value i32
}

pub type ChipProperty = IntChipProperty | IntegerSliderChipProperty
