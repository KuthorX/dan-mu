extends Node2D

## The playfield as a hanging scroll unrolling at night: an ink landscape per stage
## (painted by tools/art/gen_art.py) scrolls down under a few drifting specks.
## Everything here stays dark and low-contrast so bullets always own the foreground.

const ColorFx = preload("res://scripts/color_fx.gd")
const STAGE_TEXTURES := [
	preload("res://art/bg/stage1.png"),
	preload("res://art/bg/stage2.png"),
	preload("res://art/bg/stage3.png"),
	preload("res://art/bg/stage4.png"),
	preload("res://art/bg/stage5.png"),
]
## Speck tint per stage (the painting's own mist colour, lifted).
const SPECK_TINTS := [
	Color(0.62, 0.70, 0.95, 0.55),
	Color(1.0, 0.62, 0.42, 0.45),
	Color(0.74, 0.66, 0.95, 0.5),
	Color(0.95, 0.52, 0.56, 0.45),
	Color(0.45, 0.95, 0.88, 0.42),
]
const SCROLL_SPEED := 22.0
const SPECK_COUNT := 36

var playfield_rect := Rect2(24.0, 24.0, 560.0, 912.0)
var specks: Array = []
var time_passed := 0.0
var danger_level := 0.0
var stage_index := 1
var scroll := 0.0
var pulse_timer := 0.0
var pulse_duration := 0.0
var pulse_color := Color(1.0, 1.0, 1.0, 0.0)

func configure(rect: Rect2) -> void:
	playfield_rect = rect

func set_stage_theme(new_stage_index: int) -> void:
	stage_index = clamp(new_stage_index, 1, STAGE_TEXTURES.size())
	queue_redraw()

func set_danger_level(level: float) -> void:
	danger_level = clamp(level, 0.0, 1.0)

func trigger_pulse(effect_color: Color, strength := 0.35, effect_duration := 0.45) -> void:
	pulse_color = ColorFx.alpha(effect_color, strength * 0.6)
	pulse_duration = effect_duration
	pulse_timer = effect_duration

func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	for _index in range(SPECK_COUNT):
		specks.append({
			"position": Vector2(randf_range(0.0, playfield_rect.size.x), randf_range(0.0, playfield_rect.size.y)),
			"speed": randf_range(30.0, 90.0),
			"phase": randf() * TAU,
		})

func _process(delta: float) -> void:
	time_passed += delta
	var pace: float = 1.0 + danger_level * 0.6
	scroll += SCROLL_SPEED * pace * delta
	if pulse_timer > 0.0:
		pulse_timer = max(0.0, pulse_timer - delta)
	for speck in specks:
		var speck_position: Vector2 = speck["position"]
		speck_position.y = fposmod(speck_position.y + speck["speed"] * pace * delta, playfield_rect.size.y)
		speck_position.x = fposmod(speck_position.x + sin(time_passed * 0.7 + speck["phase"]) * delta * 10.0, playfield_rect.size.x)
		speck["position"] = speck_position
	queue_redraw()

func _draw() -> void:
	var painting: Texture2D = STAGE_TEXTURES[stage_index - 1]
	draw_texture_rect_region(painting, playfield_rect, Rect2(0.0, -scroll, playfield_rect.size.x, playfield_rect.size.y))
	var speck_color: Color = SPECK_TINTS[stage_index - 1]
	for speck in specks:
		var flicker: float = 0.5 + 0.5 * sin(time_passed * 3.0 + speck["phase"])
		draw_rect(Rect2(playfield_rect.position + speck["position"], Vector2(2.0, 2.0)), Color(speck_color.r, speck_color.g, speck_color.b, 0.12 + 0.18 * flicker))
	if pulse_timer > 0.0 and pulse_duration > 0.0:
		var pulse_alpha: float = sin(clamp((pulse_duration - pulse_timer) / pulse_duration, 0.0, 1.0) * PI) * pulse_color.a
		if pulse_alpha > 0.001:
			draw_rect(playfield_rect, ColorFx.alpha(pulse_color, pulse_alpha), true)
