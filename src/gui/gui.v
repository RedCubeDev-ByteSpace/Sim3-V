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
	draw_chip_select_window(mut app)
	draw_blueprints_windows(mut app)

	for mut comp in app.sim.components.values() {
		comp.draw_component_window(mut app)
	}

	app.mu.end()
	app.mu.render()
}

fn draw_debug_window(mut app data.App) {
	if app.mu.begin_window_ex('Debug Window', rl.Rectangle{0, 0, 250, 260}, .noclose) {
		app.mu.layout_row([-1], 12)

		camera_pos := app.view.camera_position.add(app.view.camera_offset.div_scalar(app.view.zoom * data.one_simspace_unit_in_px))
		app.mu.label('FPS: ${rl.get_fps()}')
		app.mu.label('MUi Input Capture: ${if app.mu.wants_input_capture() { 'yes' } else { 'no' }}')
		app.mu.label('Bench state: ${match app.bench.bench_state {
			.idle { 'idle' }
			.moving_view { 'moving_view' }
			.selecting { 'selecting' }
			.moving_components { 'moving_components' }
			.moving_wire { 'moving_wire' }
			.placing_component { 'placing_component' }
			.pasting_components { 'pasting_component' }
			.placing_blueprint { 'placing_blueprint' }
		}}')
		app.mu.label('Camera: ${camera_pos.x:.2f}, ${camera_pos.y:.2f}')
		app.mu.label('Mouse: ${app.input.mouse_pos.x:.0}, ${app.input.mouse_pos.y:.0}')
		app.mu.label('Zoom: ${app.view.zoom}')
		app.mu.label('Zoom%: ${if app.view.zoom >= 1 {
			math.log(app.view.zoom) / math.log(12)
		} else {
			0
		}:.2}')
		app.mu.label('Rotation: ${match app.bench.placement.rotation {
			.left { 'left' }
			.up { 'up' }
			.right { 'right' }
			.down { 'down' }
		}}')

		app.mu.layout_row([-1], 2)
		app.mu.layout_next()
		app.mu.layout_row([1, -1], 0)
		app.mu.layout_next()
		app.mu.checkbox('Draw AABBs', app.view.debug.show_aabb)

		app.mu.layout_next()
		app.mu.checkbox('Draw Contact Points', app.view.debug.show_contacts)

		app.mu.layout_next()
		app.mu.checkbox('Only Draw LEDs', app.view.debug.draw_only_led)

		app.mu.layout_row([130, -1], 0)
		app.mu.label('Sim-Steps per Frame')
		app.mu.slider_ex(app.sim.steps_per_frame, 1, 50, 1, '%.0f', 0)

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
				app.bench.placement.current_selected_color_idx = i
			}

			if i == app.bench.placement.current_selected_color_idx {
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
	if app.mu.begin_window_ex('Components', rl.Rectangle{10, 80, 250, 65}, .noclose | .noresize | .noscroll) {
		app.mu.layout_row([30, 30, 30, 30, 30, 30, 30], 30)

		style := app.mu.get_style()
		border_color := style.colors[microui.Color.border]
		hover_color := style.colors[microui.Color.basehover]
		focus_color := style.colors[microui.Color.basefocus]
		bg_color := style.colors[microui.Color.base]
		fg_color := style.colors[microui.Color.text]

		// -------------------------------------------------------------------------------------------------------------
		// Wire button
		draw_component_button(mut app, .wire, fg_color, bg_color, focus_color, hover_color,
			border_color, fn (rect rl.Rectangle, mut app data.App, fg_color rl.Color, bg_color rl.Color, border_color rl.Color) {
				rl.draw_rectangle(int(rect.x), int(rect.y), int(rect.width), int(rect.height),
					bg_color)
				rl.draw_rectangle_lines_ex(rect, 1, border_color)

				margin := 5
				rl.draw_line_ex(rl.Vector2{rect.x + margin, rect.y + margin}, rl.Vector2{rect.x +
					rect.width - margin, rect.y + rect.width - margin}, 2, fg_color)
			})

		// -------------------------------------------------------------------------------------------------------------
		// Bus button
		draw_component_button(mut app, .bus, fg_color, bg_color, focus_color, hover_color,
			border_color, fn (rect rl.Rectangle, mut app data.App, fg_color rl.Color, bg_color rl.Color, border_color rl.Color) {
				rl.draw_rectangle(int(rect.x), int(rect.y), int(rect.width), int(rect.height),
					bg_color)
				rl.draw_rectangle_lines_ex(rect, 1, border_color)

				margin := 5
				rl.draw_line_ex(rl.Vector2{rect.x + margin, rect.y + margin}, rl.Vector2{rect.x +
					rect.width - margin, rect.y + rect.width - margin}, 4, fg_color)
			})

		// -------------------------------------------------------------------------------------------------------------
		// Switch component button
		draw_component_button(mut app, .switch, fg_color, bg_color, focus_color, hover_color,
			border_color, fn (rect rl.Rectangle, mut app data.App, fg_color rl.Color, bg_color rl.Color, border_color rl.Color) {
				rl.draw_rectangle(int(rect.x), int(rect.y), int(rect.width), int(rect.height),
					bg_color)
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
		draw_component_button(mut app, .fixed_contact, fg_color, bg_color, focus_color,
			hover_color, border_color, fn (rect rl.Rectangle, mut app data.App, fg_color rl.Color, bg_color rl.Color, border_color rl.Color) {
				rl.draw_rectangle(int(rect.x), int(rect.y), int(rect.width), int(rect.height),
					bg_color)
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

		// -------------------------------------------------------------------------------------------------------------
		// Clock component button
		draw_component_button(mut app, .clock, fg_color, bg_color, focus_color, hover_color,
			border_color, fn (rect rl.Rectangle, mut app data.App, fg_color rl.Color, bg_color rl.Color, border_color rl.Color) {
				rl.draw_rectangle(int(rect.x), int(rect.y), int(rect.width), int(rect.height),
					bg_color)
				rl.draw_rectangle_lines_ex(rect, 1, border_color)

				margin := 5
				rl.draw_rectangle_lines_ex(rl.Rectangle{
					x:      rect.x + margin
					y:      rect.y + margin
					width:  rect.width - margin * 2
					height: rect.height - margin * 2
				}, 2, fg_color)

				rl.draw_rectangle(int(rect.x + rect.width / 2 - margin + 5), int(rect.y +
					rect.height / 2 - 1), int(rect.width / 2 - margin - 3), int(2), fg_color)
			})

		// -------------------------------------------------------------------------------------------------------------
		// LED component button
		draw_component_button(mut app, .led, fg_color, bg_color, focus_color, hover_color,
			border_color, fn (rect rl.Rectangle, mut app data.App, fg_color rl.Color, bg_color rl.Color, border_color rl.Color) {
				rl.draw_rectangle(int(rect.x), int(rect.y), int(rect.width), int(rect.height),
					bg_color)
				rl.draw_rectangle_lines_ex(rect, 1, border_color)

				rl.draw_circle(int(rect.x + rect.width / 2), int(rect.y + rect.height / 2),
					5, fg_color)

				rl.draw_circle_lines(int(rect.x + rect.width / 2), int(rect.y + rect.height / 2),
					8, fg_color)
				rl.draw_circle_lines(int(rect.x + rect.width / 2), int(rect.y + rect.height / 2),
					8.5, fg_color)
			})

		// -------------------------------------------------------------------------------------------------------------
		// Chip component button
		draw_component_button(mut app, .chip, fg_color, bg_color, focus_color, hover_color,
			border_color, fn (rect rl.Rectangle, mut app data.App, fg_color rl.Color, bg_color rl.Color, border_color rl.Color) {
				rl.draw_rectangle(int(rect.x), int(rect.y), int(rect.width), int(rect.height),
					bg_color)
				rl.draw_rectangle_lines_ex(rect, 1, border_color)

				width := 10
				height := 15
				chip_box := rl.Rectangle{
					x:      rect.x + rect.width / 2 - width / 2
					y:      rect.y + rect.height / 2 - height / 2
					width:  width
					height: height
				}
				rl.draw_rectangle_lines_ex(chip_box, 1.7, fg_color)

				margin := 7
				num_leg_rows := 3
				leg_space_height := 12
				leg_spacing := leg_space_height / num_leg_rows
				start_y := rect.y + rect.height / 2 - 4
				for i in 0 .. num_leg_rows {
					y := int(start_y + leg_spacing * i)
					rl.draw_line(int(rect.x + margin), y, int(chip_box.x), y, fg_color)
					rl.draw_line(int(chip_box.x + chip_box.width), y, int(rect.x + rect.width - margin),
						y, fg_color)
				}
			})

		app.mu.end_window()
	}
}

fn draw_component_button(mut app data.App, comp_type data.SelectedComponentType, fg_color rl.Color, bg_color rl.Color, focus_color rl.Color, hover_color rl.Color, border_color rl.Color, draw fn (rect rl.Rectangle, mut app data.App, fg_color rl.Color, bg_color rl.Color, border_color rl.Color)) {
	// determine the background color for this button
	rect := app.mu.layout_next()
	mut bg := bg_color
	if app.bench.placement.current_selected_component_type == comp_type {
		bg = focus_color
	} else if app.mu.mouse_over(rect) {
		bg = hover_color
	}

	// when clicked: toggle this component being selected
	if app.mu.mouse_over(rect) && app.mu.is_mouse_pressed(.left) {
		utils.toggle_component_placement(mut app, comp_type)
	}

	// draw the button
	app.mu.draw_custom(rect, app, fn [fg_color, bg, border_color, draw] (rect rl.Rectangle, mut app data.App) {
		draw(rect, mut app, fg_color, bg, border_color)
	})
}

fn draw_chip_select_window(mut app data.App) {
	if app.mu.begin_window_ex('Chips', rl.Rectangle{10, 150, 260, 400}, .noclose) {
		for group_name, chip_uids in app.catalog.groups {
			if app.mu.header(group_name) {
				app.mu.layout_row([10, -1], 40)

				for chip_uid in chip_uids {
					app.mu.layout_next()
					if draw_chip_button(mut app, chip_uid) {
						app.bench.placement.current_selected_chip_uid = chip_uid

						if app.bench.placement.current_selected_component_type != .chip {
							utils.toggle_component_placement(mut app, .chip)
						}
					}
				}
			}
		}

		app.mu.end_window()
	}
}

fn draw_chip_button(mut app data.App, chip_uid string) bool {
	chip := app.catalog.chips[chip_uid]
	rect := app.mu.layout_next()
	id := app.mu.get_id(chip_uid)
	mut clicked := false

	app.mu.update_control(id, rect, 0)
	if app.mu.is_mouse_pressed(.left) && app.mu.get_focus_id() == id {
		clicked = true
	}

	color := if chip.unique_id == app.bench.placement.current_selected_chip_uid {
		microui.Color.buttonfocus
	} else {
		microui.Color.button
	}
	app.mu.draw_control_frame(id, rect, color, 0)

	top_rect := rl.Rectangle{
		...rect
		y:      rect.y + 3
		height: rect.height / 2
	}
	top_rect_faux_bold := rl.Rectangle{
		...top_rect
		x: rect.x + 1
	}
	bottom_rect := rl.Rectangle{
		...rect
		y:      rect.y + rect.height / 2
		height: rect.height / 2
	}
	app.mu.draw_control_text(chip.name, top_rect, .text, 0)
	app.mu.draw_control_text(chip.name, top_rect_faux_bold, .text, 0)
	app.mu.draw_control_text(chip.description, bottom_rect, .text, 0)

	return clicked
}
