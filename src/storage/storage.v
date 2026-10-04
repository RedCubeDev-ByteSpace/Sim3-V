module storage

import data
import os

const data_dir_name = '.sim3'
const blueprints_dir_name = 'blueprints'

pub fn setup_storage(mut app data.App) {
	app.storage.data_directory = ensure_data_directory() or {
		println('Couldnt set up data directory!')
		return
	}

	// make sure we have a place to save and load blueprints from / to
	app.storage.blueprints_directory, app.storage.has_blueprints_directory = ensure_blueprints_directory(app.storage.data_directory)

	// index the blueprint directory
	index_blueprint_directory(mut app)
}

fn ensure_data_directory() !string {
	// get the users home directory
	home_dir := os.home_dir()

	// create a .sim3 directory inside of it
	sim3_dir := os.join_path(home_dir, data_dir_name)
	if !os.exists(sim3_dir) {
		os.mkdir(sim3_dir)!
	}

	return sim3_dir
}

fn ensure_blueprints_directory(data_dir string) (string, bool) {
	// create a .sim3 directory inside of it
	blueprints_dir := os.join_path(data_dir, blueprints_dir_name)
	if !os.exists(blueprints_dir) {
		os.mkdir(blueprints_dir) or { return '', false }
	}

	return blueprints_dir, true
}
