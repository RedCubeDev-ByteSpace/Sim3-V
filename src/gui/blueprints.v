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
	app.mu.layout_row([-1], data.blueprint_preview_size)
	for blueprint in dir.blueprints {
		if draw_blueprint_button(mut app, blueprint) {
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

fn draw_blueprint_button(mut app data.App, bp data.Blueprint) bool {
	rect := app.mu.layout_next()
	id := app.mu.get_id(bp.path)
	mut clicked := false

	app.mu.update_control(id, rect, 0)
	if app.mu.is_mouse_pressed(.left) && app.mu.get_focus_id() == id {
		clicked = true
	}

	app.mu.draw_control_frame(id, rect, .button, 0)

	preview_size := data.blueprint_preview_size

	top_rect := rl.Rectangle{
		...rect
		x:      rect.x + preview_size
		y:      rect.y + 3
		height: rect.height / 3
	}
	top_rect_faux_bold := rl.Rectangle{
		...top_rect
		x: top_rect.x + 1
	}
	bottom_rect := rl.Rectangle{
		...top_rect
		y: top_rect.y + top_rect.height - 4
	}
	app.mu.draw_control_text(bp.name, top_rect, .text, 0)
	app.mu.draw_control_text(bp.name, top_rect_faux_bold, .text, 0)
	app.mu.draw_control_text(bp.date, bottom_rect, .text, 0)

	// draw preview
	preview_rect := rl.Rectangle{
		x:      rect.x + 2
		y:      rect.y + 2
		width:  preview_size - 4
		height: preview_size - 4
	}

	texture := bp.preview
	app.mu.set_clip(app.mu.get_current_container_body())
	app.mu.draw_custom(preview_rect, app, fn [texture] (rect rl.Rectangle, _ voidptr) {
		mut dest_rect := rl.Rectangle{0, 0, texture.width, texture.height}

		if dest_rect.width > dest_rect.height {
			if dest_rect.width > rect.width {
				dest_rect = rl.Rectangle{
					...dest_rect
					width:  rect.width
					height: rect.width * (dest_rect.height / dest_rect.width)
				}
			}
		} else {
			if dest_rect.height > rect.height {
				dest_rect = rl.Rectangle{
					...dest_rect
					width:  rect.height * (dest_rect.width / dest_rect.height)
					height: rect.height
				}
			}
		}

		rl.draw_texture_pro(texture, rl.Rectangle{0, 0, texture.width, -texture.height},
			rl.Rectangle{
				...dest_rect
				x: rect.x + (rect.width - dest_rect.width) / 2
				y: rect.y + (rect.height - dest_rect.height) / 2
			}, rl.Vector2{0, 0}, 0, rl.white)
	})
	app.mu.unset_clip()

	return clicked
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
