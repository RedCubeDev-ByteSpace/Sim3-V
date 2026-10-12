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

	// imgui.show_demo_window(unsafe { nil })

	imgui.pop_font()
	imgui.rl_imgui_end()
}
