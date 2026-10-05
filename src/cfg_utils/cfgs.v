module cfg_utils

import data
import components
import utils
import math.vec
import raylib as rl

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

pub fn draw_component_from_cfg(app data.App, screen_pos vec.Vec2[f32], zoom f32, cfg data.ComponentCfg, color rl.Color, single_pixel_wires bool) {
	// prepare the variables needed for drawing any components
	zoomed_unit := data.one_simspace_unit_in_px * zoom

	match cfg {
		data.SwitchCfg {
			offset := utils.vi_to_vf(cfg.pos).mul_scalar(zoomed_unit)
			components.Switch.draw(screen_pos.add(offset), zoomed_unit, color, cfg.state,
				data.Rotation.from_int(cfg.rot))
		}
		data.FixedContactCfg {
			offset := utils.vi_to_vf(cfg.pos).mul_scalar(zoomed_unit)
			components.FixedContact.draw(app, screen_pos.add(offset), zoomed_unit, color,
				cfg.state, data.Rotation.from_int(cfg.rot))
		}
		data.ClockCfg {
			offset := utils.vi_to_vf(cfg.pos).mul_scalar(zoomed_unit)
			components.Clock.draw(screen_pos.add(offset), zoomed_unit, color, 0, cfg.frequency,
				data.Rotation.from_int(cfg.rot))
		}
		data.LEDCfg {
			offset := utils.vi_to_vf(cfg.pos).mul_scalar(zoomed_unit)
			components.LED.draw(screen_pos.add(offset), zoomed_unit, color, false, data.Rotation.from_int(cfg.rot))
		}
		data.ChipCfg {
			offset := utils.vi_to_vf(cfg.pos).mul_scalar(zoomed_unit)
			components.Chip.draw(app, screen_pos.add(offset), zoomed_unit, color, data.Rotation.from_int(cfg.rot),
				cfg.chip_uid, []data.ContactPoint{})
		}
		data.WireCfg {
			wire_from := utils.vi_to_vf(cfg.wire_from).mul_scalar(zoomed_unit)
			wire_to := utils.vi_to_vf(cfg.wire_to).mul_scalar(zoomed_unit)
			components.Wire.draw(utils.vf_to_vi(wire_from.add(screen_pos)), utils.vf_to_vi(wire_to.add(screen_pos)),
				zoom, .low, color, single_pixel_wires)
		}
		data.BusCfg {
			wire_from := utils.vi_to_vf(cfg.wire_from).mul_scalar(zoomed_unit)
			wire_to := utils.vi_to_vf(cfg.wire_to).mul_scalar(zoomed_unit)
			components.Bus.draw(utils.vf_to_vi(wire_from.add(screen_pos)), utils.vf_to_vi(wire_to.add(screen_pos)),
				zoom, color, single_pixel_wires)
		}
	}
}
