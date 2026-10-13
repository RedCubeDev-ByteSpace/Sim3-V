module data

pub struct HandleList[T] {
mut:
	entries []T
	idx     int
}

pub fn (mut h HandleList[T]) add(entry_to_add T) {
	h.entries << entry_to_add
}

pub fn (mut h HandleList[T]) remove(entry_to_remove T) {
	for i, entry in h.entries {
		if entry_to_remove == entry {
			h.entries.delete(i)
			return
		}
	}
}

pub fn (h HandleList[T]) is_empty() bool {
	return h.entries.len == 0
}

pub fn (h HandleList[T]) len() int {
	return h.entries.len
}

pub fn (h HandleList[T]) handles() []T {
	return h.entries
}
