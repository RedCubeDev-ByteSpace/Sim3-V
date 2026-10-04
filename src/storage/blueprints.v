module storage

import data
import os
import x.json2
import utils

pub fn index_blueprint_directory(mut app data.App) {
	// do we have a working blueprints dir?
	if !app.storage.has_blueprints_directory {
		return
	}

	// if so -> index it!
	app.storage.blueprints.blueprint_dir = index_directory(app.storage.blueprints_directory)
}

fn index_directory(path string) data.BlueprintDirectory {
	// create a new blueprint directory node
	mut dir := data.BlueprintDirectory{}

	// use the directory's name
	dir.name = os.file_name(path)

	// scan the path...
	files := os.ls(path) or { return dir }

	// ...and go through all of its files and directories
	for file in files {
		file_path := os.join_path(path, file)

		// is this file actually a directory?
		// -> index it
		if os.is_dir(file_path) {
			dir.blueprint_directories << index_directory(file_path)
		}

		// otherwise: is it a json?
		if os.file_ext(file) != '.json' {
			continue // no? -> skip
		}

		// try to read the file
		file_content := os.read_file(file_path) or { continue }

		// try to deserialize it
		blueprint := json2.decode[data.Blueprint](file_content) or { panic(err) }

		// store it in the index
		dir.blueprints << blueprint
	}

	return dir
}

pub fn create_blueprint_from_selected_components(mut app data.App, name string, path string) {
	// make sure we have somewhere to store this in
	if !app.storage.has_blueprints_directory {
		return
	}

	// try to create the path
	full_path := os.join_path(app.storage.blueprints_directory, path)
	if !os.exists(full_path) {
		os.mkdir_all(full_path) or { return }
	}

	// create a new blueprint object
	mut cfgs := []data.ComponentCfg{}
	for comp in app.bench.selected_components {
		cfgs << comp.get_cfg()
	}
	utils.normalize_cfgs(mut cfgs)

	blueprint := data.Blueprint{
		name:       name
		components: cfgs
	}

	// serialize it
	json := json2.encode(blueprint)
	dump(json)

	// write it to disk
	filename := os.join_path(full_path, '${name}.json')
	os.write_file(filename, json) or { return }

	// refresh the index
	index_blueprint_directory(mut app)
}
