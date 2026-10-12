module gui

import raylib as rl
import data
import imgui
import utils

fn draw_component_choice_window(mut app data.App) {
	margin := 5
	imgui.set_next_window_pos(imgui.ImVec2{margin, 70 + margin}, int(imgui.Cond_.first_use_ever),
		imgui.ImVec2{0, 0})

	if imgui.begin(c'Components', unsafe { nil }, int(imgui.WindowFlags_.no_resize) | int(imgui.WindowFlags_.always_auto_resize)) {
		imgui.push_style_var_x(int(imgui.StyleVar_.frame_padding), 0)
		imgui.push_style_var_y(int(imgui.StyleVar_.frame_padding), 0)

		draw_component_button(mut app, 'wire_button', .wire, app.icons.components.wire_button)
		draw_component_button(mut app, 'bus_button', .bus, app.icons.components.bus_button)
		draw_component_button(mut app, 'switch_button', .switch, app.icons.components.switch_button)
		draw_component_button(mut app, 'fixed_contact_button', .fixed_contact, app.icons.components.fixed_contact_button)
		draw_component_button(mut app, 'clock_button', .clock, app.icons.components.clock_button)
		draw_component_button(mut app, 'led_button', .led, app.icons.components.led_button)
		draw_component_button(mut app, 'chip_button', .chip, app.icons.components.chip_button)

		imgui.pop_style_var(2)
	}
	imgui.end()
}

fn draw_component_button(mut app data.App, id string, comp_type data.SelectedComponentType, texture rl.RenderTexture2D) {
	texture_ref := imgui.ImTextureRef{
		_TexID: texture.texture.id
	}

	size := imgui.ImVec2{30, 30}
	uv0 := imgui.ImVec2{0, 1}
	uv1 := imgui.ImVec2{1, 0}
	bg_color := imgui.ImVec4{0, 0, 0, 0}
	tint_color := imgui.ImVec4{1, 1, 1, 1}

	is_selected := app.bench.placement.current_selected_component_type == comp_type
	if is_selected {
		imgui.push_style_color_vec4(int(imgui.Col_.border), imgui.ImVec4{0, 0, 0, 1})
		imgui.push_style_var_float(int(imgui.StyleVar_.frame_border_size), 1.5)
	}

	if imgui.image_button(id.str, texture_ref, size, uv0, uv1, bg_color, tint_color) {
		utils.toggle_component_placement(mut app, comp_type)
	}

	if is_selected {
		imgui.pop_style_color(1)
		imgui.pop_style_var(1)
	}

	imgui.same_line(0, 5)
}
