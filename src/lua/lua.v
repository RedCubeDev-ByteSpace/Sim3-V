module lua

import abuss.vlua.vlua
import data

const message_pack_stub = "package.path = package.path .. ';./src/res/lib/MessagePack.lua';"
const chip_base_library = './src/res/lib/base.lua'
const chip_script_dir = './src/res/chips/scripts/'

pub fn setup_chip_lua_state(app data.App, chip_uid string) ?voidptr {
	chip_entry := app.catalog.chips[chip_uid]

	// lua!!!!
	state := vlua.new_state() or {
		println('Couldnt create lua state')
		return none
	}

	// load the message pack lib
	vlua.safe_dostring(state, message_pack_stub) or {
		vlua.close_state(state)
		println('Couldnt run MessagePack stub')
		return none
	}

	// load the chip base lib
	vlua.safe_dofile(state, chip_base_library) or {
		vlua.close_state(state)
		println('Couldnt load lua base library')
		return none
	}

	// load the chip script
	vlua.safe_dofile(state, chip_script_dir + chip_entry.script.source) or {
		vlua.close_state(state)
		println("Couldnt load chip script '${chip_script_dir + chip_entry.script.source}'!")
		return none
	}

	return state
}

pub fn destroy_lua_state(state voidptr) {
	vlua.close_state(state)
}

pub fn has_function(state voidptr, func_name string) bool {
	C.lua_getglobal(state, func_name.str)
	if C.lua_isnil(state, -1) != 0 {
		C.lua_pop(state, 1)
		return false
	}
	is_function := C.lua_isfunction(state, -1) != 0
	C.lua_pop(state, 1)
	return is_function
}

pub fn do_pin_setup(state voidptr, mut pins []data.ContactPoint) {
	// load a reference to the setup function
	C.lua_getglobal(state, c'PinSetup')

	// convert the states of all pins into a lua table
	build_pin_table(state, pins, false)

	// call the function
	if C.lua_pcall(state, 0, 0, 0) != 0 {
		str := unsafe { cstring_to_vstring(C.lua_tostring(state, -1)) }
		println('Setup crashed!! \n' + str)
		C.lua_pop(state, 1)
		return
	}

	// read the pin table back in
	read_pin_table(state, mut pins)
}

pub fn do_step(state voidptr, mut pins []data.ContactPoint) {
	// load a reference to the step function
	C.lua_getglobal(state, c'Step')

	// convert the states of all pins into a lua table
	build_pin_table(state, pins, true)

	// call the function
	if C.lua_pcall(state, 0, 0, 0) != 0 {
		str := unsafe { cstring_to_vstring(C.lua_tostring(state, -1)) }
		println('Step crashed!! \n' + str)
		C.lua_pop(state, 1)
		return
	}

	// read the pin table back in
	read_pin_table(state, mut pins)
}

pub fn do_step_rising(state voidptr, mut pins []data.ContactPoint) {
	// load a reference to the step rising function
	C.lua_getglobal(state, c'StepRising')

	// convert the states of all pins into a lua table
	build_pin_table(state, pins, true)

	// call the function
	if C.lua_pcall(state, 0, 0, 0) != 0 {
		str := unsafe { cstring_to_vstring(C.lua_tostring(state, -1)) }
		println('StepRising crashed!! \n' + str)
		C.lua_pop(state, 1)
		return
	}

	// read the pin table back in
	read_pin_table(state, mut pins)
}

pub fn do_step_falling(state voidptr, mut pins []data.ContactPoint) {
	// load a reference to the step rising function
	C.lua_getglobal(state, c'StepFalling')

	// convert the states of all pins into a lua table
	build_pin_table(state, pins, true)

	// call the function
	if C.lua_pcall(state, 0, 0, 0) != 0 {
		str := unsafe { cstring_to_vstring(C.lua_tostring(state, -1)) }
		println('StepFalling crashed!! \n' + str)
		C.lua_pop(state, 1)
		return
	}

	// read the pin table back in
	read_pin_table(state, mut pins)
}

fn build_pin_table(state voidptr, pins []data.ContactPoint, include_input_state bool) {
	// create a lua table that contains the current state of all pins
	C.lua_newtable(state)

	for pin in pins {
		// create another table with "input" and "output" for each pin
		C.lua_newtable(state)

		// get the data into a suitable format
		// state 0 = LOW
		//       1 = HIGH
		//       2 = FLOATING
		output_state := match pin.output_state {
			.low { 0 }
			.high { 1 }
			.floating { 2 }
		}

		// write the output state into the table
		C.lua_pushnumber(state, output_state)
		C.lua_setfield(state, -2, c'output')

		// if this should include the input state
		// -> include it
		if include_input_state {
			// error states are also counted as low
			input_state := if pin.input_state == .high { 1 } else { 0 }

			// write the input state into the table
			C.lua_pushnumber(state, input_state)
			C.lua_setfield(state, -2, c'input')
		}

		// push the pin record onto the pin table
		C.lua_setfield(state, -2, pin.label.str)
	}

	// store this table in a global named "pins"
	C.lua_setglobal(state, c'pins')
}

fn read_pin_table(state voidptr, mut pins []data.ContactPoint) {
	// get the "pins" global
	C.lua_getglobal(state, c'pins')

	// apply the changes made to the actual pins
	for mut pin in pins {
		// get the record for this pin on the stack
		C.lua_getfield(state, -1, pin.label.str)

		// we only care about the output state
		C.lua_getfield(state, -1, c'output')

		// first: try to convert the value of the pin to an integer directly
		mut is_integer := 0
		mut pin_state := C.lua_tointegerx(state, -1, &is_integer)

		// if that didnt work:
		// -> convert to a boolean, every value is thruthy or falsy
		if is_integer == 0 {
			pin_state = if C.lua_toboolean(state, -1) != 0 { 1 } else { 0 }
		}

		C.lua_pop(state, 2)
		pin.output_state = match pin_state {
			0 { .low }
			1 { .high }
			else { .floating }
		}
	}

	C.lua_pop(state, 1)
}
