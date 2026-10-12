module gui

import data
import imgui

fn draw_color_window(mut app data.App) {
	margin := 5
	imgui.set_next_window_pos(imgui.ImVec2{margin, margin}, int(imgui.Cond_.first_use_ever),
		imgui.ImVec2{0, 0})

	if imgui.begin(c'Colors', unsafe { nil }, int(imgui.WindowFlags_.no_resize) | int(imgui.WindowFlags_.always_auto_resize)) {
		for i, color in data.wire_colors {
			// highlight the selected color
			is_selected := app.bench.placement.current_selected_color_idx == i
			if is_selected {
				imgui.push_style_color_vec4(int(imgui.Col_.border), imgui.ImVec4{0, 0, 0, 1})
				imgui.push_style_var_float(int(imgui.StyleVar_.frame_border_size), 1.5)
			}

			if imgui.color_button('##color_${i}'.str, imgui.ImVec4{
				x: f32(color.r) / 255.0
				y: f32(color.g) / 255.0
				z: f32(color.b) / 255.0
				w: f32(color.a) / 255.0
			}, int(imgui.ColorEditFlags_.no_tooltip), imgui.ImVec2{30, 30})
			{
				app.bench.placement.current_selected_color_idx = i
			}

			if is_selected {
				imgui.pop_style_color(1)
				imgui.pop_style_var(1)
			}

			imgui.same_line(0, 5)
		}
	}
	imgui.end()
}
