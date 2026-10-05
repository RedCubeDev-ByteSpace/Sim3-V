@[translated]
module c

#flag @VMODROOT/c/microui.c
#include "@VMODROOT/c/microui.h"

//
//* Copyright (c) 2024 rxi
//*
//* This library is free software; you can redistribute it and/or modify it
//* under the terms of the MIT license. See `microui.c` for details.
// // empty enum
pub const mu_slider_fmt = '%.2f'
pub const mu_real_fmt = '%.2f'

pub const mu_clip_part = 1
pub const mu_clip_all = 2 // empty enum

pub const mu_command_jump = 1
pub const mu_command_clip = 2
pub const mu_command_rect = 3
pub const mu_command_text = 4
pub const mu_command_icon = 5
pub const mu_command_cust = 6
pub const mu_command_max = 7 // empty enum

pub const mu_color_text = 0
pub const mu_color_border = 1
pub const mu_color_windowbg = 2
pub const mu_color_titlebg = 3
pub const mu_color_titletext = 4
pub const mu_color_panelbg = 5
pub const mu_color_button = 6
pub const mu_color_buttonhover = 7
pub const mu_color_buttonfocus = 8
pub const mu_color_base = 9
pub const mu_color_basehover = 10
pub const mu_color_basefocus = 11
pub const mu_color_scrollbase = 12
pub const mu_color_scrollthumb = 13
pub const mu_color_max = 14 // empty enum

pub const mu_icon_close = 1
pub const mu_icon_check = 2
pub const mu_icon_collapsed = 3
pub const mu_icon_expanded = 4
pub const mu_icon_max = 5 // empty enum

pub const mu_res_active = 1
pub const mu_res_submit = 2
pub const mu_res_change = 4 // empty enum

pub const mu_opt_aligncenter = 1
pub const mu_opt_alignright = 2
pub const mu_opt_noi32eract = 4
pub const mu_opt_noframe = 8
pub const mu_opt_noresize = 16
pub const mu_opt_noscroll = 32
pub const mu_opt_noclose = 64
pub const mu_opt_notitle = 128
pub const mu_opt_holdfocus = 256
pub const mu_opt_autosize = 512
pub const mu_opt_popup = 1024
pub const mu_opt_closed = 2048
pub const mu_opt_expanded = 4096 // empty enum

pub const mu_mouse_left = 1
pub const mu_mouse_right = 2
pub const mu_mouse_middle = 4 // empty enum

pub const mu_key_shift = 1
pub const mu_key_ctrl = 2
pub const mu_key_alt = 4
pub const mu_key_backspace = 8
pub const mu_key_return = 16

pub type C.mu_Id = u32

@[typedef]
pub struct C.mu_Context {
	// callbacks
	text_width  fn (font voidptr, str &char, len i32) i32
	text_height fn (font voidptr) i32
	draw_frame  fn (ctx &C.mu_Context, rect C.mu_Rect, colorid i32)

	// core state
	_style C.mu_Style
	style  &C.mu_Style

	hover         u32
	focus         u32
	last_id       u32
	last_rect     C.mu_Rect
	last_zindex   i32
	updated_focus i32
	frame         i32

	hover_root      &C.mu_Container
	next_hover_root &C.mu_Container
	scroll_target   &C.mu_Container

	number_edit_buf [127]u8 // MU_MAX_FMT
	number_edit     u32

	// stacks
	// mu_stack(char, 256 * 1024)
	command_list_idx   i32
	command_list_items [256 * 1024]u8

	// mu_stack(mu_Container*, 32)
	root_list_idx   i32
	root_list_items [32]&C.mu_Container

	// mu_stack(mu_Container*, 32)
	container_stack_idx   i32
	container_stack_items [32]&C.mu_Container

	// mu_stack(mu_Rect, 32)
	clip_stack_idx   i32
	clip_stack_items [32]C.mu_Rect

	// mu_stack(mu_Id, 32)
	id_stack_idx   i32
	id_stack_items [32]u32

	// mu_stack(mu_Layout, 16)
	layout_stack_idx   i32
	layout_stack_items [16]C.mu_Layout

	// retained state pools
	container_pool [48]C.mu_PoolItem
	containers     [48]C.mu_Container

	treenode_pool [48]C.mu_PoolItem

	// input state
	mouse_pos      C.mu_Vec2
	last_mouse_pos C.mu_Vec2
	mouse_delta    C.mu_Vec2
	scroll_delta   C.mu_Vec2
	mouse_down     i32
	mouse_pressed  i32
	key_down       i32
	key_pressed    i32
	input_text     [32]u8
}

@[typedef]
pub struct C.mu_Style {
pub mut:
	font           voidptr
	size           C.mu_Vec2
	padding        int
	spacing        int
	indent         int
	title_height   int
	scrollbar_size int
	thumb_size     int
	colors         [14]C.mu_Color
}

@[typedef]
pub struct C.mu_Rect {
pub mut:
	x i32
	y i32
	w i32
	h i32
}

@[typedef]
pub struct C.mu_fRect {
pub mut:
	x f32
	y f32
	w f32
	h f32
}

@[typedef]
pub struct C.mu_Color {
pub mut:
	r u8
	g u8
	b u8
	a u8
}

@[typedef]
pub struct C.mu_Vec2 {
pub mut:
	x i32
	y i32
}

@[typedef]
pub struct C.mu_BaseCommand {
pub mut:
	@type i32
	size  i32
}

@[typedef]
pub struct C.mu_RectCommand {
pub mut:
	base  C.mu_BaseCommand
	rect  C.mu_Rect
	color C.mu_Color
}

@[typedef]
pub struct C.mu_TextCommand {
pub mut:
	base  C.mu_BaseCommand
	font  voidptr
	pos   C.mu_Vec2
	color C.mu_Color
	str   [1]char // C flexible array member
}

@[typedef]
pub struct C.mu_IconCommand {
pub mut:
	base  C.mu_BaseCommand
	rect  C.mu_Rect
	id    i32
	color C.mu_Color
}

@[typedef]
pub struct C.mu_ClipCommand {
pub mut:
	base C.mu_BaseCommand
	rect C.mu_Rect
}

@[typedef]
pub struct C.mu_CustCommand {
pub mut:
	base      C.mu_BaseCommand
	rect      C.mu_fRect
	user_data voidptr
	draw      fn (rect C.mu_fRect, user_data voidptr)
}

@[typedef]
pub union C.mu_Command {
pub mut:
	@type i32
	base  C.mu_BaseCommand
	clip  C.mu_ClipCommand
	rect  C.mu_RectCommand
	text  C.mu_TextCommand
	icon  C.mu_IconCommand
	cust  C.mu_CustCommand
}

@[typedef]
pub struct C.mu_Container {
pub mut:
	head                    &C.mu_Command
	tail                    &C.mu_Command
	rect                    C.mu_Rect
	body                    C.mu_Rect
	content_size            C.mu_Vec2
	scroll                  C.mu_Vec2
	zindeinput_buffer_sizex i32
	open                    i32
}

pub fn C.mu_vec2(x i32, y i32) C.mu_Vec2
pub fn C.mu_rect(x i32, y i32, w i32, h i32) C.mu_Rect
pub fn C.mu_color(r i32, g i32, b i32, a i32) C.mu_Color
pub fn C.mu_init(ctx &C.mu_Context)
pub fn C.mu_begin(ctx &C.mu_Context)
pub fn C.mu_end(ctx &C.mu_Context)
pub fn C.mu_set_focus(ctx &C.mu_Context, id C.mu_Id)
pub fn C.mu_get_id(ctx &C.mu_Context, data voidptr, size i32) C.mu_Id
pub fn C.mu_push_id(ctx &C.mu_Context, data voidptr, size i32)
pub fn C.mu_pop_id(ctx &C.mu_Context)
pub fn C.mu_push_clip_rect(ctx &C.mu_Context, rect C.mu_Rect)
pub fn C.mu_pop_clip_rect(ctx &C.mu_Context)
pub fn C.mu_get_clip_rect(ctx &C.mu_Context) C.mu_Rect
pub fn C.mu_check_clip(ctx &C.mu_Context, r C.mu_Rect) i32
pub fn C.mu_get_current_container(ctx &C.mu_Context) &C.mu_Container
pub fn C.mu_get_container(ctx &C.mu_Context, name &i8) &C.mu_Container
pub fn C.mu_bring_to_front(ctx &C.mu_Context, cnt &C.mu_Container)
pub fn C.mu_pool_init(ctx &C.mu_Context, items &C.mu_PoolItem, len i32, id C.mu_Id) i32
pub fn C.mu_pool_get(ctx &C.mu_Context, items &C.mu_PoolItem, len i32, id C.mu_Id) i32
pub fn C.mu_pool_update(ctx &C.mu_Context, items &C.mu_PoolItem, idx i32)
pub fn C.mu_input_mousemove(ctx &C.mu_Context, x i32, y i32)
pub fn C.mu_input_mousedown(ctx &C.mu_Context, x i32, y i32, btn i32)
pub fn C.mu_input_mouseup(ctx &C.mu_Context, x i32, y i32, btn i32)
pub fn C.mu_input_scroll(ctx &C.mu_Context, x i32, y i32)
pub fn C.mu_input_keydown(ctx &C.mu_Context, key i32)
pub fn C.mu_input_keyup(ctx &C.mu_Context, key i32)
pub fn C.mu_input_text(ctx &C.mu_Context, text &i8)
pub fn C.mu_push_command(ctx &C.mu_Context, type_ i32, size i32) &C.mu_Command
pub fn C.mu_next_command(ctx &C.mu_Context, cmd &&C.mu_Command) i32
pub fn C.mu_set_clip(ctx &C.mu_Context, rect C.mu_Rect)
pub fn C.mu_draw_rect(ctx &C.mu_Context, rect C.mu_Rect, color C.mu_Color)
pub fn C.mu_draw_box(ctx &C.mu_Context, rect C.mu_Rect, color C.mu_Color)
pub fn C.mu_draw_text(ctx &C.mu_Context, font voidptr, str &i8, len i32, pos C.mu_Vec2, color C.mu_Color)
pub fn C.mu_draw_icon(ctx &C.mu_Context, id i32, rect C.mu_Rect, color C.mu_Color)
pub fn C.mu_layout_row(ctx &C.mu_Context, items i32, widths &i32, height i32)
pub fn C.mu_layout_width(ctx &C.mu_Context, width i32)
pub fn C.mu_layout_height(ctx &C.mu_Context, height i32)
pub fn C.mu_layout_begin_column(ctx &C.mu_Context)
pub fn C.mu_layout_end_column(ctx &C.mu_Context)
pub fn C.mu_layout_set_next(ctx &C.mu_Context, r C.mu_Rect, relative i32)
pub fn C.mu_layout_next(ctx &C.mu_Context) C.mu_Rect
pub fn C.mu_draw_control_frame(ctx &C.mu_Context, id C.mu_Id, rect C.mu_Rect, colorid i32, opt i32)
pub fn C.mu_draw_control_text(ctx &C.mu_Context, str &i8, rect C.mu_Rect, colorid i32, opt i32)
pub fn C.mu_mouse_over(ctx &C.mu_Context, rect C.mu_Rect) i32
pub fn C.mu_update_control(ctx &C.mu_Context, id C.mu_Id, rect C.mu_Rect, opt i32)
pub fn C.mu_text(ctx &C.mu_Context, text &i8)
pub fn C.mu_label(ctx &C.mu_Context, text &i8)
pub fn C.mu_button_ex(ctx &C.mu_Context, label &i8, icon i32, opt i32) i32
pub fn C.mu_checkbox(ctx &C.mu_Context, label &i8, state &i32) i32
pub fn C.mu_textbox_raw(ctx &C.mu_Context, buf &i8, bufsz i32, id C.mu_Id, r C.mu_Rect, opt i32) i32
pub fn C.mu_textbox_ex(ctx &C.mu_Context, buf &char, bufsz i32, opt i32) i32
pub fn C.mu_slider_ex(ctx &C.mu_Context, value &f32, low f32, high f32, step f32, fmt &i8, opt i32) i32
pub fn C.mu_number_ex(ctx &C.mu_Context, value &f32, step f32, fmt &i8, opt i32) i32
pub fn C.mu_header_ex(ctx &C.mu_Context, label &i8, opt i32) i32
pub fn C.mu_begin_treenode_ex(ctx &C.mu_Context, label &i8, opt i32) i32
pub fn C.mu_end_treenode(ctx &C.mu_Context)
pub fn C.mu_begin_window_ex(ctx &C.mu_Context, title &i8, rect C.mu_Rect, opt i32) i32
pub fn C.mu_end_window(ctx &C.mu_Context)
pub fn C.mu_open_popup(ctx &C.mu_Context, name &i8)
pub fn C.mu_begin_popup(ctx &C.mu_Context, name &i8) i32
pub fn C.mu_end_popup(ctx &C.mu_Context)
pub fn C.mu_begin_panel_ex(ctx &C.mu_Context, name &i8, opt i32)
pub fn C.mu_end_panel(ctx &C.mu_Context)
pub fn C.mu_draw_custom(ctx &C.mu_Context, rect C.mu_fRect, user_data voidptr, draw fn (rect C.mu_fRect, user_data voidptr))

//
//* Copyright (c) 2024 rxi
//*
//* Permission is hereby granted, free of charge, to any person obtaining a copy
//* of this software and associated documentation files (the "Software"), to
//* deal in the Software without restriction, including without limitation the
//* rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
//* sell copies of the Software, and to permit persons to whom the Software is
//* furnished to do so, subject to the following conditions:
//*
//* The above copyright notice and this permission notice shall be included in
//* all copies or substantial portions of the Software.
//*
//* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//* IN THE SOFTWARE.
//
// incremented after incase `val` uses this value
// 32bit fnv-1a hash
//============================================================================
//* pool
//*============================================================================
//============================================================================
//* input handlers
//*============================================================================
//============================================================================
//* commandlist
//*============================================================================
//============================================================================
//* layout
//*============================================================================ // empty enum

pub const relative = 1
pub const absolute = 2

//============================================================================
//* controls
//*============================================================================
// only add scrollbar if content size is larger than body
// get sizing / positioning
// handle input
// clamp scroll to limits
// draw base and thumb
// set this as the scroll_target (will get scrolled on mousewheel)
// if the mouse is over it
