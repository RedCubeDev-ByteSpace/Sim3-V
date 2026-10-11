import os

fn main() {
	lib_name := 'librlimgui.a'

	if os.exists(lib_name) {
		println('${lib_name} already exists. Skipping compilation.')
		return
	}

	println('Compiling C++ sources into ${lib_name}...')

	cmds := [
		'g++ -std=c++11 -c thirdparty/cimgui/imgui/imgui.cpp -Ithirdparty/cimgui -Ithirdparty/cimgui/imgui',
		'g++ -std=c++11 -c thirdparty/cimgui/imgui/imgui_draw.cpp -Ithirdparty/cimgui -Ithirdparty/cimgui/imgui',
		'g++ -std=c++11 -c thirdparty/cimgui/imgui/imgui_tables.cpp -Ithirdparty/cimgui -Ithirdparty/cimgui/imgui',
		'g++ -std=c++11 -c thirdparty/cimgui/imgui/imgui_widgets.cpp -Ithirdparty/cimgui -Ithirdparty/cimgui/imgui',
		'g++ -std=c++11 -c thirdparty/cimgui/imgui/imgui_demo.cpp -Ithirdparty/cimgui -Ithirdparty/cimgui/imgui',
		'g++ -std=c++11 -c thirdparty/cimgui/cimgui.cpp -Ithirdparty/cimgui -Ithirdparty/cimgui/imgui',
		'g++ -std=c++11 -c thirdparty/rlimgui/rlImGui.cpp -Ithirdparty/rlimgui -Ithirdparty/cimgui -Ithirdparty/cimgui/imgui',
		'ar rcs ${lib_name} imgui.o imgui_draw.o imgui_tables.o imgui_widgets.o imgui_demo.o cimgui.o rlImGui.o',
		'rm -f *.o',
	]

	for cmd in cmds {
		res := os.execute(cmd)
		if res.exit_code != 0 {
			eprintln('Build failed during command: ${cmd}')
			eprintln(res.output)
			exit(1)
		}
	}

	println('Successfully generated ${lib_name}!')
}
