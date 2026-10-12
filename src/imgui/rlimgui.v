module imgui

import raylib

#include "@VMODROOT/../thirdparty/rlimgui/rlImGui.h"

fn C.rlImGuiSetup(dark bool)
pub fn rl_imgui_setup(dark bool) {
	C.rlImGuiSetup(dark)
}

fn C.rlImGuiShutdown()
pub fn rl_imgui_shutdown() {
	C.rlImGuiShutdown()
}

fn C.rlImGuiBegin()
pub fn rl_imgui_begin() {
	C.rlImGuiBegin()
}

fn C.rlImGuiEnd()
pub fn rl_imgui_end() {
	C.rlImGuiEnd()
}

fn C.rlImGuiImage(texture &raylib.Texture2D)
pub fn rl_imgui_image(texture &raylib.Texture2D) {
	C.rlImGuiImage(texture)
}

fn C.rlImGuiImageSize(texture &raylib.Texture2D, width i32, height i32)
pub fn rl_imgui_image_size(texture &raylib.Texture2D, width int, height int) {
	C.rlImGuiImageSize(texture, width, height)
}
