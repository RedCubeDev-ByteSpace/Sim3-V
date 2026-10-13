module data

// ---------------------------------------------------------------------------------------------------------------------
// A lightweight handle used to reference an entry inside a slot map
pub struct SlotMapHandle {
pub:
	id  int
	gen int
}

pub type ComponentHandle = SlotMapHandle
pub type ContactPointHandle = SlotMapHandle

// ---------------------------------------------------------------------------------------------------------------------
// An internal slot for sparse lookup inside a slot map
struct Slot {
mut:
	gen   int
	index int // Index into the dense array (-1 if inactive)
}

// ---------------------------------------------------------------------------------------------------------------------
// a slot map! (a map of slots)
pub struct SlotMap[T] {
mut:
	slots             []Slot
	handles           []SlotMapHandle
	free_slot_indices []int
pub mut:
	data []T
}

// insert a component and return its unique generational handle
pub fn (mut sm SlotMap[T]) add(val T) SlotMapHandle {
	// are there any free slots? (because we freed the entry that was at that position)
	// -> reuse it!
	if sm.free_slot_indices.len > 0 {
		// get the first free index
		idx := sm.free_slot_indices.pop()

		// add this new entry to the data buffer and remember where to find it in the slot we're using
		sm.slots[idx].index = sm.data.len
		sm.data << val

		// create a new handle so the caller can retrieve this entry
		new_handle := SlotMapHandle{
			id:  idx
			gen: sm.slots[idx].gen
		}
		sm.handles << new_handle
		return new_handle
	}

	// no more free slots? -> add one!
	id := sm.slots.len
	gen := 0

	// add our entry to the data buffer and create a new slot pointing at it
	sm.slots << Slot{
		gen:   gen
		index: sm.data.len
	}
	sm.data << val

	// create a handle for looking it back up
	sm.handles << SlotMapHandle{
		id:  id
		gen: gen
	}
	return SlotMapHandle{
		id:  id
		gen: gen
	}
}

// Safely retrieve a reference to an entry using its handle
pub fn (sm SlotMap[T]) get(e SlotMapHandle) &T {
	// sorry mate
	if e.id < 0 || e.id >= sm.slots.len {
		panic('Invalid handle passed into SlotMap.get()!')
	}

	// get the slot pointed to by the handle
	slot := sm.slots[e.id]

	// has the data inside the slot changed or was it freed?
	if slot.gen != e.gen || slot.index == -1 {
		// sorry
		panic('Handle to already freed entry passed into SlotMap.get()!')
	}

	// otherwise: return the data!
	return &sm.data[slot.index]
}

// Remove a component using swap-and-pop to maintain a packed dense array
pub fn (mut sm SlotMap[T]) remove(e SlotMapHandle) bool {
	if e.id < 0 || e.id >= sm.slots.len {
		return false
	}
	slot := sm.slots[e.id]
	if slot.gen != e.gen || slot.index == -1 {
		return false
	}

	data_idx := slot.index
	last_data_idx := sm.data.len - 1

	// if it's not the last element -> swap it with the last one
	if data_idx != last_data_idx {
		sm.data[data_idx] = sm.data[last_data_idx]
		moved_entry := sm.handles[last_data_idx]
		sm.handles[data_idx] = moved_entry
		sm.slots[moved_entry.id].index = data_idx
	}

	// pop the end of the dense array
	sm.data.pop()
	sm.handles.pop()

	// invalidate the slot and push its index to the free list
	sm.slots[e.id].gen++
	sm.slots[e.id].index = -1
	sm.free_slot_indices << e.id

	return true
}
