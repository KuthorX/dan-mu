extends Node2D

## Flat lacquer-black behind the whole screen; the playfield painting and the
## washi strip are the only two materials mounted on it.

const FRAME_COLOR := Color(0.075, 0.03, 0.028)

var screen_size := Vector2(960.0, 960.0)

func configure(new_screen_size: Vector2, _rect: Rect2):
	screen_size = new_screen_size
	z_index = -3
	return self

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, screen_size), FRAME_COLOR, true)
