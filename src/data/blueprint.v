module data

import raylib as rl
import x.json2

pub struct BlueprintDirectory {
pub mut:
	name                  string
	blueprint_directories []BlueprintDirectory
	blueprints            []Blueprint
}

pub struct Blueprint {
pub:
	name       string
	components []ComponentCfg
pub mut:
	path    string       @[skip]
	date    string       @[skip]
	preview rl.Texture2D @[skip]
}

// pub fn (b Blueprint) to_json() string {
// 	mut obj := map[string]json2.Any{}
// 	obj['name'] = b.name
//
// 	mut components_arr := []json2.Any{}
// 	for comp in b.components {
// 		components_arr << comp.to_json2()
// 	}
// 	obj['components'] = components_arr
//
// 	return json2.encode(obj)
// }

pub fn (b Blueprint) unload_preview_texture() {
	rl.unload_texture(b.preview)
}
