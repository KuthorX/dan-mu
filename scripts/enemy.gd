extends Node2D

const ColorFx = preload("res://scripts/color_fx.gd")

var game = null
var custom_name := "fairy"
var motion: StringName = &"straight"
var shoot_pattern: StringName = &"none"
var bullet_shape: StringName = &"orb"
var bullet_color := Color(1.0, 0.5, 0.7)
var hp := 24.0
var max_hp := 24.0
var radius := 16.0
var velocity := Vector2.ZERO
var age := 0.0
var dead := false
var score_value := 1000
var point_drops := 2
var power_drops := 0
var sine_amplitude := 44.0
var sine_frequency := 2.4
var sine_phase := 0.0
var base_x := 0.0
var drift_x := 0.0
var destination := Vector2.ZERO
var hold_time := 1.2
var retreat_velocity := Vector2.ZERO
var has_arrived := false
var shoot_interval := 1.1
var bullet_speed := 180.0
var shot_count := 1
var spread_deg := 40.0
var ring_count := 10
var base_angle := 0.0
var rotation_step := 0.36
var flash_timer := 0.0
var wobble := 0.0
var approach_speed := 2.5
var curve_strength := 0.0
var ready_to_fire := false

func setup(game_ref, config := {}):
	game = game_ref
	global_position = config.get("spawn", Vector2.ZERO)
	custom_name = config.get("name", "fairy")
	motion = config.get("motion", &"straight")
	shoot_pattern = config.get("shoot_pattern", &"none")
	bullet_shape = config.get("bullet_shape", &"orb")
	bullet_color = config.get("bullet_color", Color(1.0, 0.5, 0.75))
	hp = config.get("hp", 24.0)
	max_hp = hp
	radius = config.get("radius", 16.0)
	velocity = config.get("velocity", Vector2(0.0, 150.0))
	score_value = config.get("score", 1000)
	point_drops = config.get("point_drops", 2)
	power_drops = config.get("power_drops", 0)
	sine_amplitude = config.get("sine_amplitude", 44.0)
	sine_frequency = config.get("sine_frequency", 2.4)
	sine_phase = config.get("sine_phase", 0.0)
	base_x = global_position.x
	drift_x = config.get("drift_x", 0.0)
	destination = config.get("destination", global_position)
	hold_time = config.get("hold_time", 1.2)
	retreat_velocity = config.get("retreat_velocity", Vector2.ZERO)
	shoot_interval = config.get("shoot_interval", 1.1)
	bullet_speed = config.get("bullet_speed", 180.0)
	shot_count = config.get("shot_count", 1)
	spread_deg = config.get("spread_deg", 42.0)
	ring_count = config.get("ring_count", 10)
	base_angle = config.get("base_angle", randf() * TAU)
	rotation_step = config.get("rotation_step", 0.34)
	approach_speed = config.get("approach_speed", 2.5)
	curve_strength = config.get("curve_strength", 0.0)
	ready_to_fire = config.get("ready_to_fire", false)
	wobble = randf() * TAU
	return self

func _enter_tree() -> void:
	if game:
		game.register_enemy(self)

func _exit_tree() -> void:
	if game:
		game.unregister_enemy(self)

func _physics_process(delta: float) -> void:
	if dead or not game or not game.is_gameplay_active():
		return
	age += delta
	flash_timer = max(0.0, flash_timer - delta)
	match motion:
		&"sine_down":
			global_position.y += velocity.y * delta
			global_position.x = base_x + drift_x * age + sin(age * sine_frequency + sine_phase) * sine_amplitude
		&"approach_hold":
			if not has_arrived:
				global_position = global_position.lerp(destination, delta * approach_speed)
				if global_position.distance_to(destination) <= 10.0:
					has_arrived = true
					age = 0.0
			else:
				if age >= hold_time:
					global_position += retreat_velocity * delta
		&"curve":
			velocity.x += curve_strength * delta
			global_position += velocity * delta
		_:
			global_position += velocity * delta
	if not ready_to_fire and game.playfield_rect.has_point(global_position):
		ready_to_fire = true
	if ready_to_fire and shoot_pattern != &"none":
		shoot_interval -= delta
		if shoot_interval <= 0.0:
			_fire_pattern()
	queue_redraw()
	var bounds: Rect2 = game.get_extended_playfield_rect(120.0)
	if not bounds.has_point(global_position):
		if global_position.y > game.playfield_rect.position.y + game.playfield_rect.size.y + 90.0:
			queue_free()

func _fire_pattern() -> void:
	match shoot_pattern:
		&"aimed_single":
			shoot_interval = randf_range(0.9, 1.2)
			var aimed_single_angle: float = game.angle_to_player(global_position)
			game.spawn_enemy_bullet(global_position, Vector2.RIGHT.rotated(aimed_single_angle) * bullet_speed, {
				"shape": bullet_shape,
				"color": bullet_color,
				"radius": 6.0
			})
		&"aimed_fan":
			shoot_interval = randf_range(1.1, 1.5)
			var aimed_fan_angle: float = game.angle_to_player(global_position)
			game.spawn_fan(global_position, aimed_fan_angle, shot_count, spread_deg, bullet_speed, &"enemy", {
				"shape": bullet_shape,
				"color": bullet_color,
				"radius": 6.0
			})
		&"ring":
			shoot_interval = randf_range(1.4, 1.9)
			base_angle += rotation_step
			game.spawn_radial_burst(global_position, ring_count, bullet_speed, base_angle, &"enemy", {
				"shape": bullet_shape,
				"color": bullet_color,
				"radius": 6.0,
				"rotation_speed": 0.8
			})
		&"spiral":
			shoot_interval = 0.16
			base_angle += rotation_step
			for offset_value in [-0.18, 0.18]:
				var offset: float = float(offset_value)
				var direction: Vector2 = Vector2.RIGHT.rotated(base_angle + offset) * bullet_speed
				game.spawn_enemy_bullet(global_position, direction, {
					"shape": bullet_shape,
					"color": bullet_color,
					"radius": 5.4,
					"rotation_speed": 1.5 * sign(offset)
				})
		&"arc_burst":
			shoot_interval = randf_range(0.95, 1.25)
			base_angle += rotation_step
			var burst_angle: float = game.angle_to_player(global_position)
			game.spawn_fan(global_position, burst_angle, shot_count, spread_deg, bullet_speed, &"enemy", {
				"shape": bullet_shape,
				"color": bullet_color,
				"radius": 5.8
			})
			game.spawn_radial_burst(global_position, max(8, ring_count), bullet_speed * 0.72, base_angle, &"enemy", {
				"shape": &"diamond",
				"color": bullet_color.lightened(0.12),
				"radius": 4.8,
				"rotation_speed": 1.2
			})
		&"wall":
			shoot_interval = randf_range(1.0, 1.35)
			game.spawn_fan(global_position, PI * 0.5, shot_count, spread_deg, bullet_speed, &"enemy", {
				"shape": bullet_shape,
				"color": bullet_color,
				"radius": 5.8,
				"wave_amplitude": 6.0,
				"wave_frequency": 4.2,
				"wave_phase": wobble
			})
		&"burst_ring":
			shoot_interval = randf_range(0.95, 1.2)
			base_angle += rotation_step
			var ring_angle: float = game.angle_to_player(global_position)
			game.spawn_enemy_bullet(global_position, Vector2.RIGHT.rotated(ring_angle) * bullet_speed, {
				"shape": bullet_shape,
				"color": bullet_color,
				"radius": 5.6
			})
			game.spawn_radial_burst(global_position, ring_count, bullet_speed * 0.65, base_angle, &"enemy", {
				"shape": &"petal",
				"color": bullet_color.lightened(0.15),
				"radius": 5.2,
				"rotation_speed": 0.9
			})
	game.on_enemy_fired(shoot_pattern)

func take_damage(amount: float) -> void:
	if dead:
		return
	hp -= amount
	flash_timer = 0.08
	if hp <= 0.0:
		destroy()
	else:
		queue_redraw()

func destroy() -> void:
	if dead:
		return
	dead = true
	game.on_enemy_destroyed(self)
	queue_free()

func is_targetable() -> bool:
	return not dead and age >= 0.05 and global_position.y >= game.playfield_rect.position.y - 20.0

func _draw() -> void:
	var body_color := Color(0.95, 0.42, 0.72)
	match custom_name:
		"sweeper":
			body_color = Color(0.46, 0.92, 1.0)
		"spinner":
			body_color = Color(1.0, 0.86, 0.42)
		"carrier":
			body_color = Color(0.86, 0.56, 1.0)
		"lancer":
			body_color = Color(1.0, 0.72, 0.46)
		"weaver":
			body_color = Color(0.62, 1.0, 0.92)
		"guardian":
			body_color = Color(0.72, 0.78, 1.0)
	if flash_timer > 0.0:
		body_color = Color.WHITE
	var wing: float = 8.0 + sin(age * 6.0 + wobble) * 1.8
	var hull := PackedVector2Array([
		Vector2(0.0, -radius * 0.95),
		Vector2(radius * 0.75, -radius * 0.15),
		Vector2(radius * 0.45, radius * 0.9),
		Vector2(0.0, radius * 0.45),
		Vector2(-radius * 0.45, radius * 0.9),
		Vector2(-radius * 0.75, -radius * 0.15)
	])
	draw_colored_polygon(hull, ColorFx.alpha(body_color, 0.95))
	draw_circle(Vector2.ZERO, radius * 0.28, ColorFx.alpha(Color.WHITE, 0.92))
	draw_line(Vector2(-wing, 2.0), Vector2(wing, 2.0), ColorFx.alpha(body_color.lightened(0.15), 0.85), 2.0, true)
	if custom_name == "guardian":
		draw_arc(Vector2.ZERO, radius * 0.86, 0.0, TAU, 32, ColorFx.alpha(body_color, 0.4), 2.0, true)
