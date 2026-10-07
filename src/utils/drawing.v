module utils

import data
import math.vec

pub fn get_aabb_offset_for_rotation(x f32, y f32, w f32, h f32, rot data.Rotation) vec.Vec2[f32] {
	match rot {
		.up {
			return vec.vec2(x, y)
		}
		.down {
			return vec.vec2(-x - w, -y - h)
		}
		.right {
			return vec.vec2(-y - h, x)
		}
		.left {
			return vec.vec2(y, -x - w)
		}
	}
}

pub fn translate_point(pos vec.Vec2[int], x int, y int, rot data.Rotation) (int, int) {
	match rot {
		.up {
			return pos.x + x, pos.y + y
		}
		.down {
			return pos.x - x, pos.y - y
		}
		.right {
			return pos.x - y, pos.y + x
		}
		.left {
			return pos.x + y, pos.y - x
		}
	}
}
