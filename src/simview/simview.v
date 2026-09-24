module simview

import data

// simview -------------------------------------------------------------------------------------------------------------
// this module is all about the drawing side of things
// it supplies all the objects that are drawable in the simulation space
// it also takes care of rendering those objects to the screen and drawing the background grid

pub fn draw_view(app data.App) {
	// first: draw the background grid
	draw_grid(app)
}
