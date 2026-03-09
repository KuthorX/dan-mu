extends Node2D

const ColorFx = preload("res://scripts/color_fx.gd")

var game = null
var pickup_type: StringName = &"point"
var radius := 11.0
var velocity := Vector2.ZERO
var age := 0.0
var homing := false
var collected := false
var spin := 0.0

func setup(game_ref, spawn_position: Vector2, kind: StringName, options := {}):
	game = game_ref
	global_position = spawn_position
	pickup_type = kind
	velocity = options.get("velocity", Vector2(randf_range(-45.0, 45.0), randf_range(-120.0, -70.0)))
	radius = options.get("radius", 11.0)
	spin = randf() * TAU
	return self

func _enter_tree() -> void:
	if game:
		game.register_pickup(self)

func _exit_tree() -> void:
	if game:
		game.unregister_pickup(self)

func _physics_process(delta: float) -> void:
	if not game or not game.is_gameplay_active():
		return
	age += delta
	spin += delta * 3.5
	var player = game.player
	if not player or not player.is_collectable():
		return
	if not homing:
		velocity.y = min(velocity.y + 240.0 * delta, 145.0)
		velocity.x = lerp(velocity.x, 0.0, delta * 1.4)
		if game.point_of_collection_active() or global_position.distance_squared_to(player.global_position) <= pow(110.0, 2.0):
			homing = true
	else:
		var direction: Vector2 = (player.global_position - global_position).normalized()
		velocity = velocity.lerp(direction * 420.0, delta * 4.2)
	global_position += velocity * delta
	queue_redraw()
	if global_position.distance_squared_to(player.global_position) <= pow(radius + 14.0, 2.0):
		collected = true
		game.collect_pickup(self)
		queue_free()
		return
	var bounds: Rect2 = game.get_extended_playfield_rect(72.0)
	if global_position.y > bounds.position.y + bounds.size.y + 48.0:
		queue_free()

func _draw() -> void:
	var main_color := Color(0.95, 0.95, 1.0)
	var accent_color := Color(0.5, 0.9, 1.0)
	if pickup_type == &"power":
		main_color = Color(1.0, 0.48, 0.88)
		accent_color = Color(1.0, 0.82, 0.32)
	var local_spin := spin
	draw_set_transform(Vector2.ZERO, local_spin, Vector2.ONE)
	var points := PackedVector2Array([
		Vector2(0.0, -radius),
		Vector2(radius * 0.6, 0.0),
		Vector2(0.0, radius),
		Vector2(-radius * 0.6, 0.0)
	])
	var outline := PackedVector2Array([
		Vector2(0.0, -radius),
		Vector2(radius * 0.6, 0.0),
		Vector2(0.0, radius),
		Vector2(-radius * 0.6, 0.0),
		Vector2(0.0, -radius)
	])
	draw_colored_polygon(points, ColorFx.alpha(main_color, 0.95))
	draw_polyline(outline, accent_color, 2.0, true)
	draw_circle(Vector2.ZERO, radius * 0.32, ColorFx.alpha(accent_color, 0.95))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
