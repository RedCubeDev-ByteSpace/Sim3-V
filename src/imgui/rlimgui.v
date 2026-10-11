module imgui

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
