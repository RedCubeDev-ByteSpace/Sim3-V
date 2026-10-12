module gui

import data
import imgui

pub fn draw_ui(mut app data.App) {
	imgui.rl_imgui_begin()
	imgui.push_font(app.fonts.imgui_font, 13)

	draw_debug_window(mut app)
	draw_color_window(mut app)
	draw_component_choice_window(mut app)
	draw_chip_select_window(mut app)
	draw_blueprints_window(mut app)

	for mut comp in app.sim.components.data {
		comp.draw_component_window(mut app)
	}

	imgui.pop_font()
	imgui.rl_imgui_end()
}
