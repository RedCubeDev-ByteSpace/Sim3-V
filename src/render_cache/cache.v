module render_cache

import data
import raylib as rl

pub fn has_cache(app data.App, key string) bool {
	return key in app.renderers.cache
}

pub fn begin_cache(app data.App, width int, height int) rl.RenderTexture2D {
	r_texture := rl.load_render_texture(width + data.render_cache_margin_px * 2, height +
		data.render_cache_margin_px * 2)

	rl.set_texture_filter(r_texture.texture, int(rl.TextureFilter.texture_filter_anisotropic_4x))
	rl.set_texture_wrap(r_texture.texture, int(rl.TextureWrap.texture_wrap_clamp))

	rl.begin_texture_mode(r_texture)
	rl.clear_background(rl.Color{0, 0, 0, 0})
	return r_texture
}

pub fn end_cache(mut app data.App, key string, r_texture rl.RenderTexture2D) {
	rl.end_texture_mode()
	app.renderers.cache[key] = r_texture
}

pub fn draw_from_cache(app data.App, key string, render_rect rl.Rectangle, opacity f32) {
	// get the texture from the cache map
	r_texture := app.renderers.cache[key]

	// draw it!
	rl.draw_texture_pro(r_texture.texture, rl.Rectangle{
		x:      0
		y:      0
		width:  r_texture.texture.width
		height: -r_texture.texture.height
	}, rl.Rectangle{
		x:      render_rect.x - data.render_cache_margin_px
		y:      render_rect.y - data.render_cache_margin_px
		width:  render_rect.width + data.render_cache_margin_px * 2
		height: render_rect.height + data.render_cache_margin_px * 2
	}, rl.Vector2{0, 0}, 0, rl.Color{
		r: 255
		g: 255
		b: 255
		a: u8(255 * opacity)
	})
}
