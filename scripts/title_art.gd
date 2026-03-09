extends Control

const ColorFx = preload("res://scripts/color_fx.gd")

var accent_color := Color(0.56, 0.92, 1.0)
var secondary_color := Color(1.0, 0.74, 0.48)
var time_passed := 0.0

func set_palette(primary: Color, secondary: Color) -> void:
	accent_color = primary
	secondary_color = secondary
	queue_redraw()

func _process(delta: float) -> void:
	time_passed += delta
	if visible:
		queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	var base_radius: float = min(size.x, size.y) * 0.28
	var pulse: float = 1.0 + sin(time_passed * 1.5) * 0.05
	draw_circle(center, base_radius * 1.55, ColorFx.alpha(accent_color, 0.05))
	for ring_index in range(3):
		var radius: float = base_radius * (0.78 + float(ring_index) * 0.34) * pulse
		var start_angle: float = time_passed * (0.25 + 0.14 * float(ring_index)) + float(ring_index) * 0.7
		var sweep: float = PI * (1.1 + 0.12 * float(ring_index))
		draw_arc(center, radius, start_angle, start_angle + sweep, 48, ColorFx.alpha(accent_color, 0.30 - 0.06 * float(ring_index)), 2.0, true)
		draw_arc(center, radius + 10.0, -start_angle * 1.3, -start_angle * 1.3 + sweep * 0.75, 40, ColorFx.alpha(secondary_color, 0.22 - 0.04 * float(ring_index)), 1.6, true)
	for spoke_index in range(12):
		var angle: float = TAU * float(spoke_index) / 12.0 + time_passed * 0.22
		var inner: Vector2 = center + Vector2.RIGHT.rotated(angle) * (base_radius * 0.58)
		var outer: Vector2 = center + Vector2.RIGHT.rotated(angle) * (base_radius * 1.18 + sin(time_passed * 1.7 + float(spoke_index)) * 10.0)
		draw_line(inner, outer, ColorFx.alpha(accent_color, 0.16), 1.4, true)
	var star := PackedVector2Array()
	for point_index in range(10):
		var local_radius: float = base_radius * (0.36 if point_index % 2 == 0 else 0.16)
		var angle: float = -PI * 0.5 + TAU * float(point_index) / 10.0 + time_passed * 0.35
		star.append(center + Vector2.RIGHT.rotated(angle) * local_radius)
	draw_colored_polygon(star, ColorFx.alpha(secondary_color, 0.28))
	for stripe_index in range(5):
		var y: float = center.y - 92.0 + float(stripe_index) * 44.0 + sin(time_passed * 1.3 + float(stripe_index)) * 6.0
		draw_line(Vector2(center.x - 200.0, y), Vector2(center.x + 200.0, y), ColorFx.alpha(accent_color, 0.07), 1.0, true)
