module fonts

import data
import microui
import raylib as rl

pub fn init(mut app data.App) {
	// load different sizes of Computer Modern
	sizes := [5, 10, 15, 20, 30, 40, 50, 100, 150, 170]

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
			return app.fonts.fonts[i - 1].font
		}
	}

	return app.fonts.fonts[app.fonts.fonts.len - 1].font
}
