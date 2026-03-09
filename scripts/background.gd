extends Node2D

const ColorFx = preload("res://scripts/color_fx.gd")

var playfield_rect := Rect2(24.0, 24.0, 560.0, 912.0)
var stars: Array = []
var embers: Array = []
var time_passed := 0.0
var danger_level := 0.0
var stage_index := 1
var pulse_timer := 0.0
var pulse_duration := 0.0
var pulse_color := Color(1.0, 1.0, 1.0, 0.0)

func configure(rect: Rect2) -> void:
	playfield_rect = rect

func set_stage_theme(new_stage_index: int) -> void:
	stage_index = new_stage_index
	queue_redraw()

func set_danger_level(level: float) -> void:
	danger_level = clamp(level, 0.0, 1.0)

func trigger_pulse(effect_color: Color, strength := 0.35, effect_duration := 0.45) -> void:
	pulse_color = ColorFx.alpha(effect_color, strength)
	pulse_duration = effect_duration
	pulse_timer = effect_duration

func _ready() -> void:
	if stars.is_empty():
		for index in range(120):
			stars.append({
				"position": Vector2(
					randf_range(playfield_rect.position.x + 6.0, playfield_rect.position.x + playfield_rect.size.x - 6.0),
					randf_range(playfield_rect.position.y, playfield_rect.position.y + playfield_rect.size.y)
				),
				"speed": randf_range(18.0, 145.0),
				"size": randf_range(1.0, 2.8),
				"twinkle": randf() * TAU,
				"layer": index % 3
			})
	if embers.is_empty():
		for _index in range(60):
			embers.append({
				"position": Vector2(
					randf_range(playfield_rect.position.x, playfield_rect.position.x + playfield_rect.size.x),
					randf_range(playfield_rect.position.y, playfield_rect.position.y + playfield_rect.size.y)
				),
				"speed": randf_range(28.0, 80.0),
				"size": randf_range(2.0, 4.5),
				"phase": randf() * TAU
			})

func _process(delta: float) -> void:
	time_passed += delta
	if pulse_timer > 0.0:
		pulse_timer = max(0.0, pulse_timer - delta)
	for star in stars:
		var star_position: Vector2 = star["position"]
		star_position.y += star["speed"] * delta * (1.0 + danger_level * 0.25)
		if star_position.y > playfield_rect.position.y + playfield_rect.size.y + 4.0:
			star_position.y = playfield_rect.position.y - 4.0
			star_position.x = randf_range(playfield_rect.position.x + 6.0, playfield_rect.position.x + playfield_rect.size.x - 6.0)
		star["position"] = star_position
	for ember in embers:
		var ember_position: Vector2 = ember["position"]
		ember_position.y += ember["speed"] * delta * (0.9 + danger_level * 0.35)
		ember_position.x += sin(time_passed * 0.8 + ember["phase"]) * delta * 14.0
		if ember_position.y > playfield_rect.position.y + playfield_rect.size.y + 8.0:
			ember_position.y = playfield_rect.position.y - 8.0
			ember_position.x = randf_range(playfield_rect.position.x, playfield_rect.position.x + playfield_rect.size.x)
		ember["position"] = ember_position
	queue_redraw()

func _draw() -> void:
	var palette: Dictionary = _palette_for_stage(stage_index)
	var rect_end: Vector2 = playfield_rect.position + playfield_rect.size
	var base_color: Color = palette["base"]
	var accent_color: Color = palette["accent"]
	var line_color: Color = palette["line"]
	draw_rect(playfield_rect, base_color, true)
	if stage_index == 1:
		_draw_stage_one(rect_end, accent_color, line_color)
	elif stage_index == 2:
		_draw_stage_two(rect_end, accent_color, line_color)
	elif stage_index == 3:
		_draw_stage_three(rect_end, accent_color, line_color)
	elif stage_index == 4:
		_draw_stage_four(rect_end, accent_color, line_color)
	else:
		_draw_stage_five(rect_end, accent_color, line_color)
	var pulse_alpha: float = 0.0
	if pulse_timer > 0.0 and pulse_duration > 0.0:
		pulse_alpha = sin(clamp((pulse_duration - pulse_timer) / pulse_duration, 0.0, 1.0) * PI) * pulse_color.a
		if pulse_alpha > 0.001:
			draw_rect(playfield_rect, ColorFx.alpha(pulse_color, pulse_alpha), true)

func _draw_stage_one(rect_end: Vector2, accent_color: Color, line_color: Color) -> void:
	for stripe in range(14):
		var stripe_y: float = playfield_rect.position.y + fposmod(time_passed * 38.0 + float(stripe) * 72.0, playfield_rect.size.y)
		draw_line(
			Vector2(playfield_rect.position.x, stripe_y),
			Vector2(rect_end.x, stripe_y),
			ColorFx.alpha(accent_color, 0.08 + 0.01 * float(stripe % 3)),
			1.0,
			true
		)
	for diagonal in range(11):
		var diagonal_x: float = playfield_rect.position.x - 160.0 + fposmod(time_passed * 56.0 + float(diagonal) * 92.0, playfield_rect.size.x + 220.0)
		draw_line(
			Vector2(diagonal_x, playfield_rect.position.y),
			Vector2(diagonal_x + 180.0, rect_end.y),
			ColorFx.alpha(line_color, 0.05 + 0.02 * danger_level),
			1.2,
			true
		)
	for band in range(4):
		var center := Vector2(
			playfield_rect.position.x + playfield_rect.size.x * (0.18 + 0.22 * float(band)),
			playfield_rect.position.y + fposmod(time_passed * (22.0 + float(band) * 5.0) + float(band) * 180.0, playfield_rect.size.y)
		)
		draw_circle(center, 90.0 + float(band) * 18.0, ColorFx.alpha(accent_color, 0.04))
	for star in stars:
		var pulse: float = 0.65 + 0.35 * sin(time_passed * 2.0 + star["twinkle"])
		var layer_boost: float = 0.15 * float(star["layer"])
		var star_color := Color(0.78 + layer_boost, 0.86 + danger_level * 0.1, 1.0, 0.55 + pulse * 0.35)
		draw_circle(star["position"], star["size"] * pulse, star_color)

func _draw_stage_two(rect_end: Vector2, accent_color: Color, line_color: Color) -> void:
	for column in range(8):
		var phase: float = time_passed * (0.6 + float(column) * 0.08) + float(column) * 0.5
		var x: float = playfield_rect.position.x + 28.0 + float(column) * 72.0 + sin(phase) * 18.0
		draw_line(
			Vector2(x, playfield_rect.position.y),
			Vector2(x, rect_end.y),
			ColorFx.alpha(accent_color, 0.08 + 0.05 * danger_level),
			1.6,
			true
		)
	for ring_index in range(7):
		var center := Vector2(
			playfield_rect.position.x + playfield_rect.size.x * 0.5 + sin(time_passed * 0.5 + float(ring_index)) * 70.0,
			playfield_rect.position.y + 120.0 + float(ring_index) * 108.0
		)
		draw_arc(center, 48.0 + sin(time_passed + float(ring_index)) * 12.0, 0.0, TAU, 40, ColorFx.alpha(line_color, 0.07 + 0.03 * danger_level), 2.0, true)
	for ember in embers:
		var flicker: float = 0.65 + 0.35 * sin(time_passed * 4.0 + ember["phase"])
		var ember_color := Color(1.0, 0.76 + danger_level * 0.12, 0.46, 0.35 + flicker * 0.28)
		draw_circle(ember["position"], ember["size"] * flicker, ember_color)
		if ember["size"] > 3.0:
			draw_line(ember["position"] + Vector2(0.0, -8.0), ember["position"] + Vector2(0.0, 8.0), ColorFx.alpha(ember_color, 0.18), 1.0, true)
	for band in range(5):
		var y: float = playfield_rect.position.y + fposmod(time_passed * 94.0 + float(band) * 176.0, playfield_rect.size.y)
		draw_line(Vector2(playfield_rect.position.x, y), Vector2(rect_end.x, y), ColorFx.alpha(accent_color, 0.04), 1.0, true)

func _draw_stage_three(rect_end: Vector2, accent_color: Color, line_color: Color) -> void:
	for ring_index in range(6):
		var ring_center := Vector2(
			playfield_rect.position.x + playfield_rect.size.x * 0.5 + sin(time_passed * 0.7 + float(ring_index) * 0.5) * 84.0,
			playfield_rect.position.y + 84.0 + float(ring_index) * 128.0
		)
		draw_arc(ring_center, 56.0 + cos(time_passed * 1.2 + float(ring_index)) * 14.0, 0.0, TAU, 52, ColorFx.alpha(accent_color, 0.08 + 0.02 * danger_level), 2.2, true)
	for column in range(9):
		var x: float = playfield_rect.position.x + 26.0 + float(column) * 64.0 + sin(time_passed * 0.9 + float(column)) * 12.0
		draw_line(Vector2(x, playfield_rect.position.y), Vector2(x, rect_end.y), ColorFx.alpha(line_color, 0.06 + 0.03 * danger_level), 1.4, true)
	for shard in range(12):
		var shard_y: float = playfield_rect.position.y + fposmod(time_passed * (72.0 + float(shard % 4) * 8.0) + float(shard) * 88.0, playfield_rect.size.y)
		var shard_x: float = playfield_rect.position.x + 48.0 + float(shard % 6) * 92.0
		draw_line(Vector2(shard_x - 18.0, shard_y - 24.0), Vector2(shard_x + 18.0, shard_y + 24.0), ColorFx.alpha(accent_color, 0.1), 1.6, true)
		if shard % 2 == 0:
			draw_line(Vector2(shard_x + 18.0, shard_y - 24.0), Vector2(shard_x - 18.0, shard_y + 24.0), ColorFx.alpha(line_color, 0.08), 1.0, true)
	for star in stars:
		var pulse: float = 0.6 + 0.4 * sin(time_passed * 2.6 + star["twinkle"])
		var star_color := Color(0.82 + 0.1 * float(star["layer"]), 0.8, 1.0, 0.42 + pulse * 0.3)
		draw_circle(star["position"], star["size"] * pulse, star_color)

func _draw_stage_four(rect_end: Vector2, accent_color: Color, line_color: Color) -> void:
	for column in range(10):
		var x: float = playfield_rect.position.x + 18.0 + float(column) * 58.0 + sin(time_passed * 1.2 + float(column)) * 10.0
		draw_line(Vector2(x, playfield_rect.position.y), Vector2(x, rect_end.y), ColorFx.alpha(line_color, 0.08 + 0.04 * danger_level), 1.4, true)
	for band in range(8):
		var y: float = playfield_rect.position.y + 42.0 + float(band) * 108.0 + sin(time_passed * 0.9 + float(band)) * 16.0
		draw_arc(Vector2(playfield_rect.position.x + playfield_rect.size.x * 0.5, y), 76.0 + float(band) * 5.0, PI * 0.1, PI * 0.9, 34, ColorFx.alpha(accent_color, 0.08), 2.0, true)
		draw_arc(Vector2(playfield_rect.position.x + playfield_rect.size.x * 0.5, y), 76.0 + float(band) * 5.0, PI * 1.1, PI * 1.9, 34, ColorFx.alpha(line_color, 0.07), 1.4, true)
	for shard in range(14):
		var shard_phase: float = time_passed * (0.7 + float(shard % 4) * 0.08) + float(shard)
		var center := Vector2(
			playfield_rect.position.x + 50.0 + fposmod(float(shard) * 41.0 + time_passed * 30.0, playfield_rect.size.x - 100.0),
			playfield_rect.position.y + 50.0 + fposmod(float(shard) * 67.0 + time_passed * 52.0, playfield_rect.size.y - 100.0)
		)
		var reach: float = 16.0 + sin(shard_phase) * 6.0
		draw_line(center + Vector2(-reach, -reach), center + Vector2(reach, reach), ColorFx.alpha(accent_color, 0.12), 1.6, true)
		draw_line(center + Vector2(reach, -reach), center + Vector2(-reach, reach), ColorFx.alpha(line_color, 0.09), 1.0, true)
	for ember in embers:
		var flicker: float = 0.62 + 0.38 * sin(time_passed * 4.6 + ember["phase"])
		var ember_color := Color(1.0, 0.72, 0.62, 0.28 + flicker * 0.26)
		draw_circle(ember["position"], ember["size"] * flicker, ember_color)
	for star in stars:
		var pulse: float = 0.55 + 0.45 * sin(time_passed * 2.8 + star["twinkle"])
		var star_color := Color(0.92, 0.84 + 0.05 * float(star["layer"]), 1.0, 0.36 + pulse * 0.28)
		draw_circle(star["position"], star["size"] * pulse, star_color)

func _draw_stage_five(rect_end: Vector2, accent_color: Color, line_color: Color) -> void:
	for ring in range(9):
		var center := Vector2(
			playfield_rect.position.x + playfield_rect.size.x * 0.5 + sin(time_passed * 0.8 + float(ring)) * 64.0,
			playfield_rect.position.y + 72.0 + float(ring) * 96.0
		)
		var radius: float = 54.0 + float(ring % 3) * 18.0 + sin(time_passed * 1.4 + float(ring)) * 6.0
		draw_arc(center, radius, 0.0, TAU, 52, ColorFx.alpha(accent_color, 0.08 + 0.02 * danger_level), 2.0, true)
	for lane in range(11):
		var x: float = playfield_rect.position.x + 14.0 + float(lane) * 52.0 + sin(time_passed * 1.1 + float(lane) * 0.6) * 8.0
		draw_line(Vector2(x, playfield_rect.position.y), Vector2(x, rect_end.y), ColorFx.alpha(line_color, 0.08), 1.2, true)
	for shard in range(16):
		var t: float = time_passed * (0.6 + float(shard % 5) * 0.05) + float(shard)
		var center := Vector2(
			playfield_rect.position.x + 40.0 + fposmod(float(shard) * 33.0 + time_passed * 26.0, playfield_rect.size.x - 80.0),
			playfield_rect.position.y + 30.0 + fposmod(float(shard) * 59.0 + time_passed * 48.0, playfield_rect.size.y - 60.0)
		)
		var reach: float = 12.0 + sin(t) * 7.0
		draw_line(center + Vector2(-reach, 0.0), center + Vector2(reach, 0.0), ColorFx.alpha(accent_color, 0.12), 1.8, true)
		draw_line(center + Vector2(0.0, -reach), center + Vector2(0.0, reach), ColorFx.alpha(line_color, 0.1), 1.0, true)
	for ember in embers:
		var flicker: float = 0.58 + 0.42 * sin(time_passed * 5.2 + ember["phase"])
		var ember_color := Color(1.0, 0.66, 0.7, 0.24 + flicker * 0.28)
		draw_circle(ember["position"], ember["size"] * flicker, ember_color)
	for star in stars:
		var pulse: float = 0.6 + 0.4 * sin(time_passed * 3.0 + star["twinkle"])
		var star_color := Color(1.0, 0.9, 0.96, 0.34 + pulse * 0.3)
		draw_circle(star["position"], star["size"] * pulse, star_color)

func _palette_for_stage(current_stage_index: int) -> Dictionary:
	if current_stage_index == 2:
		return {
			"base": Color(0.06, 0.03, 0.09, 1.0),
			"accent": Color(0.34, 0.90, 1.0, 0.28),
			"line": Color(1.0, 0.64, 0.38, 0.22)
		}
	if current_stage_index == 3:
		return {
			"base": Color(0.035, 0.03, 0.08, 1.0),
			"accent": Color(0.72, 0.56, 1.0, 0.26),
			"line": Color(0.48, 0.94, 1.0, 0.2)
		}
	if current_stage_index == 4:
		return {
			"base": Color(0.06, 0.02, 0.035, 1.0),
			"accent": Color(1.0, 0.54, 0.5, 0.24),
			"line": Color(0.74, 0.92, 1.0, 0.18)
		}
	if current_stage_index == 5:
		return {
			"base": Color(0.04, 0.015, 0.05, 1.0),
			"accent": Color(1.0, 0.5, 0.68, 0.24),
			"line": Color(0.78, 0.94, 1.0, 0.2)
		}
	return {
		"base": Color(0.02, 0.025, 0.07, 1.0),
		"accent": Color(0.10, 0.22 + danger_level * 0.08, 0.42 + danger_level * 0.15, 0.35),
		"line": Color(0.40, 0.82, 1.0, 0.16)
	}
