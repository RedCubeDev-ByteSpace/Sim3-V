module gui

import imgui
import data
import storage
import utils

fn draw_blueprints_window(mut app data.App) {
	hovered_bp := app.bench.placement.current_hovered_blueprint_path
	app.bench.placement.current_hovered_blueprint_path = ''

	margin := 5
	imgui.set_next_window_pos(imgui.ImVec2{margin, 545 + margin}, int(imgui.Cond_.first_use_ever),
		imgui.ImVec2{0, 0})
	imgui.set_next_window_size(imgui.ImVec2{255, 300}, int(imgui.Cond_.first_use_ever))

	if imgui.begin(c'Blueprints', unsafe { nil }, 0) {
		avail_width := imgui.get_content_region_avail().x
		if imgui.button(c'New Blueprint!', imgui.ImVec2{avail_width, 20}) {
			// make sure we have anything selected
			if app.bench.selected_components.len > 0 {
				app.storage.blueprints.gui.new_blueprint_name = 'New Blueprint'
				app.storage.blueprints.gui.new_blueprint_selected_dir = 0
				app.storage.blueprints.gui.is_showing_new_blueprint_dialog = true
				imgui.open_popup_str(c'Create New Blueprint', 0)
			}
		}

		draw_blueprints_dir(mut app, hovered_bp, app.storage.blueprints.blueprint_dir)

		draw_new_blueprint_dialog(mut app)
	}
	imgui.end()
}

fn draw_blueprints_dir_node(mut app data.App, hovered_bp string, dir data.BlueprintDirectory) {
	if imgui.tree_node_str(dir.name.str) {
		draw_blueprints_dir(mut app, hovered_bp, dir)
		imgui.tree_pop()
	}
}

fn draw_blueprints_dir(mut app data.App, hovered_bp string, dir data.BlueprintDirectory) {
	for subdir in dir.blueprint_directories {
		draw_blueprints_dir_node(mut app, hovered_bp, subdir)
	}

	for blueprint in dir.blueprints {
		draw_blueprint_button(mut app, hovered_bp, blueprint)
	}
}

fn draw_blueprint_button(mut app data.App, hovered_bp string, bp data.Blueprint) {
	imgui.set_cursor_pos_x(imgui.get_cursor_pos_x() + 10)
	avail_width := imgui.get_content_region_avail().x
	entry_size := imgui.ImVec2{avail_width, 40}

	imgui.push_style_var_x(int(imgui.StyleVar_.window_padding), 5)
	imgui.push_style_var_y(int(imgui.StyleVar_.window_padding), 5)

	style := imgui.get_style()
	is_hovered := bp.path == hovered_bp
	if is_hovered {
		imgui.push_style_color_vec4(int(imgui.Col_.child_bg), style.Colors[int(imgui.Col_.button_hovered)])
	} else {
		imgui.push_style_color_vec4(int(imgui.Col_.child_bg), style.Colors[int(imgui.Col_.button)])
	}

	if imgui.begin_child_str(bp.path.str, entry_size, int(imgui.ChildFlags_.borders),
		int(imgui.WindowFlags_.no_scrollbar))
	{
		cursor_x := imgui.get_cursor_pos_x()
		cursor_y := imgui.get_cursor_pos_y()

		imgui.text(bp.name.str)

		imgui.set_cursor_pos_x(cursor_x + 1)
		imgui.set_cursor_pos_y(cursor_y)

		imgui.text(bp.name.str)

		imgui.text(bp.date.str)
	}
	imgui.end_child()

	imgui.pop_style_color(1)
	imgui.pop_style_var(2)

	// was it hovered?
	if imgui.is_item_hovered(0) {
		app.bench.placement.current_hovered_blueprint_path = bp.path

		imgui.begin_tooltip()
		imgui.rl_imgui_image(bp.preview)
		imgui.end_tooltip()
	}

	// was it clicked?
	if imgui.is_item_clicked(0) {
		app.bench.selected_components.clear()

		app.bench.blueprints.current_blueprint_cfgs.clear()
		for cfg in bp.components {
			app.bench.blueprints.current_blueprint_cfgs << cfg
		}

		if app.bench.blueprints.current_blueprint_cfgs.len > 0 {
			app.bench.bench_state = .placing_blueprint
		}
	}
}

fn draw_new_blueprint_dialog(mut app data.App) {
	if imgui.begin_popup_modal(c'Create New Blueprint', app.storage.blueprints.gui.is_showing_new_blueprint_dialog,
		int(imgui.WindowFlags_.always_auto_resize) | int(imgui.WindowFlags_.no_saved_settings))
	{
		if imgui.begin_table(c'layout_table', 2, int(imgui.TableFlags_.sizing_fixed_fit),
			imgui.ImVec2{}, 0)
		{
			imgui.table_setup_column(c'label_column', int(imgui.TableColumnFlags_.width_fixed),
				50, unsafe { nil })
			imgui.table_setup_column(c'input_column', int(imgui.TableColumnFlags_.width_fixed),
				200, unsafe { nil })

			imgui.table_next_row(0, 0)
			imgui.table_set_column_index(0)
			imgui.text(c'Name')
			imgui.table_set_column_index(1)

			imgui.set_next_item_width(imgui.get_content_region_avail().x)
			utils.gui_load_buffer(mut app, app.storage.blueprints.gui.new_blueprint_name)
			imgui.input_text(c'##name_input', &app.gui.input_buffer[0], usize(app.gui.input_buffer.len),
				0, unsafe { nil }, unsafe { nil })
			app.storage.blueprints.gui.new_blueprint_name = utils.gui_read_buffer(mut app)

			imgui.table_next_row(0, 0)
			imgui.table_set_column_index(0)
			imgui.text(c'Directory')
			imgui.table_set_column_index(1)

			imgui.set_next_item_width(imgui.get_content_region_avail().x)
			if imgui.begin_combo(c'folder_combo', app.storage.blueprints.blueprint_dir_paths[app.storage.blueprints.gui.new_blueprint_selected_dir].str,
				0)
			{
				for i, dir in app.storage.blueprints.blueprint_dir_paths {
					is_selected := app.storage.blueprints.gui.new_blueprint_selected_dir == i

					if imgui.selectable_bool(dir.str, is_selected, 0, imgui.ImVec2{}) {
						app.storage.blueprints.gui.new_blueprint_selected_dir = i
					}

					if is_selected {
						imgui.set_item_default_focus()
					}
				}

				imgui.end_combo()
			}

			imgui.end_table()
		}

		if imgui.button(c'Create!', imgui.ImVec2{}) {
			app.storage.blueprints.gui.is_showing_new_blueprint_dialog = false

			storage.create_blueprint_from_selected_components(mut app, app.storage.blueprints.gui.new_blueprint_name,
				app.storage.blueprints.blueprint_dir_paths[app.storage.blueprints.gui.new_blueprint_selected_dir])
		}

		imgui.end_popup()
	}
}
