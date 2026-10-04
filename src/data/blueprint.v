module data

import x.json2
import json

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
}

pub fn (b Blueprint) to_json() string {
	mut obj := map[string]json2.Any{}
	obj['name'] = b.name

	mut components_arr := []json2.Any{}
	for comp in b.components {
		components_arr << comp.to_json2()
	}
	obj['components'] = components_arr

	return json2.encode(obj)
}
