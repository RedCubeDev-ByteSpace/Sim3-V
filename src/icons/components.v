module icons

import raylib as rl
import data
import fonts

fn generate_component_icons(mut app data.App) {
	app.icons.components.wire_button = draw_icon(mut app, fn (rect rl.Rectangle, mut app data.App, fg_color rl.Color) {
		margin := 5
		rl.draw_line_ex(rl.Vector2{rect.x + margin, rect.y + margin}, rl.Vector2{rect.x + rect.width - margin,
			rect.y + rect.width - margin}, 2, fg_color)
	})

	app.icons.components.bus_button = draw_icon(mut app, fn (rect rl.Rectangle, mut app data.App, fg_color rl.Color) {
		margin := 5
		rl.draw_line_ex(rl.Vector2{rect.x + margin, rect.y + margin}, rl.Vector2{rect.x + rect.width - margin,
			rect.y + rect.width - margin}, 4, fg_color)
	})

	app.icons.components.switch_button = draw_icon(mut app, fn (rect rl.Rectangle, mut app data.App, fg_color rl.Color) {
		margin := 5
		rl.draw_rectangle_lines_ex(rl.Rectangle{
			x:      rect.x + margin
			y:      rect.y + margin
			width:  rect.width - margin * 2
			height: rect.height - margin * 2
		}, 2, fg_color)

		rl.draw_circle(int(rect.x + rect.width / 2), int(rect.y + rect.height / 2), 5,
			fg_color)
	})

	app.icons.components.fixed_contact_button = draw_icon(mut app, fn (rect rl.Rectangle, mut app data.App, fg_color rl.Color) {
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

	app.icons.components.clock_button = draw_icon(mut app, fn (rect rl.Rectangle, mut app data.App, fg_color rl.Color) {
		margin := 5
		rl.draw_rectangle_lines_ex(rl.Rectangle{
			x:      rect.x + margin
			y:      rect.y + margin
			width:  rect.width - margin * 2
			height: rect.height - margin * 2
		}, 2, fg_color)

		rl.draw_rectangle(int(rect.x + rect.width / 2 - margin + 5), int(rect.y + rect.height / 2 - 1),
			int(rect.width / 2 - margin - 3), int(2), fg_color)
	})

	app.icons.components.led_button = draw_icon(mut app, fn (rect rl.Rectangle, mut app data.App, fg_color rl.Color) {
		rl.draw_circle(int(rect.x + rect.width / 2), int(rect.y + rect.height / 2), 5,
			fg_color)

		rl.draw_circle_lines(int(rect.x + rect.width / 2), int(rect.y + rect.height / 2),
			8, fg_color)
		rl.draw_circle_lines(int(rect.x + rect.width / 2), int(rect.y + rect.height / 2),
			8.5, fg_color)
	})

	app.icons.components.chip_button = draw_icon(mut app, fn (rect rl.Rectangle, mut app data.App, fg_color rl.Color) {
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
}

fn draw_icon(mut app data.App, draw fn (rect rl.Rectangle, mut app data.App, fg_color rl.Color)) rl.RenderTexture2D {
	size := 30 // icons are always 25x25 pixels because i said so

	r_texture := rl.load_render_texture(size, size)
	rl.begin_texture_mode(r_texture)

	draw(rl.Rectangle{
		x:      0
		y:      0
		width:  size
		height: size
	}, mut app, rl.Color{0, 0, 0, 255})

	rl.end_texture_mode()

	return r_texture
}
