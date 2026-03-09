extends Node2D

const ColorFx = preload("res://scripts/color_fx.gd")

var game = null
var faction: StringName = &"enemy"
var shape: StringName = &"orb"
var color := Color.WHITE
var radius := 6.0
var damage := 1.0
var life_time := 8.5
var velocity := Vector2.ZERO
var speed := 0.0
var age := 0.0
var destroyed := false
var grazed := false
var visual_rotation := 0.0
var rotation_speed := 0.0
var visual_scale := 1.0
var wave_amplitude := 0.0
var wave_frequency := 0.0
var wave_phase := 0.0
var spawn_position := Vector2.ZERO
var travel_distance := 0.0
var base_direction := Vector2.UP
var accel_after := -1.0
var accel := 0.0
var turn_rate := 0.0

func setup(game_ref, spawn_pos: Vector2, velocity_vector: Vector2, bullet_faction: StringName, options := {}):
	game = game_ref
	global_position = spawn_pos
	spawn_position = spawn_pos
	velocity = velocity_vector
	speed = velocity.length()
	if speed > 0.001:
		base_direction = velocity.normalized()
	faction = bullet_faction
	shape = options.get("shape", &"orb")
	color = options.get("color", Color.WHITE)
	radius = options.get("radius", 6.0)
	damage = options.get("damage", 1.0)
	life_time = options.get("life_time", 8.5)
	rotation_speed = options.get("rotation_speed", 0.0)
	visual_scale = options.get("scale", 1.0)
	wave_amplitude = options.get("wave_amplitude", 0.0)
	wave_frequency = options.get("wave_frequency", 0.0)
	wave_phase = options.get("wave_phase", 0.0)
	accel_after = options.get("accel_after", -1.0)
	accel = options.get("accel", 0.0)
	turn_rate = options.get("turn_rate", 0.0)
	visual_rotation = velocity_vector.angle() + PI * 0.5
	rotation = visual_rotation
	scale = Vector2.ONE * visual_scale
	queue_redraw()
	return self

func _enter_tree() -> void:
	if game:
		game.register_bullet(self)

func _exit_tree() -> void:
	if game:
		game.unregister_bullet(self)

func _physics_process(delta: float) -> void:
	if destroyed or not game or not game.is_gameplay_active():
		return
	age += delta
	if age >= life_time:
		destroy(false)
		return
	if rotation_speed != 0.0:
		visual_rotation += rotation_speed * delta
	if wave_amplitude != 0.0 and speed > 0.0:
		if accel_after >= 0.0 and age >= accel_after:
			speed += accel * delta
		travel_distance += speed * delta
		var side := Vector2(-base_direction.y, base_direction.x)
		global_position = spawn_position + base_direction * travel_distance + side * sin(age * wave_frequency + wave_phase) * wave_amplitude
	else:
		if accel_after >= 0.0 and age >= accel_after and velocity.length_squared() > 0.001:
			velocity += velocity.normalized() * accel * delta
		if turn_rate != 0.0:
			velocity = velocity.rotated(turn_rate * delta)
		global_position += velocity * delta
		if velocity.length_squared() > 0.001:
			speed = velocity.length()
			base_direction = velocity.normalized()
			if turn_rate != 0.0:
				visual_rotation = base_direction.angle() + PI * 0.5
	rotation = visual_rotation
	if faction == &"enemy":
		_check_player_collision()
	else:
		if game.try_player_bullet_hit(self):
			destroy(true)
			return
	_update_visibility_and_bounds()

func _update_visibility_and_bounds() -> void:
	if faction == &"player":
		var left_bound: float = game.playfield_rect.position.x + 1.0
		var right_bound: float = game.playfield_rect.position.x + game.playfield_rect.size.x - 1.0
		var top_bound: float = game.playfield_rect.position.y - 24.0
		var bottom_bound: float = game.playfield_rect.position.y + game.playfield_rect.size.y + 10.0
		visible = global_position.x >= left_bound and global_position.x <= right_bound and global_position.y >= top_bound and global_position.y <= bottom_bound
		if global_position.y < game.playfield_rect.position.y - 40.0:
			destroy(false)
			return
		if global_position.x < game.playfield_rect.position.x - 14.0 or global_position.x > game.playfield_rect.position.x + game.playfield_rect.size.x + 14.0:
			destroy(false)
			return
	else:
		visible = true
		if not game.get_extended_playfield_rect(96.0).has_point(global_position):
			destroy(false)

func _check_player_collision() -> void:
	var player = game.player
	if not player or not player.is_targetable():
		return
	var hit_distance_sq: float = pow(radius + player.hitbox_radius, 2.0)
	var graze_distance_sq: float = pow(radius + player.graze_radius, 2.0)
	var distance_sq := global_position.distance_squared_to(player.global_position)
	if not grazed and distance_sq <= graze_distance_sq and distance_sq > hit_distance_sq:
		grazed = true
		game.on_player_graze(global_position)
	if player.can_be_hit() and distance_sq <= hit_distance_sq:
		game.on_player_hit()
		destroy(false)

func destroy(show_effect := true, cancelled := false) -> void:
	if destroyed:
		return
	destroyed = true
	if show_effect and game and not game.should_reduce_minor_fx():
		var burst_color := color.lightened(0.2)
		if cancelled:
			burst_color = Color(0.8, 0.96, 1.0)
		game.spawn_ring_effect(global_position, burst_color, radius * 0.2, radius * 1.9, 0.2, 2.0)
	queue_free()

func _draw() -> void:
	match shape:
		&"diamond":
			var diamond := PackedVector2Array([
				Vector2(0.0, -radius * 1.3),
				Vector2(radius * 0.9, 0.0),
				Vector2(0.0, radius * 1.3),
				Vector2(-radius * 0.9, 0.0)
			])
			draw_colored_polygon(diamond, ColorFx.alpha(color, 0.95))
			draw_circle(Vector2.ZERO, radius * 0.26, color.lightened(0.3))
		&"needle":
			var needle := PackedVector2Array([
				Vector2(0.0, -radius * 1.9),
				Vector2(radius * 0.45, -radius * 0.15),
				Vector2(0.0, radius * 1.7),
				Vector2(-radius * 0.45, -radius * 0.15)
			])
			draw_colored_polygon(needle, ColorFx.alpha(color, 0.95))
			draw_circle(Vector2.ZERO, radius * 0.18, ColorFx.alpha(Color.WHITE, 0.85))
		&"petal":
			var petal := PackedVector2Array([
				Vector2(0.0, -radius * 1.7),
				Vector2(radius * 0.7, -radius * 0.6),
				Vector2(radius * 0.55, radius * 1.0),
				Vector2(0.0, radius * 1.5),
				Vector2(-radius * 0.55, radius * 1.0),
				Vector2(-radius * 0.7, -radius * 0.6)
			])
			draw_colored_polygon(petal, ColorFx.alpha(color, 0.92))
			draw_circle(Vector2.ZERO, radius * 0.22, color.lightened(0.35))
		&"star":
			var star := PackedVector2Array()
			for index in range(10):
				var local_radius: float = radius * (1.4 if index % 2 == 0 else 0.58)
				var angle := -PI * 0.5 + TAU * float(index) / 10.0
				star.append(Vector2.RIGHT.rotated(angle) * local_radius)
			draw_colored_polygon(star, ColorFx.alpha(color, 0.94))
			draw_circle(Vector2.ZERO, radius * 0.24, ColorFx.alpha(Color.WHITE, 0.8))
		_:
			draw_circle(Vector2.ZERO, radius * 1.08, ColorFx.alpha(color, 0.25))
			draw_circle(Vector2.ZERO, radius, ColorFx.alpha(color, 0.95))
			draw_circle(Vector2.ZERO, radius * 0.38, ColorFx.alpha(color.lightened(0.3), 0.95))
