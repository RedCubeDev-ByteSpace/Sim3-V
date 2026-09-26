module simview

import data
import utils
import gg
import math.vec

// simview -------------------------------------------------------------------------------------------------------------
// this module is all about the drawing side of things
// it supplies all the objects that are drawable in the simulation space
// it also takes care of rendering those objects to the screen and drawing the background grid

pub fn draw_view(app data.App) {
	// first: draw the background grid
	draw_grid(app)

	draw_components(app)
}

fn draw_components(app data.App) {
	// get the AABB for the current viewport
	view_aabb := utils.get_viewport_aabb(app)

	for comp in app.sim.components {
		// only draw components that are touching the current viewports aabb
		if utils.do_aabbs_intersect(view_aabb, comp.get_aabb()) {
			comp.draw(app)

			// if enabled: draw bounding boxes
			if app.view.debug.show_aabb {
				draw_aabb(app, comp.get_aabb())
			}
		}
	}
}

fn draw_aabb(app data.App, aabb data.AABB) {
	top_left := utils.worldspace_to_screenspace(app, vec.vec2[f32](aabb.x, aabb.y))
	zoomed_unit := data.one_simspace_unit_in_px * app.view.zoom
	app.gg.draw_rect_empty(top_left.x, top_left.y, aabb.width * zoomed_unit, aabb.height * zoomed_unit,
		data.aabb_color)
}
