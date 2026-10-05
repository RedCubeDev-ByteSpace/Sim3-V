module microui

const mu_color_text = 0
const mu_color_border = 1
const mu_color_windowbg = 2
const mu_color_titlebg = 3
const mu_color_titletext = 4
const mu_color_panelbg = 5
const mu_color_button = 6
const mu_color_buttonhover = 7
const mu_color_buttonfocus = 8
const mu_color_base = 9
const mu_color_basehover = 10
const mu_color_basefocus = 11
const mu_color_scrollbase = 12
const mu_color_scrollthumb = 13
const mu_color_max = 14

const mu_icon_close = 1
const mu_icon_check = 2
const mu_icon_collapsed = 3
const mu_icon_expanded = 4

const mu_opt_aligncenter = 1
const mu_opt_alignright = 2
const mu_opt_nointeract = 4
const mu_opt_noframe = 8
const mu_opt_noresize = 16
const mu_opt_noscroll = 32
const mu_opt_noclose = 64
const mu_opt_notitle = 128
const mu_opt_holdfocus = 256
const mu_opt_autosize = 512
const mu_opt_popup = 1024
const mu_opt_closed = 2048
const mu_opt_expanded = 4096 // empty enum

pub const mu_res_active = 1
pub const mu_res_submit = 2
pub const mu_res_change = 4 // empty enum

pub const mu_mouse_left = 1
pub const mu_mouse_right = 2
pub const mu_mouse_middle = 4 // empty enum

// -----------------------------------------------------------------------------
@[flag]
pub enum Opt {
	aligncenter
	alignright
	nointeract
	noframe
	noresize
	noscroll
	noclose
	notitle
	holdfocus
	autosize
	popup
	closed
	expanded
}

// -----------------------------------------------------------------------------
pub enum Icon {
	none      = 0
	close     = mu_icon_close
	check     = mu_icon_check
	collapsed = mu_icon_collapsed
	expanded  = mu_icon_expanded
}

// -----------------------------------------------------------------------------
pub enum Color {
	text        = mu_color_text
	border      = mu_color_border
	windowbg    = mu_color_windowbg
	titlebg     = mu_color_titlebg
	titletext   = mu_color_titletext
	panelbg     = mu_color_panelbg
	button      = mu_color_button
	buttonhover = mu_color_buttonhover
	buttonfocus = mu_color_buttonfocus
	base        = mu_color_base
	basehover   = mu_color_basehover
	basefocus   = mu_color_basefocus
	scrollbase  = mu_color_scrollbase
	scrollthumb = mu_color_scrollthumb
}

// -----------------------------------------------------------------------------
pub enum Res {
	none
	active = mu_res_active
	submit = mu_res_submit
	change = mu_res_change
}

// -----------------------------------------------------------------------------
pub enum Mouse {
	left   = mu_mouse_left
	middle = mu_mouse_middle
	right  = mu_mouse_right
}
