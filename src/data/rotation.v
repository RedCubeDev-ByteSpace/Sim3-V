module data

pub enum Rotation {
	left
	up
	right
	down
}

pub fn (r Rotation) to_int() int {
	return int(r)
}

pub fn Rotation.from_int(i int) Rotation {
	return match i {
		0 { .left }
		1 { .up }
		2 { .right }
		3 { .down }
		else { .left }
	}
}
