module main

import gg
import microui // look mom its my wrapper!
import gui
import data
import simview
import input
import components
import math.vec
import utils

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

	// create a new gg window
	app.gg = gg.new_context(
		// configure the window using our initial values
		width:        initial_window_width
		height:       initial_window_height
		window_title: window_title

		// remember our application data across all events
		user_data: app

		// define callbacks for frame drawing and input events
		frame_fn: on_frame
		event_fn: on_event

		// set the window background to a nice blinding white
		bg_color: gg.rgb(230, 230, 230) // its 23:24 right now, my retinas are burning up

		// font config :)
		font_bytes_normal: $embed_file('./res/tahoma.ttf').to_bytes()
	)

	app.mu = microui.new_context(mut app.gg) or { panic('Failed to initialize microui!') }

	// customize the microui style
	mut style := app.mu.get_style()

	// set the font spacing to 1
	style.font = gg.TextCfg{
		size: 15
	}
	style.size.y = 1

	// change some of the colors
	style.colors[microui.Color.text] = gg.Color{50, 50, 50, 255}
	style.colors[microui.Color.titletext] = gg.Color{50, 50, 50, 255}
	style.colors[microui.Color.titlebg] = gg.Color{255, 255, 255, 255}
	style.colors[microui.Color.windowbg] = gg.Color{230, 230, 230, 255}
	style.colors[microui.Color.base] = gg.Color{255, 255, 255, 255}
	style.colors[microui.Color.basehover] = gg.Color{240, 240, 240, 255}

	app.mu.set_style(style)

	// initialize the camera so its pointing at 0,0
	app.view.camera_position = vec.vec2[f32](initial_window_width / data.one_simspace_unit_in_px / 2,
		initial_window_height / data.one_simspace_unit_in_px / 2)

	app.sim.components << components.Switch.new(vec.vec2[int](0, 0), .left, data.wire_colors[0],
		false)
	app.sim.components << components.Switch.new(vec.vec2[int](3, 0), .up, data.wire_colors[0],
		true)
	app.sim.components << components.Switch.new(vec.vec2[int](6, 0), .right, data.wire_colors[0],
		false)

	app.sim.components << components.Switch.new(vec.vec2[int](10, 0), .down, data.wire_colors[0],
		false)

	// run the main draw loop!
	app.gg.run()
}

// on_event ------------------------------------------------------------------------------------------------------------
// all input events end up here
fn on_event(e &gg.Event, mut app data.App) {
	input.handle_input(e, mut app)
}

// on_frame ------------------------------------------------------------------------------------------------------------
// draw a new frame!
fn on_frame(mut app data.App) {
	input.sync_zoom(mut app)
	app.gg.begin()

	// draw all the components that are currently in view
	simview.step_marching_ants(mut app)
	simview.draw_view(app)

	// draw the ui last so its always on top
	gui.draw_ui(mut app)

	app.gg.show_fps()
	app.gg.end()
}
