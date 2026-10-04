module fonts

import data
import microui
import raylib as rl

pub fn init(mut app data.App) {
	// load different sizes of Computer Modern
	sizes := [3, 5, 8, 10, 12, 15, 16, 20, 30, 40, 50, 100, 150, 170]

	for size in sizes {
		sized_font := microui.SizedFont{
			font: rl.load_font_ex('./src/res/cmunbx.ttf', size, unsafe { nil }, 0)
			size: size
		}

		rl.set_texture_filter(sized_font.font.texture, int(rl.TextureFilter.texture_filter_trilinear))

		app.fonts.fonts << sized_font
	}
}

pub fn get_font_for_size(app data.App, size int) rl.Font {
	// is the requested size smaller than any font we have?
	// -> return the smallest
	if size < app.fonts.fonts[0].size {
		return app.fonts.fonts[0].font
	}

	// otherwise: fond a font that fits
	for i, font in app.fonts.fonts {
		if font.size > size {
			return app.fonts.fonts[i].font
		}
	}

	return app.fonts.fonts[app.fonts.fonts.len - 1].font
}

pub fn recalculate_font_choices(mut app data.App) {
	// only recalculate when the zoom changed
	if app.view.zoom == app.fonts.last_zoom {
		return
	}
	app.fonts.last_zoom = app.view.zoom

	zoomed_unit := app.view.zoom * data.one_simspace_unit_in_px

	// chip label font
	app.fonts.chip_label_font_size = zoomed_unit
	app.fonts.chip_label_font = get_font_for_size(app, int(zoomed_unit))

	// pin label font
	app.fonts.chip_pin_label_font_size = zoomed_unit * 0.25
	app.fonts.chip_pin_label_font = get_font_for_size(app, int(zoomed_unit * 0.25))

	// fixed contact label font
	app.fonts.fixed_contact_label_font_size = zoomed_unit * 0.75
	app.fonts.fixed_contact_label_font = get_font_for_size(app, int(zoomed_unit * 0.75))
}
