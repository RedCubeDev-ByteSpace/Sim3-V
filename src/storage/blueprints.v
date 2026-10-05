module storage

import data
import os
import x.json2
import raylib as rl
import cfg_utils
import math.vec
import time

pub fn index_blueprint_directory(mut app data.App) {
	// do we have a working blueprints dir?
	if !app.storage.has_blueprints_directory {
		return
	}

	// unload the textures of the old dir index
	unload_directory(app.storage.blueprints.blueprint_dir)

	// index!
	app.storage.blueprints.blueprint_dir = index_directory(app, app.storage.blueprints_directory)
}

fn index_directory(app data.App, path string) data.BlueprintDirectory {
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
			dir.blueprint_directories << index_directory(app, file_path)
		}

		// otherwise: is it a json?
		if os.file_ext(file) != '.json' {
			continue // no? -> skip
		}

		// try to read the file
		file_content := os.read_file(file_path) or { continue }

		// try to deserialize it
		mut blueprint := json2.decode[data.Blueprint](file_content) or { panic(err) }
		blueprint.path = file_path
		blueprint.date = time.unix(os.file_last_mod_unix(file_path)).format_ss()
		blueprint.preview = render_preview_texture(app, blueprint.components)

		// store it in the index
		dir.blueprints << blueprint
	}

	return dir
}

fn unload_directory(dir data.BlueprintDirectory) {
	for blueprint in dir.blueprints {
		blueprint.unload_preview_texture()
	}

	for subdir in dir.blueprint_directories {
		unload_directory(subdir)
	}
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
	cfg_utils.normalize_cfgs(mut cfgs)

	blueprint := data.Blueprint{
		name:       name
		components: cfgs
		preview:    render_preview_texture(app, cfgs)
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

fn render_preview_texture(app data.App, cfgs []data.ComponentCfg) rl.Texture2D {
	margin_in_worldspace := 3

	// shift all cfgs over by the margin
	for cfg in cfgs {
		mut icfg := cfg.as_interface()
		icfg.translate_by(vec.vec2(margin_in_worldspace, margin_in_worldspace))
	}

	// get the bottom rightest point in our clipboard
	// -> this gives us the width and height rectangle around all of our components because the top left is always 0,0
	mut bottom_right := cfgs[0].as_interface().get_bottom_right()
	for cfg in cfgs {
		cfg_bottom_right := cfg.as_interface().get_bottom_right()
		if cfg_bottom_right.x > bottom_right.x {
			bottom_right.x = cfg_bottom_right.x
		}
		if cfg_bottom_right.y > bottom_right.y {
			bottom_right.y = cfg_bottom_right.y
		}
	}

	// add the margin to the bottom_right
	bottom_right = bottom_right.add(vec.vec2(margin_in_worldspace, margin_in_worldspace))
	max_preview_side_length := f32(data.blueprint_preview_size - 4)
	zoom := if bottom_right.x > bottom_right.y {
		max_preview_side_length / (bottom_right.x * data.one_simspace_unit_in_px)
	} else {
		max_preview_side_length / (bottom_right.y * data.one_simspace_unit_in_px)
	}

	// create a new render texture for the preview
	render_texture := rl.load_render_texture(550, 550)
	rl.begin_texture_mode(render_texture)
	rl.clear_background(rl.Color{0, 0, 0, 0})

	for cfg in cfgs {
		cfg_utils.draw_component_from_cfg(app, vec.vec2[f32](50, 50), f32(zoom), cfg,
			cfg.color.to_rl(), true)
	}

	rl.end_texture_mode()

	// crop the texture
	img := rl.load_image_from_texture(render_texture.texture)
	rl.unload_render_texture(render_texture)

	rl.image_alpha_crop(&img, 0.1)
	texture := rl.load_texture_from_image(img)
	// rl.set_texture_filter(texture, int(rl.TextureFilter.texture_filter_anisotropic_4x))

	// shift all cfgs back over by the margin
	for cfg in cfgs {
		mut icfg := cfg.as_interface()
		icfg.translate_by(vec.vec2(-margin_in_worldspace, -margin_in_worldspace))
	}

	return texture
}
