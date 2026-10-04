module gui

import raylib as rl
import data
import storage

fn draw_blueprints_windows(mut app data.App) {
	draw_blueprints_window(mut app)
	draw_new_blueprint_dialog(mut app)
}

fn draw_blueprints_window(mut app data.App) {
	if app.mu.begin_window_ex('Blueprints', rl.Rectangle{10, 555, 260, 300}, .noclose) {
		app.mu.layout_row([-1], 0)

		if app.mu.button('Create New Blueprint') {
			// open the new blueprint dialog in the center of the screen
			if app.bench.selected_components.len > 0 {
				app.storage.blueprints.gui.new_blueprint_name = 'New Blueprint'

				app.storage.blueprints.gui.is_showing_new_blueprint_dialog = true
				app.storage.blueprints.gui.has_set_dialog_size = false
			}
		}

		draw_blueprints_dir(mut app, app.storage.blueprints.blueprint_dir)

		app.mu.end_window()
	}
}

fn draw_blueprints_dir_node(mut app data.App, dir data.BlueprintDirectory) {
	if app.mu.begin_treenode(dir.name) {
		draw_blueprints_dir(mut app, dir)
		app.mu.end_treenode()
	}
}

fn draw_blueprints_dir(mut app data.App, dir data.BlueprintDirectory) {
	app.mu.layout_row([-1], 0)
	for blueprint in dir.blueprints {
		if app.mu.button(blueprint.name) {
			app.bench.selected_components.clear()

			app.bench.blueprints.current_blueprint_cfgs.clear()
			for cfg in blueprint.components {
				app.bench.blueprints.current_blueprint_cfgs << cfg
			}

			if app.bench.blueprints.current_blueprint_cfgs.len > 0 {
				app.bench.bench_state = .placing_blueprint
			}
		}
	}

	for subdir in dir.blueprint_directories {
		draw_blueprints_dir_node(mut app, subdir)
	}
}

fn draw_new_blueprint_dialog(mut app data.App) {
	screen_width := rl.get_screen_width()
	screen_height := rl.get_screen_height()

	dialog_width := 330
	dialog_height := 130

	if app.mu.begin_window_bool_controlled('Create New Blueprint', rl.Rectangle{100, 100, 100, 100},
		app.storage.blueprints.gui.is_showing_new_blueprint_dialog)
	{
		if !app.storage.blueprints.gui.has_set_dialog_size {
			app.mu.set_current_container_rect(rl.Rectangle{
				x:      screen_width / 2 - dialog_width / 2
				y:      screen_height / 2 - dialog_height / 2
				width:  dialog_width
				height: dialog_height
			})

			app.storage.blueprints.gui.has_set_dialog_size = true
		}

		app.mu.layout_row([-1], 0)
		app.mu.label('Create a blueprint out of the ${app.bench.selected_components.len} selected components?')

		app.mu.layout_row([50, -1], 0)
		app.mu.label('Name')
		app.mu.textbox(app.storage.blueprints.gui.new_blueprint_name)

		app.mu.label('Path')
		app.mu.textbox(app.storage.blueprints.gui.new_blueprint_path)

		app.mu.layout_row([-60, -1], 0)
		app.mu.layout_next()
		if app.mu.button('Create') {
			app.storage.blueprints.gui.is_showing_new_blueprint_dialog = false

			storage.create_blueprint_from_selected_components(mut app, app.storage.blueprints.gui.new_blueprint_name,
				app.storage.blueprints.gui.new_blueprint_path)
		}

		if app.storage.blueprints.gui.is_showing_new_blueprint_dialog {
			app.mu.end_window_bool_controlled(app.storage.blueprints.gui.is_showing_new_blueprint_dialog)
		} else {
			app.mu.end_window()
		}
	}
}
