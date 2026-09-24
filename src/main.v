module main

import gg
import microui // look mom its my wrapper!
import gui
import data
import simview
import input

// ---------------------------------------------------------------------------------------------------------------------
// constants for initial window configuration
const initial_window_width = 800
const initial_window_height = 600
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
	)

	app.mu = microui.new_context(mut app.gg) or { panic('Failed to initialize microui!') }

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
	app.gg.begin()

	// draw all the components that are currently in view
	simview.draw_view(app)

	// draw the ui last so its always on top
	gui.draw_ui(mut app)

	app.gg.end()
}
