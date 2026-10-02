module main

import raylib as rl
import microui // look mom its my wrapper!
import gui
import data
import simview
import input
import components
import math.vec
import fonts
import sim
import chip_catalog

$if tinyc {
	#flag @VMODROOT/hacks/tcc.c
}

$if emscripten ? {
	#include <emscripten/emscripten.h>
}

fn C.emscripten_set_main_loop_arg(func fn (&data.App), arg &data.App, fps int, simulate_infinite_loop int)

// ---------------------------------------------------------------------------------------------------------------------
// constants for initial window configuration
const initial_window_width = 1600
const initial_window_height = 900
const window_title = 'Sim3'

// main ----------------------------------------------------------------------------------------------------------------
// the programs entry point
fn main() {
	// create a new state object for our application
	mut app := &data.App{}

	// create a new raylib window
	rl.set_config_flags(rl.ConfigFlags.flag_msaa_4x_hint)
	rl.init_window(initial_window_width, initial_window_height, window_title)
	rl.set_target_fps(60)
	rl.set_exit_key(0)
	rl.set_window_state(.flag_window_resizable)

	// load fonts
	fonts.init(mut app)

	// load the chips!!! wow i really need to clean up my initialization jesus
	app.catalog.chips, app.catalog.groups = chip_catalog.load_catalogs('./src/res/chips/catalogs') or {
		panic('Unable to load any catalogs! Did SOMEONE mess up the path?')
	}

	// ----------------------------------------------------------------------------------------------------------------
	// initialize microui
	app.mu = microui.new_context()

	// customize the microui style
	mut style := app.mu.get_style()

	// set the font spacing to 1
	style.font = microui.SizedFont{
		size: 15
		font: rl.load_font_ex('./src/res/tahoma.ttf', 15, unsafe { nil }, unsafe { nil })
	}

	// change some of the colors
	style.colors[microui.Color.text] = rl.Color{50, 50, 50, 255}
	style.colors[microui.Color.titletext] = rl.Color{50, 50, 50, 255}
	style.colors[microui.Color.titlebg] = rl.Color{255, 255, 255, 255}
	style.colors[microui.Color.windowbg] = rl.Color{230, 230, 230, 255}
	style.colors[microui.Color.base] = rl.Color{255, 255, 255, 255}
	style.colors[microui.Color.basehover] = rl.Color{240, 240, 240, 255}
	style.colors[microui.Color.basefocus] = rl.Color{200, 200, 200, 255}
	style.colors[microui.Color.button] = rl.Color{255, 255, 255, 255}
	style.colors[microui.Color.buttonhover] = rl.Color{240, 240, 240, 255}
	style.colors[microui.Color.buttonfocus] = rl.Color{220, 220, 220, 255}
	style.colors[microui.Color.scrollbase] = rl.Color{210, 210, 210, 255}
	style.colors[microui.Color.scrollthumb] = rl.Color{180, 180, 180, 255}

	app.mu.set_style(style)

	// initialize the camera so its pointing at 0,0
	app.view.camera_position = vec.vec2[f32](initial_window_width / data.one_simspace_unit_in_px / 2,
		initial_window_height / data.one_simspace_unit_in_px / 2)

	components.Wire.new(mut app, vec.vec2[int](0, 0), vec.vec2[int](3, 5), data.wire_colors[0])
	// components.Wire.new(mut app, vec.vec2[int](3, 5), vec.vec2[int](5, 5), data.wire_colors[1])
	// components.Wire.new(mut app, vec.vec2[int](3, 5), vec.vec2[int](-1, 2), data.wire_colors[2])
	// components.Wire.new(mut app, vec.vec2[int](-1, 2), vec.vec2[int](-1, -1), data.wire_colors[3])
	// app.sim.components << components.FixedContact.new(mut app, vec.vec2[int](3, 0), .up,
	// 	data.wire_colors[0], true)
	// app.sim.components << components.FixedContact.new(mut app, vec.vec2[int](6, 0), .right,
	// 	data.wire_colors[0], false)
	components.Switch.new(mut app, vec.vec2[int](0, 0), .right, data.wire_colors[0], true)
	components.Switch.new(mut app, vec.vec2[int](3, 5), .left, data.wire_colors[0], true)

	// run the main draw loop!
	$if emscripten ? {
		C.emscripten_set_main_loop_arg(on_frame, app, 0, 1)
	} $else {
		for !rl.window_should_close() {
			on_frame(mut app)
		}
	}

	// clean up
	rl.close_window()
}

// on_frame ------------------------------------------------------------------------------------------------------------
// draw a new frame!
fn on_frame(mut app data.App) {
	input.handle_input(mut app)
	input.sync_zoom(mut app)

	sim.recalculate_wire_meshes(mut app)
	sim.update_wire_meshes(mut app)

	rl.begin_drawing()
	rl.clear_background(data.background_color)

	// draw all the components that are currently in view
	simview.step_marching_ants(mut app)
	simview.draw_view(app)

	// draw the ui last so its always on top
	gui.draw_ui(mut app)

	rl.end_drawing()
}
