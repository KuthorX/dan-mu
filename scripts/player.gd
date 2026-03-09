extends Node2D

signal bomb_requested

var game = null
var active := true
var visible_ship := true
var respawn_delay := 0.0
var invuln_timer := 0.0
var shot_cooldown := 0.0
var focus_ratio := 0.0
var animation_time := 0.0
var hit_flash := 0.0
var hitbox_radius := 3.5
var graze_radius := 24.0
var fast_speed := 330.0
var slow_speed := 165.0

func setup(game_ref):
	game = game_ref
	global_position = game.get_player_spawn_position()
	return self

func begin_run() -> void:
	active = true
	visible_ship = true
	respawn_delay = 0.0
	invuln_timer = 1.7
	shot_cooldown = 0.0
	focus_ratio = 0.0
	hit_flash = 0.0
	global_position = game.get_player_spawn_position()
	queue_redraw()

func prepare_for_stage(invuln_duration := 2.0) -> void:
	active = true
	visible_ship = true
	respawn_delay = 0.0
	shot_cooldown = 0.0
	focus_ratio = 0.0
	invuln_timer = max(invuln_timer, invuln_duration)
	global_position = game.get_player_spawn_position()
	queue_redraw()

func start_respawn() -> void:
	active = false
	visible_ship = false
	respawn_delay = 1.1
	invuln_timer = 0.0
	shot_cooldown = 0.12
	queue_redraw()

func set_invulnerable(duration: float) -> void:
	invuln_timer = max(invuln_timer, duration)

func can_be_hit() -> bool:
	return active and visible_ship and respawn_delay <= 0.0 and invuln_timer <= 0.0

func is_targetable() -> bool:
	return visible_ship and respawn_delay <= 0.0

func is_collectable() -> bool:
	return visible_ship and respawn_delay <= 0.0

func _physics_process(delta: float) -> void:
	animation_time += delta
	if hit_flash > 0.0:
		hit_flash = max(0.0, hit_flash - delta)
	if respawn_delay > 0.0:
		respawn_delay -= delta
		if respawn_delay <= 0.0:
			visible_ship = true
			active = true
			global_position = game.get_player_spawn_position()
			invuln_timer = 2.3
		queue_redraw()
		return
	if invuln_timer > 0.0:
		invuln_timer = max(0.0, invuln_timer - delta)
	if not game or not game.is_gameplay_active():
		queue_redraw()
		return
	focus_ratio = move_toward(focus_ratio, 1.0 if Input.is_action_pressed(&"focus") else 0.0, delta * 6.5)
	var input_vector: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var current_speed: float = lerpf(fast_speed, slow_speed, focus_ratio)
	global_position += input_vector * current_speed * delta
	var rect: Rect2 = game.playfield_rect
	global_position.x = clamp(global_position.x, rect.position.x + 12.0, rect.position.x + rect.size.x - 12.0)
	global_position.y = clamp(global_position.y, rect.position.y + 16.0, rect.position.y + rect.size.y - 18.0)
	shot_cooldown = max(0.0, shot_cooldown - delta)
	if Input.is_action_pressed(&"shoot") and shot_cooldown <= 0.0:
		shot_cooldown = 0.09
		_fire_volley()
	if Input.is_action_just_pressed(&"bomb") and active:
		emit_signal("bomb_requested")
	queue_redraw()

func _fire_volley() -> void:
	game.on_player_shot(focus_ratio)
	var tier: int = game.get_power_tier()
	var main_speed := 760.0
	game.spawn_player_bullet(global_position + Vector2(-6.0, -18.0), Vector2(0.0, -main_speed), {
		"damage": 1.35,
		"shape": &"needle",
		"color": Color(0.72, 0.96, 1.0),
		"radius": 5.0,
		"rotation_speed": 0.08
	})
	game.spawn_player_bullet(global_position + Vector2(6.0, -18.0), Vector2(0.0, -main_speed), {
		"damage": 1.35,
		"shape": &"needle",
		"color": Color(0.72, 0.96, 1.0),
		"radius": 5.0,
		"rotation_speed": -0.08
	})
	if tier >= 2:
		game.spawn_player_bullet(global_position + Vector2(-14.0, -12.0), Vector2(-70.0, -main_speed * 0.96), {
			"damage": 1.0,
			"shape": &"diamond",
			"color": Color(0.95, 0.55, 1.0),
			"radius": 4.6
		})
		game.spawn_player_bullet(global_position + Vector2(14.0, -12.0), Vector2(70.0, -main_speed * 0.96), {
			"damage": 1.0,
			"shape": &"diamond",
			"color": Color(0.95, 0.55, 1.0),
			"radius": 4.6
		})
	if tier >= 3:
		game.spawn_player_bullet(global_position + Vector2(-2.0, -23.0), Vector2(0.0, -main_speed * 1.06), {
			"damage": 1.7,
			"shape": &"needle",
			"color": Color(1.0, 0.92, 0.55),
			"radius": 5.2
		})
		game.spawn_player_bullet(global_position + Vector2(2.0, -23.0), Vector2(0.0, -main_speed * 1.06), {
			"damage": 1.7,
			"shape": &"needle",
			"color": Color(1.0, 0.92, 0.55),
			"radius": 5.2
		})
	if tier >= 4:
		game.spawn_player_bullet(global_position + Vector2(-20.0, -8.0), Vector2(-120.0, -main_speed * 0.93), {
			"damage": 0.95,
			"shape": &"star",
			"color": Color(0.64, 1.0, 0.88),
			"radius": 4.5,
			"rotation_speed": 3.0
		})
		game.spawn_player_bullet(global_position + Vector2(20.0, -8.0), Vector2(120.0, -main_speed * 0.93), {
			"damage": 0.95,
			"shape": &"star",
			"color": Color(0.64, 1.0, 0.88),
			"radius": 4.5,
			"rotation_speed": -3.0
		})
	for option_position in _get_option_positions(tier):
		var aim := Vector2(0.0, -1.0)
		var spread: float = option_position.x * 0.0055 * (1.0 - focus_ratio)
		aim = aim.rotated(spread)
		game.spawn_player_bullet(global_position + option_position, aim * (main_speed * 0.96), {
			"damage": 0.9 + focus_ratio * 0.55,
			"shape": &"diamond" if focus_ratio > 0.55 else &"orb",
			"color": Color(0.95, 0.72, 1.0) if focus_ratio > 0.55 else Color(0.62, 0.92, 1.0),
			"radius": 4.2,
			"rotation_speed": 1.6 * sign(option_position.x)
		})

func on_got_hit() -> void:
	hit_flash = 0.18
	queue_redraw()

func _get_option_positions(tier: int) -> Array:
	var wide: Array = [Vector2(-34.0, -10.0), Vector2(34.0, -10.0), Vector2(-58.0, 8.0), Vector2(58.0, 8.0)]
	var focused: Array = [Vector2(-16.0, -18.0), Vector2(16.0, -18.0), Vector2(-28.0, -4.0), Vector2(28.0, -4.0)]
	var count := 2
	if tier >= 3:
		count = 4
	var result: Array = []
	for index in range(count):
		result.append(wide[index].lerp(focused[index], focus_ratio))
	return result

func _draw() -> void:
	if not visible_ship:
		return
	var blink_alpha := 1.0
	if invuln_timer > 0.0:
		blink_alpha = 0.45 + 0.55 * abs(sin(animation_time * 14.0))
	var ship_color := Color(0.72, 0.92, 1.0, blink_alpha)
	if hit_flash > 0.0:
		ship_color = Color(1.0, 0.55, 0.72, 1.0)
	for option_position in _get_option_positions(game.get_power_tier()):
		draw_circle(option_position, 6.0, Color(0.88, 0.7, 1.0, 0.16 + 0.18 * blink_alpha))
		draw_circle(option_position, 3.2, Color(1.0, 0.82, 1.0, 0.95 * blink_alpha))
	var wing_flare: float = 2.0 + sin(animation_time * 8.0) * 1.2
	var hull := PackedVector2Array([
		Vector2(0.0, -14.0),
		Vector2(10.0, 8.0 + wing_flare),
		Vector2(0.0, 4.0),
		Vector2(-10.0, 8.0 + wing_flare)
	])
	draw_colored_polygon(hull, ship_color)
	draw_circle(Vector2.ZERO, 5.2, Color(1.0, 1.0, 1.0, 0.92 * blink_alpha))
	draw_circle(Vector2(0.0, 8.0), 3.2, Color(0.5, 0.84, 1.0, 0.85 * blink_alpha))
	if focus_ratio > 0.05 or invuln_timer > 0.0:
		draw_circle(Vector2.ZERO, graze_radius, Color(0.52, 0.82, 1.0, 0.08 + focus_ratio * 0.05))
		draw_circle(Vector2.ZERO, hitbox_radius + 1.6, Color(1.0, 1.0, 1.0, 0.22 + focus_ratio * 0.1))
		draw_circle(Vector2.ZERO, hitbox_radius, Color(1.0, 0.3, 0.45, 0.92))
