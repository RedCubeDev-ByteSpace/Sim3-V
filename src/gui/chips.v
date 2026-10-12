module gui

import data
import imgui
import utils

fn draw_chip_select_window(mut app data.App) {
	hovered_chip := app.bench.placement.current_hovered_chip_uid
	app.bench.placement.current_hovered_chip_uid = ''

	margin := 5
	imgui.set_next_window_pos(imgui.ImVec2{margin, 140 + margin}, int(imgui.Cond_.first_use_ever),
		imgui.ImVec2{0, 0})
	imgui.set_next_window_size(imgui.ImVec2{255, 400}, int(imgui.Cond_.first_use_ever))

	if imgui.begin(c'Chips', unsafe { nil }, 0) {
		for group_name, chip_uids in app.catalog.groups {
			if imgui.collapsing_header_bool_ptr(group_name.str, unsafe { nil }, 0) {
				for chip_uid in chip_uids {
					draw_chip_button(mut app, hovered_chip, chip_uid)
				}
			}
		}
	}
	imgui.end()
}

fn draw_chip_button(mut app data.App, hovered_chip string, chip_uid string) {
	chip := app.catalog.chips[chip_uid]

	imgui.set_cursor_pos_x(imgui.get_cursor_pos_x() + 10)
	avail_width := imgui.get_content_region_avail().x
	entry_size := imgui.ImVec2{avail_width, 40}

	imgui.push_style_var_x(int(imgui.StyleVar_.window_padding), 5)
	imgui.push_style_var_y(int(imgui.StyleVar_.window_padding), 5)

	style := imgui.get_style()

	is_hovered := chip_uid == hovered_chip
	is_selected := app.bench.placement.current_selected_chip_uid == chip_uid
	if is_hovered || is_selected {
		imgui.push_style_color_vec4(int(imgui.Col_.child_bg), style.Colors[int(imgui.Col_.button_hovered)])
	} else {
		imgui.push_style_color_vec4(int(imgui.Col_.child_bg), style.Colors[int(imgui.Col_.button)])
	}

	if imgui.begin_child_str(chip_uid.str, entry_size, int(imgui.ChildFlags_.borders),
		int(imgui.WindowFlags_.no_scrollbar))
	{
		cursor_x := imgui.get_cursor_pos_x()
		cursor_y := imgui.get_cursor_pos_y()

		imgui.text(chip.name.str)

		imgui.set_cursor_pos_x(cursor_x + 1)
		imgui.set_cursor_pos_y(cursor_y)

		imgui.text(chip.name.str)

		imgui.text(chip.description.str)
	}
	imgui.end_child()

	imgui.pop_style_color(1)
	imgui.pop_style_var(2)

	// was it hovered?
	if imgui.is_item_hovered(0) {
		app.bench.placement.current_hovered_chip_uid = chip_uid
	}

	// was it clicked?
	if imgui.is_item_clicked(0) {
		app.bench.placement.current_selected_chip_uid = chip_uid

		if app.bench.placement.current_selected_component_type != .chip {
			utils.toggle_component_placement(mut app, .chip)
		}
	}
}
