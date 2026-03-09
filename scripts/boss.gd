extends Node2D

const ColorFx = preload("res://scripts/color_fx.gd")

var game = null
var boss_name := "Boundary Watcher"
var boss_subtitle := ""
var phase_index := -1
var phases: Array = []
var hp := 1.0
var max_hp := 1.0
var radius := 34.0
var intro_timer := 1.6
var transition_timer := 0.0
var dead := false
var phase_time := 0.0
var move_timer := 0.0
var move_target := Vector2.ZERO
var shoot_a := 0.0
var shoot_b := 0.0
var shoot_c := 0.0
var pattern_angle := 0.0
var orbit_angle := 0.0
var alt_toggle := false
var flash_timer := 0.0
var current_phase_name := ""
var current_pattern: StringName = &"scarlet_spiral"
var current_color := Color(1.0, 0.5, 0.72)

func setup(game_ref, config := {}):
	game = game_ref
	boss_name = str(config.get("name", "Boundary Watcher"))
	boss_subtitle = str(config.get("subtitle", ""))
	radius = float(config.get("radius", 34.0))
	phases = config.get("phases", [])
	if phases.is_empty():
		phases = _default_phases()
	global_position = Vector2(game.playfield_rect.position.x + game.playfield_rect.size.x * 0.5, -90.0)
	move_target = Vector2(game.playfield_rect.position.x + game.playfield_rect.size.x * 0.5, game.playfield_rect.position.y + 160.0)
	return self

func _default_phases() -> Array:
	return [
		{"name": "Nonspell · Scarlet Spiral", "hp": 420.0, "color": Color(1.0, 0.45, 0.68), "bonus": 40000, "pattern": &"scarlet_spiral"},
		{"name": "Spell · Moon Petal Cage", "hp": 560.0, "color": Color(0.58, 0.95, 1.0), "bonus": 70000, "pattern": &"moon_petals"},
		{"name": "Spell · Prism Cascade", "hp": 700.0, "color": Color(0.76, 0.62, 1.0), "bonus": 100000, "pattern": &"prism_cascade"},
		{"name": "Last Spell · Falling Star Border", "hp": 860.0, "color": Color(1.0, 0.88, 0.46), "bonus": 150000, "pattern": &"falling_star"}
	]

func _enter_tree() -> void:
	if game:
		game.register_boss(self)

func _exit_tree() -> void:
	if game:
		game.unregister_boss(self)

func _physics_process(delta: float) -> void:
	if dead or not game or not game.is_gameplay_active():
		return
	flash_timer = max(0.0, flash_timer - delta)
	if intro_timer > 0.0:
		intro_timer -= delta
		global_position = global_position.lerp(move_target, delta * 1.8)
		queue_redraw()
		if intro_timer <= 0.0:
			_begin_phase(0)
		return
	if transition_timer > 0.0:
		transition_timer -= delta
		global_position = global_position.lerp(move_target, delta * 2.3)
		queue_redraw()
		if transition_timer <= 0.0:
			_begin_phase(phase_index + 1)
		return
	phase_time += delta
	orbit_angle += delta * 1.7
	_update_movement(delta)
	match current_pattern:
		&"scarlet_spiral":
			_pattern_scarlet_spiral(delta)
		&"moon_petals":
			_pattern_moon_petals(delta)
		&"prism_cascade":
			_pattern_prism_cascade(delta)
		&"falling_star":
			_pattern_falling_star(delta)
		&"magnetic_bloom":
			_pattern_magnetic_bloom(delta)
		&"aurora_lattice":
			_pattern_aurora_lattice(delta)
		&"comet_refinery":
			_pattern_comet_refinery(delta)
		&"boundary_collapse":
			_pattern_boundary_collapse(delta)
	queue_redraw()

func _update_movement(delta: float) -> void:
	move_timer -= delta
	if move_timer <= 0.0:
		move_timer = randf_range(1.2, 2.2)
		move_target = Vector2(
			randf_range(game.playfield_rect.position.x + 96.0, game.playfield_rect.position.x + game.playfield_rect.size.x - 96.0),
			randf_range(game.playfield_rect.position.y + 84.0, game.playfield_rect.position.y + 220.0)
		)
	global_position = global_position.lerp(move_target, delta * 1.55)

func _begin_phase(index: int) -> void:
	if index >= phases.size():
		defeat()
		return
	phase_index = index
	var phase: Dictionary = phases[phase_index]
	current_phase_name = str(phase.get("name", "Spell Card"))
	current_pattern = phase.get("pattern", &"scarlet_spiral")
	current_color = phase.get("color", Color(1.0, 0.5, 0.72))
	max_hp = float(phase.get("hp", 500.0))
	hp = max_hp
	phase_time = 0.0
	shoot_a = 0.0
	shoot_b = 0.0
	shoot_c = 0.0
	pattern_angle = randf() * TAU
	orbit_angle = randf() * TAU
	move_timer = 0.2
	alt_toggle = false
	move_target = Vector2(game.playfield_rect.position.x + game.playfield_rect.size.x * 0.5, game.playfield_rect.position.y + 150.0)
	game.cancel_all_enemy_bullets(true)
	game.spawn_ring_effect(global_position, current_color, 20.0, 128.0, 0.75, 4.0)
	game.spawn_spark_effect(global_position, current_color.lightened(0.2), 56.0, 0.45, 18)
	game.on_boss_phase_changed(current_phase_name, hp, max_hp)

func take_damage(amount: float) -> bool:
	if dead or intro_timer > 0.0 or transition_timer > 0.0:
		return false
	hp -= amount
	flash_timer = 0.05
	if hp <= 0.0:
		var phase: Dictionary = phases[phase_index]
		game.add_score(int(phase.get("bonus", 50000)))
		game.on_boss_phase_cleared(current_phase_name)
		if phase_index >= phases.size() - 1:
			defeat()
		else:
			transition_timer = 1.15
			move_target = Vector2(game.playfield_rect.position.x + game.playfield_rect.size.x * 0.5, game.playfield_rect.position.y + 152.0)
			game.cancel_all_enemy_bullets(true)
			game.spawn_explosion_effect(global_position, current_color, 42.0, 0.7)
			game.spawn_spark_effect(global_position, current_color.lightened(0.2), 74.0, 0.55, 22)
			game.on_boss_phase_changed("Phase Break", 0.0, 1.0)
	return true

func defeat() -> void:
	if dead:
		return
	dead = true
	game.cancel_all_enemy_bullets(true)
	game.spawn_explosion_effect(global_position, Color(1.0, 0.88, 0.65), 72.0, 1.0)
	game.spawn_spark_effect(global_position, current_color.lightened(0.25), 96.0, 0.65, 30)
	game.on_boss_defeated()
	queue_free()

func is_targetable() -> bool:
	return not dead and intro_timer <= 0.0 and transition_timer <= 0.0

func _pattern_scarlet_spiral(delta: float) -> void:
	shoot_a -= delta
	shoot_b -= delta
	pattern_angle += delta * 1.5
	if shoot_a <= 0.0:
		shoot_a = 0.11
		game.spawn_radial_burst(global_position, 10, 155.0, pattern_angle, &"enemy", {
			"shape": &"orb",
			"color": Color(1.0, 0.42, 0.68),
			"radius": 6.6
		})
		game.spawn_radial_burst(global_position, 10, 225.0, pattern_angle + PI / 10.0, &"enemy", {
			"shape": &"diamond",
			"color": Color(1.0, 0.84, 0.46),
			"radius": 5.6,
			"rotation_speed": 1.2
		})
	if shoot_b <= 0.0:
		shoot_b = 1.2
		var aim_angle: float = game.angle_to_player(global_position)
		game.spawn_fan(global_position, aim_angle, 7, 56.0, 240.0, &"enemy", {
			"shape": &"needle",
			"color": Color(0.96, 0.96, 1.0),
			"radius": 5.2
		})

func _pattern_moon_petals(delta: float) -> void:
	shoot_a -= delta
	shoot_b -= delta
	if shoot_a <= 0.0:
		shoot_a = 0.16
		for side_value in [-1.0, 1.0]:
			var side: float = float(side_value)
			var emitter: Vector2 = global_position + Vector2(cos(orbit_angle + side * PI * 0.45), sin(orbit_angle + side * PI * 0.45)) * 54.0
			var fan_angle: float = game.angle_to_player(emitter) + side * deg_to_rad(22.0)
			game.spawn_fan(emitter, fan_angle, 5, 50.0, 145.0, &"enemy", {
				"shape": &"petal",
				"color": Color(0.58, 0.96, 1.0),
				"radius": 6.6,
				"accel_after": 0.7,
				"accel": 125.0,
				"wave_amplitude": 6.0,
				"wave_frequency": 5.0,
				"wave_phase": side * 0.6
			})
	if shoot_b <= 0.0:
		shoot_b = 1.28
		game.spawn_radial_burst(global_position, 18, 175.0, orbit_angle * 0.7, &"enemy", {
			"shape": &"diamond",
			"color": Color(0.88, 0.66, 1.0),
			"radius": 5.7,
			"rotation_speed": 0.9
		})

func _pattern_prism_cascade(delta: float) -> void:
	shoot_a -= delta
	shoot_b -= delta
	if shoot_a <= 0.0:
		shoot_a = 0.24
		alt_toggle = not alt_toggle
		var side_x: float = game.playfield_rect.position.x + 16.0
		if not alt_toggle:
			side_x = game.playfield_rect.position.x + game.playfield_rect.size.x - 16.0
		for stream_index in range(6):
			var origin := Vector2(side_x, game.playfield_rect.position.y + 48.0 + float(stream_index) * 28.0)
			var target := Vector2(
				game.playfield_rect.position.x + 90.0 + float(stream_index) * 62.0,
				game.playfield_rect.position.y + game.playfield_rect.size.y + 32.0
			)
			var direction: Vector2 = (target - origin).normalized() * 240.0
			game.spawn_enemy_bullet(origin, direction, {
				"shape": &"needle",
				"color": Color(0.66, 0.74, 1.0),
				"radius": 5.0
			})
	if shoot_b <= 0.0:
		shoot_b = 0.95
		var aim_angle: float = game.angle_to_player(global_position)
		game.spawn_fan(global_position, aim_angle, 9, 72.0, 230.0, &"enemy", {
			"shape": &"star",
			"color": Color(0.9, 0.68, 1.0),
			"radius": 5.0,
			"rotation_speed": 3.2
		})

func _pattern_falling_star(delta: float) -> void:
	shoot_a -= delta
	shoot_b -= delta
	shoot_c -= delta
	pattern_angle += delta * 1.85
	if shoot_a <= 0.0:
		shoot_a = 0.12
		game.spawn_radial_burst(global_position, 12, 205.0, pattern_angle, &"enemy", {
			"shape": &"star",
			"color": Color(1.0, 0.84, 0.48),
			"radius": 5.2,
			"rotation_speed": 3.0
		})
		game.spawn_radial_burst(global_position, 12, 140.0, pattern_angle + PI / 12.0, &"enemy", {
			"shape": &"orb",
			"color": Color(1.0, 0.42, 0.72),
			"radius": 6.3,
			"accel_after": 0.9,
			"accel": 110.0
		})
	if shoot_b <= 0.0:
		shoot_b = 0.72
		var aim_angle: float = game.angle_to_player(global_position)
		game.spawn_fan(global_position, aim_angle, 11, 88.0, 260.0, &"enemy", {
			"shape": &"needle",
			"color": Color(0.94, 0.95, 1.0),
			"radius": 5.1
		})
	if shoot_c <= 0.0:
		shoot_c = 0.34
		for side_x in [game.playfield_rect.position.x + 24.0, game.playfield_rect.position.x + game.playfield_rect.size.x - 24.0]:
			for offset in range(3):
				var origin := Vector2(side_x, game.playfield_rect.position.y + 76.0 + float(offset) * 40.0)
				var target_angle: float = game.angle_to_player(origin) + deg_to_rad((float(offset) - 1.0) * 10.0)
				game.spawn_enemy_bullet(origin, Vector2.RIGHT.rotated(target_angle) * 225.0, {
					"shape": &"petal",
					"color": Color(0.58, 0.94, 1.0),
					"radius": 5.7,
					"wave_amplitude": 10.0,
					"wave_frequency": 4.4,
					"wave_phase": float(offset)
				})

func _pattern_magnetic_bloom(delta: float) -> void:
	shoot_a -= delta
	shoot_b -= delta
	pattern_angle += delta * 1.2
	if shoot_a <= 0.0:
		shoot_a = 0.22
		alt_toggle = not alt_toggle
		var lateral: float = -64.0 if alt_toggle else 64.0
		var emitter: Vector2 = global_position + Vector2(lateral, sin(phase_time * 3.0) * 18.0)
		var aim_angle: float = game.angle_to_player(emitter) + (0.24 if alt_toggle else -0.24)
		game.spawn_fan(emitter, aim_angle, 6, 64.0, 165.0, &"enemy", {
			"shape": &"petal",
			"color": Color(1.0, 0.66, 0.42),
			"radius": 6.1,
			"wave_amplitude": 8.0,
			"wave_frequency": 4.8,
			"wave_phase": lateral * 0.03
		})
	if shoot_b <= 0.0:
		shoot_b = 0.88
		game.spawn_radial_burst(global_position, 14, 155.0, pattern_angle, &"enemy", {
			"shape": &"diamond",
			"color": Color(0.54, 0.95, 1.0),
			"radius": 5.2,
			"rotation_speed": 1.0
		})
		game.spawn_radial_burst(global_position, 14, 220.0, pattern_angle + PI / 14.0, &"enemy", {
			"shape": &"needle",
			"color": Color(1.0, 0.84, 0.48),
			"radius": 4.8
		})

func _pattern_aurora_lattice(delta: float) -> void:
	shoot_a -= delta
	shoot_b -= delta
	shoot_c -= delta
	if shoot_a <= 0.0:
		shoot_a = 0.18
		for orbit_index in range(3):
			var orbit_phase: float = orbit_angle + float(orbit_index) * TAU / 3.0
			var emitter: Vector2 = global_position + Vector2(cos(orbit_phase), sin(orbit_phase)) * 60.0
			game.spawn_enemy_bullet(emitter, Vector2.DOWN.rotated(sin(orbit_phase) * 0.16) * 200.0, {
				"shape": &"needle",
				"color": Color(0.54, 0.95, 1.0),
				"radius": 5.0,
				"turn_rate": cos(orbit_phase) * 0.08
			})
	if shoot_b <= 0.0:
		shoot_b = 0.94
		for side_x in [game.playfield_rect.position.x + 18.0, game.playfield_rect.position.x + game.playfield_rect.size.x - 18.0]:
			for row in range(4):
				var origin := Vector2(side_x, game.playfield_rect.position.y + 70.0 + float(row) * 42.0)
				var target_angle: float = game.angle_to_player(origin) + deg_to_rad((float(row) - 1.5) * 8.0)
				game.spawn_enemy_bullet(origin, Vector2.RIGHT.rotated(target_angle) * 210.0, {
					"shape": &"diamond",
					"color": Color(0.84, 0.58, 1.0),
					"radius": 5.3,
					"wave_amplitude": 9.0,
					"wave_frequency": 4.0,
					"wave_phase": float(row) * 0.7
				})
	if shoot_c <= 0.0:
		shoot_c = 1.35
		var aim_angle: float = game.angle_to_player(global_position)
		game.spawn_fan(global_position, aim_angle, 10, 96.0, 250.0, &"enemy", {
			"shape": &"star",
			"color": Color(1.0, 0.82, 0.46),
			"radius": 4.8,
			"rotation_speed": 2.8
		})

func _pattern_comet_refinery(delta: float) -> void:
	shoot_a -= delta
	shoot_b -= delta
	if shoot_a <= 0.0:
		shoot_a = 0.24
		for lane in range(6):
			var x: float = game.playfield_rect.position.x + 50.0 + float(lane) * 90.0 + sin(phase_time * 2.0 + float(lane)) * 18.0
			var origin := Vector2(x, game.playfield_rect.position.y - 16.0)
			game.spawn_enemy_bullet(origin, Vector2(0.0, 160.0 + float(lane) * 10.0), {
				"shape": &"star",
				"color": Color(1.0, 0.76, 0.46),
				"radius": 4.8,
				"accel_after": 0.7,
				"accel": 120.0,
				"rotation_speed": 2.5
			})
	if shoot_b <= 0.0:
		shoot_b = 0.82
		var aim_angle: float = game.angle_to_player(global_position)
		game.spawn_fan(global_position, aim_angle, 9, 74.0, 240.0, &"enemy", {
			"shape": &"needle",
			"color": Color(0.94, 0.96, 1.0),
			"radius": 5.0
		})
		game.spawn_radial_burst(global_position, 10, 138.0, pattern_angle, &"enemy", {
			"shape": &"orb",
			"color": Color(0.88, 0.58, 1.0),
			"radius": 6.0,
			"accel_after": 0.9,
			"accel": 90.0
		})
		pattern_angle += PI / 10.0

func _pattern_boundary_collapse(delta: float) -> void:
	shoot_a -= delta
	shoot_b -= delta
	shoot_c -= delta
	pattern_angle += delta * 2.0
	if shoot_a <= 0.0:
		shoot_a = 0.1
		game.spawn_radial_burst(global_position, 16, 210.0, pattern_angle, &"enemy", {
			"shape": &"star",
			"color": Color(1.0, 0.84, 0.48),
			"radius": 5.0,
			"rotation_speed": 3.0
		})
		game.spawn_radial_burst(global_position, 16, 132.0, pattern_angle + PI / 16.0, &"enemy", {
			"shape": &"orb",
			"color": Color(0.52, 0.95, 1.0),
			"radius": 6.2,
			"accel_after": 1.0,
			"accel": 115.0
		})
	if shoot_b <= 0.0:
		shoot_b = 0.44
		for side_x in [game.playfield_rect.position.x + 20.0, game.playfield_rect.position.x + game.playfield_rect.size.x - 20.0]:
			for row in range(4):
				var origin := Vector2(side_x, game.playfield_rect.position.y + 62.0 + float(row) * 44.0)
				var angle_offset: float = deg_to_rad((float(row) - 1.5) * 6.0)
				var target_angle: float = game.angle_to_player(origin) + angle_offset
				game.spawn_enemy_bullet(origin, Vector2.RIGHT.rotated(target_angle) * 235.0, {
					"shape": &"petal",
					"color": Color(1.0, 0.62, 0.46),
					"radius": 5.8,
					"wave_amplitude": 11.0,
					"wave_frequency": 4.6,
					"wave_phase": float(row)
				})
	if shoot_c <= 0.0:
		shoot_c = 0.9
		var aim_angle: float = game.angle_to_player(global_position)
		game.spawn_fan(global_position, aim_angle, 13, 102.0, 268.0, &"enemy", {
			"shape": &"needle",
			"color": Color(0.96, 0.98, 1.0),
			"radius": 4.9
		})

func _draw() -> void:
	var body_color: Color = current_color
	if flash_timer > 0.0:
		body_color = Color.WHITE
	var aura_alpha: float = 0.18 + 0.08 * sin(phase_time * 4.0)
	draw_circle(Vector2.ZERO, radius * 1.35, ColorFx.alpha(body_color, aura_alpha))
	var skirt := PackedVector2Array([
		Vector2(0.0, -radius * 1.1),
		Vector2(radius * 0.82, -radius * 0.2),
		Vector2(radius * 0.66, radius * 1.05),
		Vector2(0.0, radius * 0.62),
		Vector2(-radius * 0.66, radius * 1.05),
		Vector2(-radius * 0.82, -radius * 0.2)
	])
	draw_colored_polygon(skirt, ColorFx.alpha(body_color, 0.95))
	draw_circle(Vector2.ZERO, radius * 0.28, ColorFx.alpha(Color.WHITE, 0.9))
	draw_circle(Vector2(0.0, radius * 0.12), radius * 0.45, ColorFx.alpha(body_color.lightened(0.18), 0.52))
	for wing_index in range(3):
		var offset_angle: float = orbit_angle + float(wing_index) * TAU / 3.0
		var wing_pos: Vector2 = Vector2(cos(offset_angle), sin(offset_angle)) * (radius * 0.95)
		draw_circle(wing_pos, 5.0, ColorFx.alpha(body_color, 0.45))
