extends Control

const ColorFx = preload("res://scripts/color_fx.gd")

var accent_color := Color(0.88, 0.52, 0.78)
var secondary_color := Color(0.56, 0.92, 1.0)
var side: String = "right"
var mood: String = "calm"
var motif: String = "ribbon"
var title: String = ""
var time_passed := 0.0

func configure(data: Dictionary) -> void:
	accent_color = data.get("accent_color", accent_color)
	secondary_color = data.get("secondary_color", secondary_color)
	side = str(data.get("side", side))
	mood = str(data.get("mood", mood))
	motif = str(data.get("motif", motif))
	title = str(data.get("title", title))
	queue_redraw()

func _process(delta: float) -> void:
	time_passed += delta
	if visible:
		queue_redraw()

func _draw() -> void:
	var center := size * Vector2(0.5, 0.55)
	var direction := -1.0 if side == "left" else 1.0
	var glow_radius: float = min(size.x, size.y) * 0.42
	draw_circle(center + Vector2(18.0 * direction, -10.0), glow_radius, ColorFx.alpha(accent_color, 0.07))
	var shoulder := PackedVector2Array([
		center + Vector2(-102.0, 118.0),
		center + Vector2(108.0, 126.0),
		center + Vector2(72.0, 24.0),
		center + Vector2(-78.0, 18.0)
	])
	draw_colored_polygon(shoulder, ColorFx.alpha(accent_color.darkened(0.25), 0.88))
	var hair := PackedVector2Array([
		center + Vector2(-76.0, -48.0),
		center + Vector2(-18.0, -122.0),
		center + Vector2(62.0, -96.0),
		center + Vector2(92.0, -12.0),
		center + Vector2(56.0, 92.0),
		center + Vector2(-62.0, 76.0)
	])
	draw_colored_polygon(hair, ColorFx.alpha(accent_color, 0.9))
	draw_circle(center + Vector2(8.0 * direction, -22.0), 58.0, ColorFx.alpha(Color(1.0, 0.95, 0.98), 0.95))
	var eye_y: float = -28.0 + sin(time_passed * 2.2) * 1.2
	var left_eye := center + Vector2(-14.0, eye_y)
	var right_eye := center + Vector2(24.0, eye_y - 2.0)
	var eye_color := secondary_color
	if mood == "angry":
		eye_color = Color(1.0, 0.72, 0.42)
	elif mood == "soft":
		eye_color = Color(0.76, 0.94, 1.0)
	draw_line(left_eye + Vector2(-8.0, -2.0), left_eye + Vector2(4.0, 0.0), eye_color, 2.0, true)
	draw_line(right_eye + Vector2(-4.0, 0.0), right_eye + Vector2(8.0, -2.0), eye_color, 2.0, true)
	draw_arc(center + Vector2(4.0, 14.0), 12.0, 0.2, PI - 0.2, 14, ColorFx.alpha(accent_color.darkened(0.4), 0.55), 1.5, true)
	match motif:
		"ribbon":
			_draw_ribbon(center, direction)
		"halo":
			_draw_halo(center)
		"crown":
			_draw_crown(center)
		"gear":
			_draw_gear(center)
		_:
			_draw_ribbon(center, direction)
	for sparkle_index in range(5):
		var angle: float = time_passed * 0.5 + float(sparkle_index) * TAU / 5.0
		var sparkle_pos: Vector2 = center + Vector2.RIGHT.rotated(angle) * (84.0 + 10.0 * sin(time_passed * 2.4 + float(sparkle_index)))
		draw_circle(sparkle_pos, 2.4, ColorFx.alpha(secondary_color, 0.45))

func _draw_ribbon(center: Vector2, direction: float) -> void:
	var bow_center := center + Vector2(48.0 * direction, -74.0)
	var left_wing := PackedVector2Array([
		bow_center,
		bow_center + Vector2(-34.0, -20.0),
		bow_center + Vector2(-28.0, 18.0)
	])
	var right_wing := PackedVector2Array([
		bow_center,
		bow_center + Vector2(34.0, -20.0),
		bow_center + Vector2(28.0, 18.0)
	])
	draw_colored_polygon(left_wing, ColorFx.alpha(secondary_color, 0.92))
	draw_colored_polygon(right_wing, ColorFx.alpha(secondary_color, 0.92))
	draw_circle(bow_center, 9.0, ColorFx.alpha(accent_color.darkened(0.2), 0.95))

func _draw_halo(center: Vector2) -> void:
	draw_arc(center + Vector2(0.0, -90.0), 52.0, 0.0, TAU, 36, ColorFx.alpha(secondary_color, 0.48), 3.0, true)
	draw_arc(center + Vector2(0.0, -90.0), 40.0, 0.0, TAU, 28, ColorFx.alpha(accent_color, 0.28), 1.5, true)

func _draw_crown(center: Vector2) -> void:
	var crown := PackedVector2Array([
		center + Vector2(-38.0, -86.0),
		center + Vector2(-18.0, -118.0),
		center + Vector2(0.0, -94.0),
		center + Vector2(18.0, -120.0),
		center + Vector2(38.0, -86.0),
		center + Vector2(34.0, -72.0),
		center + Vector2(-34.0, -72.0)
	])
	draw_colored_polygon(crown, ColorFx.alpha(secondary_color, 0.9))

func _draw_gear(center: Vector2) -> void:
	for tooth_index in range(8):
		var angle: float = float(tooth_index) * TAU / 8.0 + time_passed * 0.18
		var pos: Vector2 = center + Vector2.RIGHT.rotated(angle) * 74.0
		draw_rect(Rect2(pos - Vector2(5.0, 10.0), Vector2(10.0, 20.0)), ColorFx.alpha(secondary_color, 0.55), true)
	draw_arc(center, 72.0, 0.0, TAU, 40, ColorFx.alpha(secondary_color, 0.55), 3.0, true)
