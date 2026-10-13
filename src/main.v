module main

import raylib as rl
import gui
import data
import simview
import input
import math.vec
import fonts
import sim
import chip_catalog
import storage
import renderers
import imgui
import icons

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

	// initialize a raylib renderer for drawing all the components
	app.renderers.raylib_direct_renderer = renderers.RaylibDirectRenderer{}

	// load fonts
	fonts.init(mut app)

	// generate icons
	icons.generate(mut app)

	// load the chips!!! wow i really need to clean up my initialization jesus
	app.catalog.chips, app.catalog.groups = chip_catalog.load_catalogs('./src/res/chips/catalogs') or {
		panic('Unable to load any catalogs! Did SOMEONE mess up the path?')
	}
	app.bench.placement.current_selected_chip_uid = app.catalog.chips.keys()[0]

	// setup storage things
	storage.setup_storage(mut app)

	// initialize the camera so its pointing at 0,0
	app.view.camera_position = vec.vec2[f32](initial_window_width / data.one_simspace_unit_in_px / 2,
		initial_window_height / data.one_simspace_unit_in_px / 2)

	// ----------------------------------------------------------------------------------------------------------------
	// set up imgui for raylib
	imgui.rl_imgui_setup(false)

	// load a font for imgui
	mut io := imgui.get_io_nil()
	app.fonts.imgui_font = imgui.im_font_atlas_add_font_from_file_ttf(io.Fonts, c'./src/res/tahoma.ttf',
		13, unsafe { nil }, unsafe { nil })

	mut imstyle := imgui.get_style()
	imstyle.FrameBorderSize = 1
	imstyle.Colors[int(imgui.Col_.button)] = imstyle.Colors[int(imgui.Col_.window_bg)]
	imstyle.Colors[int(imgui.Col_.button_hovered)] = imstyle.Colors[int(imgui.Col_.header)]
	imstyle.Colors[int(imgui.Col_.header)] = imstyle.Colors[int(imgui.Col_.window_bg)]

	io.ConfigWindowsMoveFromTitleBarOnly = true

	// run the main draw loop!
	$if emscripten ? {
		C.emscripten_set_main_loop_arg(on_frame, app, 0, 1)
	} $else {
		for !rl.window_should_close() {
			on_frame(mut app)
		}
	}

	// clean up imgui for raylib
	imgui.rl_imgui_shutdown()

	// clean up
	rl.close_window()
}

// on_frame ------------------------------------------------------------------------------------------------------------
// draw a new frame!
fn on_frame(mut app data.App) {
	input.handle_input(mut app)
	input.sync_zoom(mut app)

	sim.step_simulation(mut app)

	rl.begin_drawing()
	rl.clear_background(data.background_color)

	// draw all the components that are currently in view
	fonts.recalculate_font_choices(mut app)
	simview.step_marching_ants(mut app)
	simview.draw_view(mut app)

	// draw the ui last so its always on top
	gui.draw_ui(mut app)

	rl.end_drawing()
}
