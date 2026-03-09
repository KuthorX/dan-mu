extends Node2D

const ColorFx = preload("res://scripts/color_fx.gd")

var mode: StringName = &"ring"
var color: Color = Color.WHITE
var duration := 0.5
var age := 0.0
var start_radius := 8.0
var end_radius := 60.0
var line_width := 3.0
var shard_seed := 0.0
var shard_count := 10
var shard_size := 18.0
var spark_length := 24.0

func configure_ring(effect_color: Color, from_radius: float, to_radius: float, effect_duration := 0.45, width := 3.0):
	mode = &"ring"
	color = effect_color
	start_radius = from_radius
	end_radius = to_radius
	duration = effect_duration
	line_width = width
	return self

func configure_explosion(effect_color: Color, size := 22.0, effect_duration := 0.55, fragments := 10):
	mode = &"explosion"
	color = effect_color
	shard_size = size
	duration = effect_duration
	shard_count = fragments
	shard_seed = randf() * TAU
	return self

func configure_sparks(effect_color: Color, length := 28.0, effect_duration := 0.35, fragments := 12):
	mode = &"sparks"
	color = effect_color
	spark_length = length
	duration = effect_duration
	shard_count = fragments
	shard_seed = randf() * TAU
	return self

func _process(delta: float) -> void:
	age += delta
	if age >= duration:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t: float = clamp(age / max(duration, 0.001), 0.0, 1.0)
	match mode:
		&"ring":
			var ring_radius: float = lerpf(start_radius, end_radius, t)
			var alpha: float = 1.0 - t
			draw_arc(Vector2.ZERO, ring_radius, 0.0, TAU, 56, ColorFx.alpha(color, alpha), line_width, true)
			if line_width > 1.5:
				draw_arc(Vector2.ZERO, ring_radius * 0.82, 0.0, TAU, 40, ColorFx.alpha(color, alpha * 0.4), max(1.0, line_width * 0.5), true)
		&"explosion":
			var flash: float = shard_size * (1.0 - t * 0.7)
			draw_circle(Vector2.ZERO, max(2.0, flash * 0.28), ColorFx.alpha(color, (1.0 - t) * 0.95))
			for index in range(shard_count):
				var angle: float = shard_seed + TAU * float(index) / float(max(1, shard_count))
				angle += sin(t * TAU * 2.0 + float(index)) * 0.18
				var distance: float = lerpf(4.0, shard_size * 2.6, t)
				var shard_position: Vector2 = Vector2.RIGHT.rotated(angle) * distance
				var shard_radius: float = max(1.2, shard_size * (1.0 - t) * (0.18 + 0.06 * float(index % 3)))
				draw_circle(shard_position, shard_radius, ColorFx.alpha(color, (1.0 - t) * 0.8))
				draw_circle(shard_position * 0.6, shard_radius * 0.6, ColorFx.alpha(color.lightened(0.25), (1.0 - t) * 0.45))
		&"sparks":
			for index in range(shard_count):
				var spark_angle: float = shard_seed + TAU * float(index) / float(max(1, shard_count))
				spark_angle += sin(float(index) * 0.9 + t * 7.0) * 0.12
				var start_distance: float = lerpf(2.0, spark_length * 0.3, t)
				var end_distance: float = lerpf(10.0, spark_length, t)
				var start_point: Vector2 = Vector2.RIGHT.rotated(spark_angle) * start_distance
				var end_point: Vector2 = Vector2.RIGHT.rotated(spark_angle) * end_distance
				var spark_alpha: float = (1.0 - t) * (0.85 - float(index % 3) * 0.08)
				draw_line(start_point, end_point, ColorFx.alpha(color, spark_alpha), 2.2, true)
				draw_circle(end_point, 1.6, ColorFx.alpha(color, spark_alpha * 0.8))
