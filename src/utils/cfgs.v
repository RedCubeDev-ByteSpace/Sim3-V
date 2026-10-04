module utils

import data

pub fn normalize_cfgs(mut cfgs []data.ComponentCfg) {
	if cfgs.len == 0 {
		return
	}

	// get the toppest and leftest component we've selected
	mut most_toppest_leftest := cfgs[0].as_interface().get_top_left()
	for mut cfg in cfgs {
		top_left := cfg.as_interface().get_top_left()

		// is this point further left? -> use its x coordinate
		if top_left.x < most_toppest_leftest.x {
			most_toppest_leftest.x = top_left.x
		}

		// is this point further up? -> use its y coordinate
		if top_left.y < most_toppest_leftest.y {
			most_toppest_leftest.y = top_left.y
		}
	}

	// shift everything over by - the top left so its at 0,0
	for mut cfg in cfgs {
		mut icfg := cfg.as_interface()
		icfg.translate_by(most_toppest_leftest.mul_scalar(-1))
	}
}

pub fn rotate_cfgs(mut cfgs []data.ComponentCfg) {
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

	// rotate all components
	for mut cfg in cfgs {
		mut icfg := cfg.as_interface()
		icfg.rotate(bottom_right.x, bottom_right.y)
	}

	// get the new top left after doing the rotation
	mut top_left := cfgs[0].as_interface().get_top_left()
	for cfg in cfgs {
		cfg_top_left := cfg.as_interface().get_top_left()
		if cfg_top_left.x < top_left.x {
			top_left.x = cfg_top_left.x
		}
		if cfg_top_left.y < top_left.y {
			top_left.y = cfg_top_left.y
		}
	}

	// shift all components so that the top left is at 0,0 again
	for mut cfg in cfgs {
		mut icfg := cfg.as_interface()
		icfg.translate_by(top_left.mul_scalar(-1))
	}
}
