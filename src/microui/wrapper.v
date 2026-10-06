module microui

import microui.c
import raylib as rl
import math.vec

// -----------------------------------------------------------------------------
// wrapped microui context struct

@[heap]
pub struct Context {
mut:
	mu                &C.mu_Context = unsafe { nil }
	icon_atlas        rl.Texture2D
	font_wrapper      &SizedFont = unsafe { nil }
	input_buffer      &char      = unsafe { nil }
	input_buffer_size i32
}

pub type MuId = u32

pub struct Style {
pub mut:
	font           SizedFont
	size           vec.Vec2[int]
	padding        int
	spacing        int
	indent         int
	title_height   int
	scrollbar_size int
	thumb_size     int
	colors         [14]rl.Color
}

pub struct SizedFont {
pub mut:
	font rl.Font
	size int
}

struct KeyMap {
	rl_key rl.KeyboardKey
	mu_key int
}

const key_mappings = [
	KeyMap{rl.KeyboardKey.key_left_shift, c.mu_key_shift},
	KeyMap{rl.KeyboardKey.key_right_shift, c.mu_key_shift},
	KeyMap{rl.KeyboardKey.key_left_control, c.mu_key_ctrl},
	KeyMap{rl.KeyboardKey.key_right_control, c.mu_key_ctrl},
	KeyMap{rl.KeyboardKey.key_left_alt, c.mu_key_alt},
	KeyMap{rl.KeyboardKey.key_right_alt, c.mu_key_alt},
	KeyMap{rl.KeyboardKey.key_backspace, c.mu_key_backspace},
	KeyMap{rl.KeyboardKey.key_enter, c.mu_key_return},
	KeyMap{rl.KeyboardKey.key_kp_enter, c.mu_key_return},
]

type CustomDrawFunuctionInternal = fn (rect C.mu_fRect, user_data voidptr)

type CustomDrawFunuctionExternal = fn (rect rl.Rectangle, user_data voidptr)

@[params]
pub struct MicroUIConfig {
	input_buffer_size int = 100
}

// -----------------------------------------------------------------------------
pub fn new_context(cfg MicroUIConfig) &Context {
	mut ctx := &Context{
		// allocate a new buffer for the microui context object
		mu: unsafe { &C.mu_Context(C.malloc(sizeof(C.mu_Context))) }

		// create a new font wrapper with a raylib font
		// this object will be passed into the text measuring functions
		font_wrapper: unsafe { &SizedFont(C.malloc(sizeof(SizedFont))) }

		// create a new input buffer for input fields
		input_buffer:      unsafe { C.malloc(cfg.input_buffer_size) }
		input_buffer_size: cfg.input_buffer_size
	}

	C.mu_init(ctx.mu)

	// store a reference to this context inside the font attribute
	// -> again, for the text measuring functions
	ctx.mu.style.font = ctx.font_wrapper
	ctx.font_wrapper.font = rl.get_font_default()
	ctx.font_wrapper.size = 10

	// -------------------------------------------------------------------------
	// hook up the text measuring functions
	ctx.mu.text_height = measure_text_height
	ctx.mu.text_width = measure_text_width

	// -------------------------------------------------------------------------
	// create texture atlas for all microui icons from the blob in atlas.inl
	ctx.load_icon_atlas()

	// -------------------------------------------------------------------------
	// return the new context back to the user
	return ctx
}

fn measure_text_height(ref voidptr) i32 {
	// unpack the reference to our font wrapper object
	font_wrapper := unsafe { &SizedFont(ref) }

	// simple return the current font size as the text height
	return font_wrapper.size
}

fn measure_text_width(ref voidptr, const_str &char, len i32) i32 {
	if const_str == unsafe { nil } {
		return 0
	}

	// unpack the reference to our font wrapper object
	font_wrapper := unsafe { &SizedFont(ref) }

	// load the cstring into a v string
	v_str := unsafe { cstring_to_vstring(const_str) }
	measure_str := if len < 0 || v_str.len == 0 {
		v_str
	} else {
		v_str[0..len]
	}

	// measure!
	size := rl.measure_text_ex(font_wrapper.font, measure_str, font_wrapper.size, 1)

	return i32(size.x)
}

fn (mut ctx Context) load_icon_atlas() {
	img := rl.load_image_from_memory('.png', &atlas_texture[0], atlas_texture.len)
	ctx.icon_atlas = rl.load_texture_from_image(img)
	rl.set_texture_filter(ctx.icon_atlas, int(rl.TextureFilter.texture_filter_point))
}

pub fn (mut ctx Context) get_context() &C.mu_Context {
	return ctx.mu
}

// -----------------------------------------------------------------------------
pub fn (mut ctx Context) get_style() Style {
	mut style := Style{
		font:           ctx.font_wrapper
		size:           vec.Vec2[int]{
			x: ctx.mu.style.size.x
			y: ctx.mu.style.size.y
		}
		padding:        ctx.mu.style.padding
		spacing:        ctx.mu.style.spacing
		indent:         ctx.mu.style.indent
		title_height:   ctx.mu.style.title_height
		scrollbar_size: ctx.mu.style.scrollbar_size
		thumb_size:     ctx.mu.style.thumb_size
	}

	for i in 0 .. mu_color_max {
		style.colors[i] = rl.Color{
			r: ctx.mu.style.colors[i].r
			g: ctx.mu.style.colors[i].g
			b: ctx.mu.style.colors[i].b
			a: ctx.mu.style.colors[i].a
		}
	}

	return style
}

pub fn (mut ctx Context) set_style(style Style) {
	ctx.font_wrapper.font = style.font.font
	ctx.font_wrapper.size = style.font.size
	ctx.mu.style.size = C.mu_vec2(style.size.x, style.size.y)
	ctx.mu.style.padding = style.padding
	ctx.mu.style.spacing = style.spacing
	ctx.mu.style.indent = style.indent
	ctx.mu.style.title_height = style.title_height
	ctx.mu.style.scrollbar_size = style.scrollbar_size
	ctx.mu.style.thumb_size = style.thumb_size

	for i in 0 .. mu_color_max {
		ctx.mu.style.colors[i].r = style.colors[i].r
		ctx.mu.style.colors[i].g = style.colors[i].g
		ctx.mu.style.colors[i].b = style.colors[i].b
		ctx.mu.style.colors[i].a = style.colors[i].a
	}
}

// -----------------------------------------------------------------------------
pub fn (mut ctx Context) begin() {
	C.mu_begin(ctx.mu)
}

pub fn (mut ctx Context) end() {
	C.mu_end(ctx.mu)
}

// -----------------------------------------------------------------------------
pub fn (mut ctx Context) handle_input_event() {
	// 1. Mouse Position
	mouse_x := rl.get_mouse_x()
	mouse_y := rl.get_mouse_y()
	C.mu_input_mousemove(ctx.mu, mouse_x, mouse_y)

	// 2. Mouse Scroll
	wheel := rl.get_mouse_wheel_move_v()
	if wheel.x != 0 || wheel.y != 0 {
		C.mu_input_scroll(ctx.mu, int(wheel.x * -30), int(wheel.y * -30))
	}

	// 3. Mouse Buttons
	if rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_left)) {
		C.mu_input_mousedown(ctx.mu, mouse_x, mouse_y, c.mu_mouse_left)
	} else if rl.is_mouse_button_released(int(rl.MouseButton.mouse_button_left)) {
		C.mu_input_mouseup(ctx.mu, mouse_x, mouse_y, c.mu_mouse_left)
	}

	if rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_right)) {
		C.mu_input_mousedown(ctx.mu, mouse_x, mouse_y, c.mu_mouse_right)
	} else if rl.is_mouse_button_released(int(rl.MouseButton.mouse_button_right)) {
		C.mu_input_mouseup(ctx.mu, mouse_x, mouse_y, c.mu_mouse_right)
	}

	if rl.is_mouse_button_pressed(int(rl.MouseButton.mouse_button_middle)) {
		C.mu_input_mousedown(ctx.mu, mouse_x, mouse_y, c.mu_mouse_middle)
	} else if rl.is_mouse_button_released(int(rl.MouseButton.mouse_button_middle)) {
		C.mu_input_mouseup(ctx.mu, mouse_x, mouse_y, c.mu_mouse_middle)
	}

	// 4. Special Keys
	for mapping in key_mappings {
		if rl.is_key_pressed(int(mapping.rl_key)) {
			C.mu_input_keydown(ctx.mu, mapping.mu_key)
		} else if rl.is_key_released(int(mapping.rl_key)) {
			C.mu_input_keyup(ctx.mu, mapping.mu_key)
		}
	}

	// 5. Character Text Input Queue
	for {
		codepoint := rl.get_char_pressed()
		if codepoint == 0 {
			break
		}
		if codepoint >= 32 && codepoint <= 126 {
			str := u8(codepoint).ascii_str()
			C.mu_input_text(ctx.mu, str.str)
		}
	}
}

pub fn (mut ctx Context) update_mouse_position() {
	mouse_x := rl.get_mouse_x()
	mouse_y := rl.get_mouse_y()
	C.mu_input_mousemove(ctx.mu, mouse_x, mouse_y)
}

pub fn (mut ctx Context) wants_input_capture() bool {
	return ctx.mu.hover_root != unsafe { nil } || ctx.mu.focus != 0
}

pub fn (mut ctx Context) is_mouse_down(button Mouse) bool {
	return ctx.mu.mouse_down & i32(button) != 0
}

pub fn (mut ctx Context) is_mouse_pressed(button Mouse) bool {
	return ctx.mu.mouse_pressed & i32(button) != 0
}

// -----------------------------------------------------------------------------
pub fn (mut ctx Context) render() {
	// iterate through all render commands generated by microui
	mut cmd := unsafe { &C.mu_Command(nil) }
	for C.mu_next_command(ctx.mu, &cmd) != 0 {
		match unsafe { cmd.@type } {
			c.mu_command_rect {
				rl.draw_rectangle(unsafe { cmd.rect.rect.x }, unsafe { cmd.rect.rect.y },
					unsafe { cmd.rect.rect.w }, unsafe { cmd.rect.rect.h }, rl.Color{
						r: unsafe { cmd.rect.color.r }
						g: unsafe { cmd.rect.color.g }
						b: unsafe { cmd.rect.color.b }
						a: unsafe { cmd.rect.color.a }
					})
			}
			c.mu_command_text {
				font := unsafe { &SizedFont(cmd.text.font) }
				text := unsafe { cstring_to_vstring(&cmd.text.str[0]) }
				rl.draw_text_ex(font.font, text, rl.Vector2{unsafe { cmd.text.pos.x }, unsafe { cmd.text.pos.y }},
					font.size, 1, rl.Color{
						r: unsafe { cmd.text.color.r }
						g: unsafe { cmd.text.color.g }
						b: unsafe { cmd.text.color.b }
						a: unsafe { cmd.text.color.a }
					})
			}
			c.mu_command_clip {
				x := unsafe { cmd.clip.rect.x }
				y := unsafe { cmd.clip.rect.y }
				w := unsafe { cmd.clip.rect.w }
				h := unsafe { cmd.clip.rect.h }

				if w == 0x1000000 && h == 0x1000000 {
					rl.end_scissor_mode()
				} else {
					rl.begin_scissor_mode(x, y, w, h)
				}
			}
			c.mu_command_icon {
				id := unsafe { cmd.icon.id }
				if id > 0 && id <= 4 {
					atlas_rect := atlas[id - 1]
					screen_rect := rl.Rectangle{
						x:      unsafe { cmd.icon.rect.x } +
							(unsafe { cmd.icon.rect.w } - atlas_rect.width) / 2
						y:      unsafe { cmd.icon.rect.y } +
							(unsafe { cmd.icon.rect.h } - atlas_rect.height) / 2
						width:  atlas_rect.width
						height: atlas_rect.height
					}
					rl.draw_texture_pro(ctx.icon_atlas, atlas_rect, screen_rect, rl.Vector2{0, 0},
						0, rl.Color{
							r: unsafe { cmd.icon.color.r }
							g: unsafe { cmd.icon.color.g }
							b: unsafe { cmd.icon.color.b }
							a: unsafe { cmd.icon.color.a }
						})
				}
			}
			c.mu_command_cust {
				callback_draw := unsafe { cmd.cust.draw }
				rect := unsafe { cmd.cust.rect }
				user_data := unsafe { cmd.cust.user_data }

				translated_callback_draw := unsafe { CustomDrawFunuctionExternal(callback_draw) }
				translated_callback_draw(rl.Rectangle{
					x:      rect.x
					y:      rect.y
					width:  rect.w
					height: rect.h
				}, user_data)
			}
			else {}
		}
	}
}

// -----------------------------------------------------------------------------
// WINDOW RELATED FUNCTIONS
// -----------------------------------------------------------------------------

// begin_window
// ------------
// Marks the beginning of a new MicroUI popup window.
// Returns true if this window should be drawn.
pub fn (mut ctx Context) begin_window(title string, rect rl.Rectangle) bool {
	// println(title)
	return ctx.begin_window_ex(title, rect, Opt.zero())
}

// begin_window_ex
// ---------------
// Marks the beginning of a new MicroUI popup window and allows additional options to be passed in.
// Returns true if this window should be drawn.
pub fn (mut ctx Context) begin_window_ex(title string, rect rl.Rectangle, options Opt) bool {
	return C.mu_begin_window_ex(ctx.mu, title.str, C.mu_Rect{
		x: int(rect.x)
		y: int(rect.y)
		w: int(rect.width)
		h: int(rect.height)
	}, int(options)) != 0
}

// end_window
// ----------
// Marks the end of a MicroUI popup window.
pub fn (mut ctx Context) end_window() {
	C.mu_end_window(ctx.mu)
}

// -----------------------------------------------------------------------------
// Bool controlled window helper functions

pub fn (mut ctx Context) begin_window_bool_controlled(title string, rect rl.Rectangle, is_open &bool) bool {
	return ctx.begin_window_ex_bool_controlled(title, rect, Opt.zero(), is_open)
}

pub fn (mut ctx Context) begin_window_ex_bool_controlled(title string, rect rl.Rectangle, options Opt, is_open bool) bool {
	// does the external bool say this window is closed?
	if !is_open {
		// make sure its closed
		ctx.set_container_open(title, false)

		// do not draw any controls inside it
		return false
	}

	// otherwise -> make sure its open
	ctx.set_container_open(title, true)

	// draw the window
	return ctx.begin_window_ex(title, rect, options)
}

pub fn (mut ctx Context) end_window_bool_controlled(is_open &bool) {
	container := C.mu_get_current_container(ctx.mu)
	C.mu_end_window(ctx.mu)
	unsafe {
		*is_open = container.@open != 0
	}
}

// -----------------------------------------------------------------------------
// POPUP RELATED FUNCTIONS
// -----------------------------------------------------------------------------
pub fn (mut ctx Context) open_popup(name string) {
	C.mu_open_popup(ctx.mu, name.str)
}

pub fn (mut ctx Context) begin_popup(name string) bool {
	return C.mu_begin_popup(ctx.mu, name.str) != 0
}

pub fn (mut ctx Context) end_popup() {
	C.mu_end_popup(ctx.mu)
}

// -----------------------------------------------------------------------------
// PANEL RELATED FUNCTIONS
// -----------------------------------------------------------------------------
pub fn (mut ctx Context) begin_panel(name string) {
	ctx.begin_panel_ex(name, Opt.zero())
}

pub fn (mut ctx Context) begin_panel_ex(name string, opt Opt) {
	C.mu_begin_panel_ex(ctx.mu, name.str, i32(opt))
}

pub fn (mut ctx Context) end_panel() {
	C.mu_end_panel(ctx.mu)
}

// -----------------------------------------------------------------------------
// LAYOUT RELATED FUNCTIONS
// -----------------------------------------------------------------------------
pub fn (mut ctx Context) layout_row(widths []int, height int) {
	c_widths := widths.map(i32(it))
	C.mu_layout_row(ctx.mu, widths.len, c_widths.data, height)
}

pub fn (mut ctx Context) layout_begin_column() {
	C.mu_layout_begin_column(ctx.mu)
}

pub fn (mut ctx Context) layout_end_column() {
	C.mu_layout_end_column(ctx.mu)
}

pub fn (mut ctx Context) layout_width(width int) {
	C.mu_layout_width(ctx.mu, i32(width))
}

pub fn (mut ctx Context) layout_height(height int) {
	C.mu_layout_height(ctx.mu, i32(height))
}

pub fn (mut ctx Context) layout_set_next(r rl.Rectangle, relative bool) {
	relative_int := if relative { i32(1) } else { i32(0) }
	C.mu_layout_set_next(ctx.mu, C.mu_rect(i32(r.x), i32(r.y), i32(r.width), i32(r.height)),
		relative_int)
}

pub fn (mut ctx Context) layout_next() rl.Rectangle {
	rect := C.mu_layout_next(ctx.mu)
	return rl.Rectangle{
		x:      rect.x
		y:      rect.y
		width:  rect.w
		height: rect.h
	}
}

// -----------------------------------------------------------------------------
// IDENTIFIER FUNCTIONS
// -----------------------------------------------------------------------------

pub fn (mut ctx Context) get_id(data string) MuId {
	return C.mu_get_id(ctx.mu, data.str, data.len)
}

pub fn (mut ctx Context) get_last_id() MuId {
	return ctx.mu.last_id
}

pub fn (mut ctx Context) get_focus_id() MuId {
	return ctx.mu.focus
}

pub fn (mut ctx Context) push_id(id string) {
	C.mu_push_id(ctx.mu, id.str, id.len)
}

pub fn (mut ctx Context) push_id_i(id i64) {
	C.mu_push_id(ctx.mu, &id, sizeof(i64))
}

pub fn (mut ctx Context) pop_id() {
	C.mu_pop_id(ctx.mu)
}

pub fn (mut ctx Context) set_focus(id MuId) {
	C.mu_set_focus(ctx.mu, id)
}

pub fn (mut ctx Context) bring_container_to_front(name string) {
	mut container := C.mu_get_container(ctx.mu, name.str)
	C.mu_bring_to_front(ctx.mu, container)
}

pub fn (mut ctx Context) set_container_open(name string, isopen bool) {
	mut container := C.mu_get_container(ctx.mu, name.str)
	container.@open = if isopen { 1 } else { 0 }
}

pub fn (mut ctx Context) get_container_open(name string) bool {
	mut container := C.mu_get_container(ctx.mu, name.str)
	return container.@open != 0
}

pub fn (mut ctx Context) get_container_rect(name string) rl.Rectangle {
	container := C.mu_get_container(ctx.mu, name.str)
	return rl.Rectangle{
		x:      container.rect.x
		y:      container.rect.y
		width:  container.rect.w
		height: container.rect.h
	}
}

pub fn (mut ctx Context) set_container_rect(name string, rect rl.Rectangle) {
	mut container := C.mu_get_container(ctx.mu, name.str)
	container.rect.x = i32(rect.x)
	container.rect.y = i32(rect.y)
	container.rect.w = i32(rect.width)
	container.rect.h = i32(rect.height)
}

pub fn (mut ctx Context) get_container_scroll(name string) vec.Vec2[int] {
	container := C.mu_get_container(ctx.mu, name.str)
	return vec.Vec2[int]{
		x: container.scroll.x
		y: container.scroll.y
	}
}

pub fn (mut ctx Context) set_container_scroll(name string, scroll vec.Vec2[int]) {
	mut container := C.mu_get_container(ctx.mu, name.str)
	container.scroll.x = scroll.x
	container.scroll.y = scroll.y
}

pub fn (mut ctx Context) get_container_content_size(name string) vec.Vec2[int] {
	container := C.mu_get_container(ctx.mu, name.str)
	return vec.Vec2[int]{
		x: container.content_size.x
		y: container.content_size.y
	}
}

pub fn (mut ctx Context) get_container_body(name string) rl.Rectangle {
	container := C.mu_get_container(ctx.mu, name.str)
	return rl.Rectangle{
		x:      container.body.x
		y:      container.body.y
		width:  container.body.w
		height: container.body.h
	}
}

pub fn (mut ctx Context) get_current_container_rect() rl.Rectangle {
	container := C.mu_get_current_container(ctx.mu)
	return rl.Rectangle{
		x:      container.rect.x
		y:      container.rect.y
		width:  container.rect.w
		height: container.rect.h
	}
}

pub fn (mut ctx Context) set_current_container_rect(rect rl.Rectangle) {
	mut container := C.mu_get_current_container(ctx.mu)
	container.rect.x = i32(rect.x)
	container.rect.y = i32(rect.y)
	container.rect.w = i32(rect.width)
	container.rect.h = i32(rect.height)
}

pub fn (mut ctx Context) get_current_container_scroll() vec.Vec2[int] {
	container := C.mu_get_current_container(ctx.mu)
	return vec.Vec2[int]{
		x: container.scroll.x
		y: container.scroll.y
	}
}

pub fn (mut ctx Context) set_current_container_scroll(scroll vec.Vec2[int]) {
	mut container := C.mu_get_current_container(ctx.mu)
	container.scroll.x = scroll.x
	container.scroll.y = scroll.y
}

pub fn (mut ctx Context) get_current_container_content_size() vec.Vec2[int] {
	container := C.mu_get_current_container(ctx.mu)
	return vec.Vec2[int]{
		x: container.content_size.x
		y: container.content_size.y
	}
}

pub fn (mut ctx Context) get_current_container_body() rl.Rectangle {
	container := C.mu_get_current_container(ctx.mu)
	return rl.Rectangle{
		x:      container.body.x
		y:      container.body.y
		width:  container.body.w
		height: container.body.h
	}
}

// -----------------------------------------------------------------------------
// DRAWING RELATED FUNCTIONS
// -----------------------------------------------------------------------------
pub fn (mut ctx Context) set_clip(rect rl.Rectangle) {
	C.mu_set_clip(ctx.mu, C.mu_rect(i32(rect.x), i32(rect.y), i32(rect.width), i32(rect.height)))
}

pub fn (mut ctx Context) unset_clip() {
	C.mu_set_clip(ctx.mu, C.mu_rect(i32(0), i32(0), i32(0x1000000), i32(0x1000000)))
}

pub fn (mut ctx Context) draw_rect(rect rl.Rectangle, color rl.Color) {
	C.mu_draw_rect(ctx.mu, C.mu_rect(i32(rect.x), i32(rect.y), i32(rect.width), i32(rect.height)),
		C.mu_color(color.r, color.g, color.b, color.a))
}

pub fn (mut ctx Context) draw_box(rect rl.Rectangle, color rl.Color) {
	C.mu_draw_box(ctx.mu, C.mu_rect(i32(rect.x), i32(rect.y), i32(rect.width), i32(rect.height)),
		C.mu_color(color.r, color.g, color.b, color.a))
}

pub fn (mut ctx Context) draw_text(str string, pos vec.Vec2[int], color rl.Color) {
	C.mu_draw_text(ctx.mu, ctx.font_wrapper, str.str, str.len, C.mu_vec2(pos.x, pos.y),
		C.mu_color(color.r, color.g, color.b, color.a))
}

pub fn (mut ctx Context) draw_icon(id int, rect rl.Rectangle, color rl.Color) {
	C.mu_draw_icon(ctx.mu, id, C.mu_rect(i32(rect.x), i32(rect.y), i32(rect.width), i32(rect.height)),
		C.mu_color(color.r, color.g, color.b, color.a))
}

pub fn (mut ctx Context) draw_custom(rect rl.Rectangle, user_data voidptr, draw fn (rect rl.Rectangle, user_data voidptr)) {
	translated_callback := unsafe { CustomDrawFunuctionInternal(draw) }
	C.mu_draw_custom(ctx.mu, C.mu_fRect{
		x: rect.x
		y: rect.y
		w: rect.width
		h: rect.height
	}, user_data, translated_callback)
}

// -----------------------------------------------------------------------------
// CONTROLS RELATED FUNCTIONS
// -----------------------------------------------------------------------------
pub fn (mut ctx Context) draw_control_frame(id MuId, rect rl.Rectangle, color Color, opt Opt) {
	C.mu_draw_control_frame(ctx.mu, id, C.mu_rect(i32(rect.x), i32(rect.y), i32(rect.width),
		i32(rect.height)), i32(color), i32(opt))
}

pub fn (mut ctx Context) draw_control_text(str string, rect rl.Rectangle, color Color, opt Opt) {
	C.mu_draw_control_text(ctx.mu, str.str, C.mu_rect(i32(rect.x), i32(rect.y), i32(rect.width),
		i32(rect.height)), i32(color), i32(opt))
}

pub fn (mut ctx Context) mouse_over(rect rl.Rectangle) bool {
	return C.mu_mouse_over(ctx.mu, C.mu_rect(i32(rect.x), i32(rect.y), i32(rect.width),
		i32(rect.height))) != 0
}

pub fn (mut ctx Context) update_control(id MuId, rect rl.Rectangle, opt Opt) {
	C.mu_update_control(ctx.mu, id, C.mu_rect(i32(rect.x), i32(rect.y), i32(rect.width),
		i32(rect.height)), i32(opt))
}

// -----------------------------------------------------------------------------
// WIDGETS
// -----------------------------------------------------------------------------
pub fn (mut ctx Context) text(text string) {
	C.mu_text(ctx.mu, text.str)
}

pub fn (mut ctx Context) label(text string) {
	C.mu_label(ctx.mu, text.str)
}

pub fn (mut ctx Context) button(label string) bool {
	return ctx.button_ex(label, .none, .aligncenter)
}

pub fn (mut ctx Context) button_ex(label string, icon Icon, options Opt) bool {
	return C.mu_button_ex(ctx.mu, label.str, i32(icon), int(options)) != 0
}

pub fn (mut ctx Context) checkbox(label string, state &bool) bool {
	content_address := i64(unsafe { voidptr(state) })
	C.mu_push_id(ctx.mu, &content_address, sizeof(i64))

	c_state := if *state { i32(1) } else { i32(0) }
	result := C.mu_checkbox(ctx.mu, label.str, &c_state) != 0
	unsafe {
		*state = c_state == 1
	}
	C.mu_pop_id(ctx.mu)
	return result
}

pub fn (mut ctx Context) textbox(content &string) Res {
	return ctx.textbox_ex(content, Opt.zero())
}

pub fn (mut ctx Context) textbox_ex(content &string, options Opt) Res {
	content_address := i64(unsafe { voidptr(content) })
	C.mu_push_id(ctx.mu, &content_address, sizeof(i64))

	// write the given string to the input buffer
	unsafe {
		C.snprintf(ctx.input_buffer, ctx.input_buffer_size, c'%s', (*content).str)
	}

	// run the microui textbox
	result := C.mu_textbox_ex(ctx.mu, ctx.input_buffer, ctx.input_buffer_size, i32(options))

	// copy the edited string back into the user provided one
	unsafe {
		*content = cstring_to_vstring(ctx.input_buffer)
	}
	C.mu_pop_id(ctx.mu)

	res := match result {
		mu_res_active { Res.active }
		mu_res_change { Res.change }
		mu_res_submit { Res.submit }
		else { Res.none }
	}
	return res
}

pub fn (mut ctx Context) slider(value &f32, low f32, high f32) bool {
	return ctx.slider_ex(value, low, high, 0, c.mu_slider_fmt, .aligncenter)
}

pub fn (mut ctx Context) slider_ex(value &f32, low f32, high f32, step f32, fmt string, opt Opt) bool {
	return C.mu_slider_ex(ctx.mu, value, low, high, step, fmt.str, i32(opt)) != 0
}

pub fn (mut ctx Context) number(value &f32, step f32) bool {
	return ctx.number_ex(value, step, c.mu_slider_fmt, .aligncenter)
}

pub fn (mut ctx Context) number_ex(value &f32, step f32, fmt string, opt Opt) bool {
	return C.mu_number_ex(ctx.mu, value, step, fmt.str, i32(opt)) != 0
}

pub fn (mut ctx Context) header(label string) bool {
	return ctx.header_ex(label, Opt.zero())
}

pub fn (mut ctx Context) header_ex(label string, opt Opt) bool {
	return C.mu_header_ex(ctx.mu, label.str, i32(opt)) != 0
}

pub fn (mut ctx Context) begin_treenode(label string) bool {
	return ctx.begin_treenode_ex(label, Opt.zero())
}

pub fn (mut ctx Context) begin_treenode_ex(label string, opt Opt) bool {
	return C.mu_begin_treenode_ex(ctx.mu, label.str, i32(opt)) != 0
}

pub fn (mut ctx Context) end_treenode() {
	C.mu_end_treenode(ctx.mu)
}
