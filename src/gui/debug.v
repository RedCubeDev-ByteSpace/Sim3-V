module gui

import raylib as rl
import data
import imgui
import math

fn draw_debug_window(mut app data.App) {
	// make sure this window sticks to the right side of the screen
	screen_width := rl.get_screen_width()
	window_width := 250
	window_height := 300
	margin := 5

	imgui.set_next_window_pos(imgui.ImVec2_c{screen_width - window_width - margin, margin},
		int(imgui.Cond_.always), imgui.ImVec2{0, 0})

	imgui.set_next_window_size(imgui.ImVec2_c{window_width, window_height}, int(imgui.Cond_.always))

	flags := int(imgui.WindowFlags_.no_move) | int(imgui.WindowFlags_.no_resize) | int(imgui.WindowFlags_.no_bring_to_front_on_focus)

	if imgui.begin(c'Debug Window', unsafe { nil }, flags) {
		// -------------------------------------------------------------------------------------------------------------
		// Debug output dump!! X3
		// -------------------------------------------------------------------------------------------------------------

		camera_pos := app.view.camera_position.add(app.view.camera_offset.div_scalar(app.view.zoom * data.one_simspace_unit_in_px))
		imgui.text('FPS: ${rl.get_fps()}'.str)

		io := imgui.get_io_nil()
		imgui.text('ImGui Input Capture: ${if io.WantCaptureMouse || io.WantCaptureKeyboard {
			'yes'
		} else {
			'no'
		}}'.str)
		imgui.text('Bench state: ${match app.bench.bench_state {
			.idle { 'idle' }
			.moving_view { 'moving_view' }
			.selecting { 'selecting' }
			.moving_components { 'moving_components' }
			.moving_wire { 'moving_wire' }
			.placing_component { 'placing_component' }
			.pasting_components { 'pasting_component' }
			.placing_blueprint { 'placing_blueprint' }
		}}'.str)
		imgui.text('Camera: ${camera_pos.x:.2f}, ${camera_pos.y:.2f}'.str)
		imgui.text('Mouse: ${app.input.mouse_pos.x:.0}, ${app.input.mouse_pos.y:.0}'.str)
		imgui.text('Zoom: ${app.view.zoom}'.str)
		imgui.text('Zoom%: ${if app.view.zoom >= 1 {
			math.log(app.view.zoom) / math.log(12)
		} else {
			0
		}:.2}'.str)
		imgui.text('Rotation: ${match app.bench.placement.rotation {
			.left { 'left' }
			.up { 'up' }
			.right { 'right' }
			.down { 'down' }
		}}'.str)

		// -------------------------------------------------------------------------------------------------------------
		// Debug options :))
		// -------------------------------------------------------------------------------------------------------------

		imgui.checkbox(c'Draw AABBs', app.view.debug.show_aabb)
		imgui.checkbox(c'Draw Contact Points', app.view.debug.show_contacts)
		imgui.checkbox(c'Only Draw LEDs', app.view.debug.draw_only_led)

		if imgui.begin_table(c'dbg_slider_table', 2, 0, imgui.ImVec2{0, 0}, 0) {
			imgui.table_setup_column(c'##labels', int(imgui.TableColumnFlags_.width_stretch),
				0, unsafe { nil })
			imgui.table_setup_column(c'##controls', int(imgui.TableColumnFlags_.width_stretch),
				0, unsafe { nil })

			imgui.table_next_column()
			imgui.text(c'Sim-Steps per Frame')

			imgui.table_next_column()
			available_width := imgui.get_content_region_avail().x
			imgui.set_next_item_width(available_width)
			imgui.slider_int(c'##sspf', app.sim.steps_per_frame, 1, 50, c'%d', 0)

			imgui.end_table()
		}
	}
	imgui.end()
}
