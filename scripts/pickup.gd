extends Node2D


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
		var homing_radius: float = 110.0 + game.get_pickup_magnet_bonus()
		if game.point_of_collection_active() or global_position.distance_squared_to(player.global_position) <= pow(homing_radius, 2.0):
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

## Power items are vermilion seals, point items are paper slips; both carry an ink keyline.
func _draw() -> void:
	var face := Color(0.93, 0.89, 0.80)
	var mark := Color(0.16, 0.30, 0.62)
	if pickup_type == &"power":
		face = Color(0.85, 0.25, 0.17)
		mark = Color(0.98, 0.93, 0.84)
	var half: float = radius * 0.62
	draw_set_transform(Vector2.ZERO, sin(spin) * 0.35, Vector2.ONE)
	draw_rect(Rect2(Vector2(-half - 2.0, -half - 2.0), Vector2(half + 2.0, half + 2.0) * 2.0), Color(0.02, 0.01, 0.03, 0.9), true)
	draw_rect(Rect2(Vector2(-half, -half), Vector2(half, half) * 2.0), face, true)
	draw_rect(Rect2(Vector2(-half * 0.45, -half * 0.45), Vector2(half, half) * 0.9), mark, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
