module utils

import data
import imgui

pub fn gui_load_buffer(mut app data.App, text string) {
	mut limited_text := text
	if limited_text.len > app.gui.input_buffer.len - 2 {
		limited_text = limited_text.substr(0, app.gui.input_buffer.len - 2)
	}

	bytes := limited_text.bytes()
	for i, byte in bytes {
		app.gui.input_buffer[i] = byte
	}

	app.gui.input_buffer[app.gui.input_buffer.len - 1] = 0
}

pub fn gui_read_buffer(mut app data.App) string {
	return unsafe { cstring_to_vstring(&app.gui.input_buffer[0]) }
}

pub fn gui_begin_component_window(comp data.IComponent, comp_type string, is_open &bool) bool {
	comp_handle := comp.get_handle()
	return imgui.begin('${comp_type} (${comp_handle.id}:${comp_handle.gen})'.str, is_open,
		int(imgui.WindowFlags_.always_auto_resize) | int(imgui.WindowFlags_.no_resize))
}

pub fn gui_begin_comp_layout_table(label_width int, input_width int) bool {
	table_open := imgui.begin_table(c'layout_table', 2, int(imgui.TableFlags_.sizing_fixed_fit),
		imgui.ImVec2{}, 0)

	if table_open {
		imgui.table_setup_column(c'label_column', int(imgui.TableColumnFlags_.width_fixed),
			label_width, unsafe { nil })
		imgui.table_setup_column(c'input_column', int(imgui.TableColumnFlags_.width_fixed),
			input_width, unsafe { nil })
	}

	return table_open
}

pub fn gui_do_label(label string) {
	imgui.align_text_to_frame_padding()
	imgui.text(label.str)
}

pub fn gui_do_text_input(mut app data.App, label string, orig_string string) string {
	imgui.set_next_item_width(imgui.get_content_region_avail().x)
	gui_load_buffer(mut app, orig_string)
	imgui.input_text(label.str, &app.gui.input_buffer[0], usize(app.gui.input_buffer.len),
		0, unsafe { nil }, unsafe { nil })
	return gui_read_buffer(mut app)
}
