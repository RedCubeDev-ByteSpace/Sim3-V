module lua

import data
import os

const message_pack_stub = "package.path = package.path .. ';./src/res/lib/MessagePack.lua';"
const chip_base_library = './src/res/lib/base.lua'
const chip_script_dir = './src/res/chips/scripts/'

pub fn setup_chip_lua_state(app &data.App, chip_uid string) ?voidptr {
	chip_entry := app.catalog.chips[chip_uid]

	// lua!!!!
	state := C.luaL_newstate()
	if state == unsafe { nil } {
		// didnt work bruv
		return none
	}

	// load all of luas standard libs
	C.luaL_openlibs(state)

	// try to inject the message pack lib
	if C.luaL_dostring(state, message_pack_stub.str) != 0 {
		// aw man
		C.lua_close(state)
		println('Couldnt run lua MessagePack stub')
		return none
	}

	// load the base library for all chips
	if C.luaL_dofile(state, chip_base_library.str) != 0 {
		// shucks
		C.lua_close(state)
		println('Could not load lua chip base library')
		return none
	}

	// load this chips own lua script
	script_path := os.join_path(chip_script_dir, chip_entry.script.source)
	if C.luaL_dofile(state, script_path.str) != 0 {
		// damn
		C.lua_close(state)
		println('Couldnt load chip script "${script_path}"')
		return none
	}

	return state
}

pub fn destroy_lua_state(state voidptr) {
	C.lua_close(state)
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

pub fn do_property_setup(state voidptr) []data.ChipProperty {
	mut properties := &[]data.ChipProperty{}

	// -----------------------------------------------------------------------------------------------------------------
	// addIntSliderProperty(<name>, <min>, <max>, <default>)
	C.lua_pushcfunction(state, fn [mut properties] (lstate voidptr) int {
		name := unsafe { cstring_to_vstring(C.luaL_checkstring(lstate, 1)) }
		min := C.luaL_checkinteger(lstate, 2)
		max := C.luaL_checkinteger(lstate, 3)
		default := C.luaL_checkinteger(lstate, 4)

		properties << data.IntegerSliderChipProperty{
			name:  name
			min:   int(min)
			max:   int(max)
			value: int(default)
		}

		return 0
	})
	C.lua_setglobal(state, c'addIntegerSliderProperty')
	// -----------------------------------------------------------------------------------------------------------------
	// addIntegerProperty(<name>, <default>)
	C.lua_pushcfunction(state, fn [mut properties] (lstate voidptr) int {
		name := unsafe { cstring_to_vstring(C.luaL_checkstring(lstate, 1)) }
		default := C.luaL_checkinteger(lstate, 2)

		properties << data.IntChipProperty{
			name:  name
			value: int(default)
		}

		return 0
	})
	C.lua_setglobal(state, c'addIntegerProperty')
	// load a reference to the setup function
	C.lua_getglobal(state, c'PropertySetup')

	// call the function
	if C.lua_pcall(state, 0, 0, 0) != 0 {
		str := unsafe { cstring_to_vstring(C.lua_tostring(state, -1)) }
		println('PropertySetup crashed!! \n' + str)
		C.lua_pop(state, 1)
		return []
	}

	// unset all registration functions
	C.lua_pushnil(state)
	C.lua_setglobal(state, c'addIntegerSliderProperty')
	C.lua_pushnil(state)
	C.lua_setglobal(state, c'addIntegerProperty')
	return *properties
}

pub fn do_pin_setup(mut app data.App, state voidptr, mut pins []data.ContactPoint, mut props []data.ChipProperty) {
	// load a reference to the setup function
	C.lua_getglobal(state, c'PinSetup')

	// make all registered properties available here
	build_property_table(state, props)

	// convert the states of all pins into a lua table
	build_pin_table(state, pins, false)

	// call the function
	if C.lua_pcall(state, 0, 0, 0) != 0 {
		str := unsafe { cstring_to_vstring(C.lua_tostring(state, -1)) }
		println('PinSetup crashed!! \n' + str)
		C.lua_pop(state, 1)
		return
	}

	// read the pin table back in
	read_pin_table(mut app, state, mut pins)

	// read the properties back in
	read_property_table(state, mut props)
}

pub fn do_step(mut app data.App, state voidptr, mut pins []data.ContactPoint, mut props []data.ChipProperty) {
	// load a reference to the step function
	C.lua_getglobal(state, c'Step')

	// make all registered properties available here
	build_property_table(state, props)

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
	read_pin_table(mut app, state, mut pins)

	// read the properties back in
	read_property_table(state, mut props)
}

pub fn do_step_rising(mut app data.App, state voidptr, mut pins []data.ContactPoint, mut props []data.ChipProperty) {
	// load a reference to the step rising function
	C.lua_getglobal(state, c'StepRising')

	// make all registered properties available here
	build_property_table(state, props)

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
	read_pin_table(mut app, state, mut pins)

	// read the properties back in
	read_property_table(state, mut props)
}

pub fn do_step_falling(mut app data.App, state voidptr, mut pins []data.ContactPoint, mut props []data.ChipProperty) {
	// load a reference to the step falling function
	C.lua_getglobal(state, c'StepFalling')

	// make all registered properties available here
	build_property_table(state, props)

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
	read_pin_table(mut app, state, mut pins)

	// read the properties back in
	read_property_table(state, mut props)
}

pub fn do_save_state(state voidptr, props []data.ChipProperty) string {
	// make all registered properties available here
	build_property_table(state, props)

	// load a reference to the serialization function
	C.lua_getglobal(state, c'__serialize')

	// load a reference to the save state function
	C.lua_getglobal(state, c'SaveState')

	// call the SaveState() function
	if C.lua_pcall(state, 0, 1, 0) != 0 {
		str := unsafe { cstring_to_vstring(C.lua_tostring(state, -1)) }
		println('SaveState crashed!! \n' + str)
		C.lua_pop(state, 1)
		return ''
	}

	// call the __serialize() function
	if C.lua_pcall(state, 1, 1, 0) != 0 {
		str := unsafe { cstring_to_vstring(C.lua_tostring(state, -1)) }
		println('__serialize crashed!! \n' + str)
		C.lua_pop(state, 1)
		return ''
	}

	// get the serialized data
	chip_state := unsafe { cstring_to_vstring(C.lua_tostring(state, -1)) }
	return chip_state
}

pub fn do_load_state(state voidptr, chip_state string, mut props []data.ChipProperty) {
	// make all registered properties available here
	build_property_table(state, props)

	// load a reference to the load state function
	C.lua_getglobal(state, c'LoadState')

	// load a reference to the deserialization function
	C.lua_getglobal(state, c'__deserialize')

	// load the state as an argument
	C.lua_pushstring(state, chip_state.str)

	// call the __deserialize() function
	if C.lua_pcall(state, 1, 1, 0) != 0 {
		str := unsafe { cstring_to_vstring(C.lua_tostring(state, -1)) }
		println('__deserialize crashed!! \n' + str)
		C.lua_pop(state, 1)
		return
	}

	// call the LoadState() function
	if C.lua_pcall(state, 1, 0, 0) != 0 {
		str := unsafe { cstring_to_vstring(C.lua_tostring(state, -1)) }
		println('LoadState crashed!! \n' + str)
		C.lua_pop(state, 1)
		return
	}

	// read the properties back in
	read_property_table(state, mut props)
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
		output_state := match pin.get_output_state() {
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

fn read_pin_table(mut app data.App, state voidptr, mut pins []data.ContactPoint) {
	// get the "pins" global
	C.lua_getglobal(state, c'pins')

	// apply the changes made to the actual pins
	for mut pin in pins {
		// get the record for this pin on the stack
		C.lua_getfield(state, -1, pin.label.str)

		// we only care about the output state
		C.lua_getfield(state, -1, c'output')

		// first: try to convert the value of the pin to an integer directly
		mut is_integer := i32(0)
		mut pin_state := C.lua_tointegerx(state, -1, &is_integer)

		// if that didnt work:
		// -> convert to a boolean, every value is thruthy or falsy
		if is_integer == 0 {
			pin_state = if C.lua_toboolean(state, -1) != 0 { 1 } else { 0 }
		}

		C.lua_pop(state, 2)
		pin.set_output_state(mut app, match pin_state {
			0 { .low }
			1 { .high }
			else { .floating }
		})
	}

	C.lua_pop(state, 1)
}

fn build_property_table(state voidptr, properties []data.ChipProperty) {
	// create a lua table that contains the current state of all pins
	C.lua_newtable(state)

	for property in properties {
		match property {
			data.IntChipProperty {
				C.lua_pushinteger(state, property.value)
			}
			data.IntegerSliderChipProperty {
				C.lua_pushinteger(state, property.value)
			}
		}

		// push the pin record onto the pin table
		C.lua_setfield(state, -2, property.name.str)
	}

	// store this table in a global named "properties"
	C.lua_setglobal(state, c'properties')
}

fn read_property_table(state voidptr, mut properties []data.ChipProperty) {
	// get the "properties" global
	C.lua_getglobal(state, c'properties')

	// apply the changes made to the actual pins
	for mut property in properties {
		// get the record for this property on the stack
		C.lua_getfield(state, -1, property.name.str)

		match property {
			data.IntChipProperty {
				property.value = i32(C.lua_tointeger(state, -1))
			}
			data.IntegerSliderChipProperty {
				property.value = i32(C.lua_tointeger(state, -1))
			}
		}
	}

	C.lua_pop(state, 1)
}
