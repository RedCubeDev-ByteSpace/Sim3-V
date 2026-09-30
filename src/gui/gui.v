module gui

import raylib as rl
import data
import math
import microui
import utils
import fonts

pub fn draw_ui(mut app data.App) {
	app.mu.begin()

	draw_debug_window(mut app)
	draw_color_window(mut app)
	draw_components_window(mut app)

	for mut comp in app.sim.components {
		comp.draw_component_window(mut app)
	}

	app.mu.end()
	app.mu.render()
}

fn draw_debug_window(mut app data.App) {
	if app.mu.begin_window_ex('Debug Window', rl.Rectangle{0, 0, 200, 145}, .noclose) {
		app.mu.layout_row([-1], 10)

		camera_pos := app.view.camera_position.add(app.view.camera_offset.div_scalar(app.view.zoom * data.one_simspace_unit_in_px))
		app.mu.label('MUi Input Capture: ${if app.mu.wants_input_capture() { 'yes' } else { 'no' }}')
		app.mu.label('Bench state: ${match app.bench.bench_state {
			.idle { 'idle' }
			.moving_view { 'moving_view' }
			.selecting { 'selecting' }
			.moving_components { 'moving_components' }
			.moving_wire { 'moving_wire' }
			.placing_component { 'placing_component' }
		}}')
		app.mu.label('Camera: ${camera_pos.x:.2f}, ${camera_pos.y:.2f}')
		app.mu.label('Mouse: ${app.input.mouse_pos.x:.0}, ${app.input.mouse_pos.y:.0}')
		app.mu.label('Zoom: ${app.view.zoom}')
		app.mu.label('Zoom%: ${if app.view.zoom >= 1 {
			math.log(app.view.zoom) / math.log(12)
		} else {
			0
		}:.2}')

		app.mu.layout_row([-1], 2)
		app.mu.layout_next()
		app.mu.layout_row([1, -1], 0)
		app.mu.layout_next()
		app.mu.checkbox('Draw AABBs', app.view.debug.show_aabb)

		app.mu.end_window()
	}

	// keep the window on the top right of the screen
	window_width := rl.get_screen_width()
	debug_window_rect_old := app.mu.get_container_rect('Debug Window')
	debug_window_rect_new := rl.Rectangle{
		...debug_window_rect_old
		x: window_width - debug_window_rect_old.width - 10
		y: 10
	}

	app.mu.set_container_rect('Debug Window', debug_window_rect_new)
}

fn draw_color_window(mut app data.App) {
	window_width := data.wire_colors.len * 30 + data.wire_colors.len * 5

	if app.mu.begin_window_ex('Colors', rl.Rectangle{10, 10, window_width, 65}, .noclose | .noresize | .noscroll) {
		mut widths := []int{}
		for _ in data.wire_colors {
			widths << 30
		}

		app.mu.layout_row(widths, 30)

		for i, color in data.wire_colors {
			rect := app.mu.layout_next()

			if app.mu.mouse_over(rect) && app.mu.is_mouse_pressed(.left) {
				app.bench.current_selected_color_idx = i
			}

			if i == app.bench.current_selected_color_idx {
				app.mu.draw_rect(rect, rl.Color{0, 0, 0, 255})
				app.mu.draw_rect(rl.Rectangle{
					x:      rect.x + 1
					y:      rect.y + 1
					width:  rect.width - 2
					height: rect.height - 2
				}, rl.Color{255, 255, 255, 255})
				app.mu.draw_rect(rl.Rectangle{
					x:      rect.x + 2
					y:      rect.y + 2
					width:  rect.width - 4
					height: rect.height - 4
				}, color)
			} else {
				app.mu.draw_rect(rect, color)
			}
		}

		app.mu.end_window()
	}
}

fn draw_components_window(mut app data.App) {
	if app.mu.begin_window_ex('Components', rl.Rectangle{10, 80, 110, 65}, .noclose | .noresize | .noscroll) {
		app.mu.layout_row([30, 30, 30], 30)

		style := app.mu.get_style()
		border_color := style.colors[microui.Color.border]
		hover_color := style.colors[microui.Color.basehover]
		focus_color := style.colors[microui.Color.basefocus]
		bg_color := style.colors[microui.Color.base]
		fg_color := style.colors[microui.Color.text]

		// -------------------------------------------------------------------------------------------------------------
		// Wire button

		// determine the background color for this button
		rect_wire := app.mu.layout_next()
		mut bg_wire := bg_color
		if app.bench.placement.selected_component_type == .wire {
			bg_wire = focus_color
		} else if app.mu.mouse_over(rect_wire) {
			bg_wire = hover_color
		}

		// when clicked: toggle this component being selected
		if app.mu.mouse_over(rect_wire) && app.mu.is_mouse_pressed(.left) {
			utils.toggle_component_placement(mut app, .wire)
			app.bench.placement.placed_wire_starting_point = false
		}

		// draw the button
		app.mu.draw_custom(rect_wire, app, fn [fg_color, bg_wire, border_color] (rect rl.Rectangle, _ voidptr) {
			rl.draw_rectangle(int(rect.x), int(rect.y), int(rect.width), int(rect.height),
				bg_wire)
			rl.draw_rectangle_lines_ex(rect, 1, border_color)

			margin := 5
			rl.draw_line_ex(rl.Vector2{rect.x + margin, rect.y + margin}, rl.Vector2{rect.x +
				rect.width - margin, rect.y + rect.width - margin}, 2, fg_color)
		})

		// -------------------------------------------------------------------------------------------------------------
		// Switch component button

		// determine the background color for this button
		rect_switch := app.mu.layout_next()
		mut bg_switch := bg_color
		if app.bench.placement.selected_component_type == .switch {
			bg_switch = focus_color
		} else if app.mu.mouse_over(rect_switch) {
			bg_switch = hover_color
		}

		// when clicked: toggle this component being selected
		if app.mu.mouse_over(rect_switch) && app.mu.is_mouse_pressed(.left) {
			utils.toggle_component_placement(mut app, .switch)
		}

		// draw the button
		app.mu.draw_custom(rect_switch, app, fn [fg_color, bg_switch, border_color] (rect rl.Rectangle, _ voidptr) {
			rl.draw_rectangle(int(rect.x), int(rect.y), int(rect.width), int(rect.height),
				bg_switch)
			rl.draw_rectangle_lines_ex(rect, 1, border_color)

			margin := 5
			rl.draw_rectangle_lines_ex(rl.Rectangle{
				x:      rect.x + margin
				y:      rect.y + margin
				width:  rect.width - margin * 2
				height: rect.height - margin * 2
			}, 2, fg_color)

			rl.draw_circle(int(rect.x + rect.width / 2), int(rect.y + rect.height / 2),
				5, fg_color)
		})

		// -------------------------------------------------------------------------------------------------------------
		// FixedContact component button

		// determine the background color for this button
		rect_fixed_contact := app.mu.layout_next()
		mut bg_fixed_contact := bg_color
		if app.bench.placement.selected_component_type == .fixed_contact {
			bg_fixed_contact = focus_color
		} else if app.mu.mouse_over(rect_fixed_contact) {
			bg_fixed_contact = hover_color
		}

		// when clicked: toggle this component being selected
		if app.mu.mouse_over(rect_fixed_contact) && app.mu.is_mouse_pressed(.left) {
			utils.toggle_component_placement(mut app, .fixed_contact)
		}

		// draw the button
		app.mu.draw_custom(rect_fixed_contact, app, fn [fg_color, bg_fixed_contact, border_color] (rect rl.Rectangle, mut app data.App) {
			rl.draw_rectangle(int(rect.x), int(rect.y), int(rect.width), int(rect.height),
				bg_fixed_contact)
			rl.draw_rectangle_lines_ex(rect, 1, border_color)

			margin := 5
			rl.draw_rectangle_lines_ex(rl.Rectangle{
				x:      rect.x + margin
				y:      rect.y + margin
				width:  rect.width - margin * 2
				height: rect.height - margin * 2
			}, 2, fg_color)

			font_size := 17
			font := fonts.get_font_for_size(app, font_size)
			text_size := rl.measure_text_ex(font, '1', font_size, 1)
			rl.draw_text_ex(font, '1', rl.Vector2{
				x: rect.x + rect.width / 2 - text_size.x / 2
				y: rect.y + rect.height / 2 - text_size.y / 2 + 1
			}, font_size, 1, fg_color)
		})

		app.mu.end_window()
	}
}
