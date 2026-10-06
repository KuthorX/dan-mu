extends Node2D

signal bomb_requested

const OPTION_COUNT_BY_TIER := [2, 2, 4, 4, 6, 6, 8, 8]
const KEYLINE := Color(0.02, 0.01, 0.03, 0.9)
const SEAL_RED := Color(0.85, 0.25, 0.17)

var game = null
var ship_key := "spirit"
var ship_label := "Spirit Frame"
var ship_description := "Balanced forward fire with a protective bomb."
var primary_color := Color(0.72, 0.92, 1.0)
var secondary_color := Color(0.96, 0.72, 1.0)
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

func setup(game_ref, ship_config := {}):
	game = game_ref
	_apply_ship_config(ship_config)
	global_position = game.get_player_spawn_position()
	return self

func _apply_ship_config(ship_config: Dictionary) -> void:
	ship_key = str(ship_config.get("key", "spirit"))
	ship_label = str(ship_config.get("label", "Spirit Frame"))
	ship_description = str(ship_config.get("description", "Balanced forward fire with a protective bomb."))
	primary_color = ship_config.get("primary_color", Color(0.72, 0.92, 1.0))
	secondary_color = ship_config.get("secondary_color", Color(0.96, 0.72, 1.0))
	fast_speed = float(ship_config.get("fast_speed", 330.0))
	slow_speed = float(ship_config.get("slow_speed", 165.0))
	hitbox_radius = float(ship_config.get("hitbox_radius", 3.5))
	graze_radius = float(ship_config.get("graze_radius", 24.0))

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

func get_bomb_profile() -> Dictionary:
	match ship_key:
		"gale":
			return {
				"type": "tempest",
				"duration": 0.96,
				"tick": 0.14,
				"clear_radius": 360.0,
				"enemy_damage": 30.0,
				"boss_damage": 40.0,
				"invuln": 1.7,
				"primary_color": primary_color,
				"secondary_color": secondary_color,
				"bonus_power": 8.0,
				"pickup_pull_radius": 420.0
			}
		"lance":
			return {
				"type": "lance",
				"duration": 1.18,
				"tick": 0.10,
				"clear_radius": 225.0,
				"enemy_damage": 56.0,
				"boss_damage": 82.0,
				"invuln": 1.95,
				"beam_half_width": 46.0,
				"primary_color": primary_color,
				"secondary_color": secondary_color
			}
		_:
			return {
				"type": "barrier",
				"duration": 1.08,
				"tick": 0.18,
				"clear_radius": 300.0,
				"enemy_damage": 36.0,
				"boss_damage": 48.0,
				"invuln": 1.8,
				"primary_color": primary_color,
				"secondary_color": secondary_color
			}

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
		shot_cooldown = game.get_player_shot_interval()
		_fire_volley()
	if Input.is_action_just_pressed(&"bomb") and active:
		emit_signal("bomb_requested")
	queue_redraw()

func _fire_volley() -> void:
	game.on_player_shot(focus_ratio)
	var tier: int = game.get_power_tier()
	var power_bonus: float = max(0.0, game.power - 100.0) / 100.0
	match ship_key:
		"gale":
			_fire_gale_volley(tier, power_bonus)
		"lance":
			_fire_lance_volley(tier, power_bonus)
		_:
			_fire_spirit_volley(tier, power_bonus)

func _fire_spirit_volley(tier: int, power_bonus: float) -> void:
	var main_speed := 770.0
	var main_damage := 1.55 + power_bonus * 0.55
	_spawn_shot(Vector2(-6.0, -18.0), Vector2(0.0, -main_speed), {
		"damage": main_damage,
		"shape": &"needle",
		"color": primary_color,
		"radius": 5.0,
		"rotation_speed": 0.08
	})
	_spawn_shot(Vector2(6.0, -18.0), Vector2(0.0, -main_speed), {
		"damage": main_damage,
		"shape": &"needle",
		"color": primary_color,
		"radius": 5.0,
		"rotation_speed": -0.08
	})
	if tier >= 2:
		_spawn_shot(Vector2(-14.0, -12.0), Vector2(-70.0, -main_speed * 0.96), {
			"damage": 1.15 + power_bonus * 0.32,
			"shape": &"diamond",
			"color": secondary_color,
			"radius": 4.6
		})
		_spawn_shot(Vector2(14.0, -12.0), Vector2(70.0, -main_speed * 0.96), {
			"damage": 1.15 + power_bonus * 0.32,
			"shape": &"diamond",
			"color": secondary_color,
			"radius": 4.6
		})
	if tier >= 3:
		_spawn_shot(Vector2(-2.0, -23.0), Vector2(0.0, -main_speed * 1.06), {
			"damage": 1.95 + power_bonus * 0.65,
			"shape": &"needle",
			"color": Color(1.0, 0.92, 0.55),
			"radius": 5.2
		})
		_spawn_shot(Vector2(2.0, -23.0), Vector2(0.0, -main_speed * 1.06), {
			"damage": 1.95 + power_bonus * 0.65,
			"shape": &"needle",
			"color": Color(1.0, 0.92, 0.55),
			"radius": 5.2
		})
	if tier >= 4:
		_spawn_shot(Vector2(-20.0, -8.0), Vector2(-120.0, -main_speed * 0.93), {
			"damage": 1.05 + power_bonus * 0.25,
			"shape": &"star",
			"color": Color(0.64, 1.0, 0.88),
			"radius": 4.5,
			"rotation_speed": 3.0
		})
		_spawn_shot(Vector2(20.0, -8.0), Vector2(120.0, -main_speed * 0.93), {
			"damage": 1.05 + power_bonus * 0.25,
			"shape": &"star",
			"color": Color(0.64, 1.0, 0.88),
			"radius": 4.5,
			"rotation_speed": -3.0
		})
	for extra_pair in range(max(0, tier - 4)):
		var extra_offset: float = 11.0 + float(extra_pair) * 7.0
		_spawn_shot(Vector2(-extra_offset, -20.0 - float(extra_pair) * 2.0), Vector2(-24.0 * float(extra_pair + 1), -main_speed * (1.04 + float(extra_pair) * 0.02)), {
			"damage": 1.25 + power_bonus * 0.4,
			"shape": &"needle",
			"color": primary_color.lightened(0.12),
			"radius": 4.8
		})
		_spawn_shot(Vector2(extra_offset, -20.0 - float(extra_pair) * 2.0), Vector2(24.0 * float(extra_pair + 1), -main_speed * (1.04 + float(extra_pair) * 0.02)), {
			"damage": 1.25 + power_bonus * 0.4,
			"shape": &"needle",
			"color": primary_color.lightened(0.12),
			"radius": 4.8
		})
	for option_position in _get_option_positions(tier):
		var aim := Vector2(0.0, -1.0)
		var spread: float = option_position.x * 0.0055 * (1.0 - focus_ratio)
		aim = aim.rotated(spread)
		_spawn_shot(option_position, aim * (main_speed * 0.96), {
			"damage": 1.0 + focus_ratio * 0.65 + power_bonus * 0.22,
			"shape": &"diamond" if focus_ratio > 0.55 else &"orb",
			"color": secondary_color if focus_ratio > 0.55 else primary_color,
			"radius": 4.2,
			"rotation_speed": 1.6 * sign(option_position.x)
		})

func _fire_gale_volley(tier: int, power_bonus: float) -> void:
	var main_speed := 720.0
	var fan_count = min(9, 3 + tier)
	var spread_deg: float = lerpf(68.0, 24.0, focus_ratio)
	game.spawn_fan(global_position + Vector2(0.0, -18.0), -PI * 0.5, fan_count, spread_deg, main_speed, &"player", {
		"damage": 0.95 + focus_ratio * 0.35 + power_bonus * 0.16,
		"shape": &"petal" if focus_ratio < 0.5 else &"needle",
		"color": primary_color,
		"radius": 4.5
	})
	if tier >= 3:
		game.spawn_fan(global_position + Vector2(0.0, -10.0), -PI * 0.5, 5, lerpf(112.0, 44.0, focus_ratio), main_speed * 0.88, &"player", {
			"damage": 0.65 + power_bonus * 0.12,
			"shape": &"orb",
			"color": secondary_color,
			"radius": 4.0,
			"rotation_speed": 1.8
		})
	for option_position in _get_option_positions(tier):
		var option_angle = -PI * 0.5 + option_position.x * 0.0062 * (1.15 - focus_ratio)
		var option_count := 2 if tier < 5 else 3
		game.spawn_fan(global_position + option_position, option_angle, option_count, lerpf(24.0, 10.0, focus_ratio), main_speed * 0.92, &"player", {
			"damage": 0.82 + power_bonus * 0.14,
			"shape": &"star",
			"color": secondary_color,
			"radius": 4.1,
			"rotation_speed": 2.4 * sign(option_position.x if option_position.x != 0.0 else 1.0)
		})

func _fire_lance_volley(tier: int, power_bonus: float) -> void:
	var main_speed := 810.0
	var center_damage := 2.25 + focus_ratio * 0.95 + power_bonus * 0.75
	_spawn_shot(Vector2(-4.0, -20.0), Vector2(0.0, -main_speed), {
		"damage": center_damage,
		"shape": &"needle",
		"color": primary_color,
		"radius": 5.1
	})
	_spawn_shot(Vector2(4.0, -20.0), Vector2(0.0, -main_speed), {
		"damage": center_damage,
		"shape": &"needle",
		"color": primary_color,
		"radius": 5.1
	})
	if tier >= 2:
		_spawn_shot(Vector2(0.0, -26.0), Vector2(0.0, -main_speed * 1.08), {
			"damage": 2.8 + focus_ratio * 1.2 + power_bonus * 0.9,
			"shape": &"needle",
			"color": Color(1.0, 0.92, 0.6),
			"radius": 5.4
		})
	if tier >= 4:
		_spawn_shot(Vector2(-16.0, -14.0), Vector2(-34.0 * (1.0 - focus_ratio), -main_speed * 0.98), {
			"damage": 1.55 + power_bonus * 0.4,
			"shape": &"diamond",
			"color": secondary_color,
			"radius": 4.5
		})
		_spawn_shot(Vector2(16.0, -14.0), Vector2(34.0 * (1.0 - focus_ratio), -main_speed * 0.98), {
			"damage": 1.55 + power_bonus * 0.4,
			"shape": &"diamond",
			"color": secondary_color,
			"radius": 4.5
		})
	for option_position in _get_option_positions(tier):
		var option_speed: float = main_speed * (1.0 + focus_ratio * 0.05)
		var drift_x: float = option_position.x * 0.045 * (1.0 - focus_ratio)
		_spawn_shot(option_position, Vector2(drift_x, -option_speed), {
			"damage": 1.35 + focus_ratio * 0.85 + power_bonus * 0.22,
			"shape": &"needle" if focus_ratio > 0.45 else &"diamond",
			"color": secondary_color,
			"radius": 4.2,
			"rotation_speed": 0.4 * sign(option_position.x)
		})
	if tier >= 6:
		for side_value in [-1.0, 1.0]:
			var side: float = float(side_value)
			_spawn_shot(Vector2(24.0 * side, -10.0), Vector2(48.0 * side * (1.0 - focus_ratio), -main_speed * 0.9), {
				"damage": 1.25 + power_bonus * 0.35,
				"shape": &"star",
				"color": primary_color.lightened(0.15),
				"radius": 4.0,
				"rotation_speed": 2.8 * side
			})

func _spawn_shot(offset: Vector2, velocity: Vector2, options := {}) -> void:
	game.spawn_player_bullet(global_position + offset, velocity, options)

func on_got_hit() -> void:
	hit_flash = 0.18
	queue_redraw()

func _get_option_positions(tier: int) -> Array:
	var wide: Array = []
	var focused: Array = []
	match ship_key:
		"gale":
			wide = [Vector2(-36.0, -10.0), Vector2(36.0, -10.0), Vector2(-62.0, 4.0), Vector2(62.0, 4.0), Vector2(-88.0, 18.0), Vector2(88.0, 18.0), Vector2(-114.0, 28.0), Vector2(114.0, 28.0), Vector2(-140.0, 40.0), Vector2(140.0, 40.0)]
			focused = [Vector2(-18.0, -18.0), Vector2(18.0, -18.0), Vector2(-30.0, -8.0), Vector2(30.0, -8.0), Vector2(-40.0, 4.0), Vector2(40.0, 4.0), Vector2(-52.0, 14.0), Vector2(52.0, 14.0), Vector2(-62.0, 24.0), Vector2(62.0, 24.0)]
		"lance":
			wide = [Vector2(-22.0, -18.0), Vector2(22.0, -18.0), Vector2(-36.0, -8.0), Vector2(36.0, -8.0), Vector2(-52.0, 2.0), Vector2(52.0, 2.0), Vector2(-68.0, 12.0), Vector2(68.0, 12.0), Vector2(-84.0, 22.0), Vector2(84.0, 22.0)]
			focused = [Vector2(-12.0, -20.0), Vector2(12.0, -20.0), Vector2(-20.0, -14.0), Vector2(20.0, -14.0), Vector2(-28.0, -8.0), Vector2(28.0, -8.0), Vector2(-36.0, 0.0), Vector2(36.0, 0.0), Vector2(-46.0, 10.0), Vector2(46.0, 10.0)]
		_:
			wide = [Vector2(-34.0, -10.0), Vector2(34.0, -10.0), Vector2(-58.0, 8.0), Vector2(58.0, 8.0), Vector2(-80.0, 22.0), Vector2(80.0, 22.0), Vector2(-102.0, 32.0), Vector2(102.0, 32.0), Vector2(-126.0, 42.0), Vector2(126.0, 42.0)]
			focused = [Vector2(-16.0, -18.0), Vector2(16.0, -18.0), Vector2(-28.0, -4.0), Vector2(28.0, -4.0), Vector2(-38.0, 8.0), Vector2(38.0, 8.0), Vector2(-50.0, 16.0), Vector2(50.0, 16.0), Vector2(-62.0, 26.0), Vector2(62.0, 26.0)]
	var count: int = OPTION_COUNT_BY_TIER[clamp(tier - 1, 0, OPTION_COUNT_BY_TIER.size() - 1)] + game.get_player_bonus_option_count()
	count = clamp(count, 0, wide.size())
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
	var ship_color := Color(primary_color.r, primary_color.g, primary_color.b, blink_alpha)
	var ship_core := Color(secondary_color.r, secondary_color.g, secondary_color.b, 0.95 * blink_alpha)
	if hit_flash > 0.0:
		ship_color = Color(1.0, 0.55, 0.72, 1.0)
		ship_core = Color(1.0, 0.86, 0.94, 1.0)
	var keyline := Color(KEYLINE.r, KEYLINE.g, KEYLINE.b, KEYLINE.a * blink_alpha)
	# options are small vermilion seals with a paper eye, the shrine's familiars
	for option_position in _get_option_positions(game.get_power_tier()):
		draw_rect(Rect2(option_position - Vector2(5.5, 5.5), Vector2(11.0, 11.0)), keyline, true)
		draw_rect(Rect2(option_position - Vector2(4.0, 4.0), Vector2(8.0, 8.0)), Color(SEAL_RED.r, SEAL_RED.g, SEAL_RED.b, blink_alpha), true)
		draw_rect(Rect2(option_position - Vector2(1.5, 1.5), Vector2(3.0, 3.0)), Color(1.0, 0.95, 0.86, blink_alpha), true)
	var hull := _hull_points()
	var outline: Array = Geometry2D.offset_polygon(hull, 2.0)
	if not outline.is_empty():
		draw_colored_polygon(outline[0], keyline)
	draw_colored_polygon(hull, ship_color)
	draw_circle(Vector2(0.0, 7.0), 3.2, ship_core)
	if ship_key == "gale":
		draw_line(Vector2(-15.0, 3.0), Vector2(15.0, 3.0), Color(primary_color.r, primary_color.g, primary_color.b, 0.58 * blink_alpha), 2.0, true)
	elif ship_key == "lance":
		draw_line(Vector2(0.0, -18.0), Vector2(0.0, 14.0), Color(secondary_color.r, secondary_color.g, secondary_color.b, 0.72 * blink_alpha), 2.2, true)
	if focus_ratio > 0.05:
		_draw_focus_marks()
	else:
		draw_circle(Vector2.ZERO, 4.2, Color(1.0, 1.0, 1.0, 0.92 * blink_alpha))

func _hull_points() -> PackedVector2Array:
	match ship_key:
		"gale":
			return PackedVector2Array([Vector2(0.0, -15.0), Vector2(13.0, 6.0), Vector2(6.0, 9.0), Vector2(0.0, 3.0), Vector2(-6.0, 9.0), Vector2(-13.0, 6.0)])
		"lance":
			return PackedVector2Array([Vector2(0.0, -16.0), Vector2(8.0, 2.0), Vector2(5.0, 12.0), Vector2(0.0, 6.0), Vector2(-5.0, 12.0), Vector2(-8.0, 2.0)])
	var wing_flare: float = 2.0 + sin(animation_time * 8.0) * 1.2
	return PackedVector2Array([Vector2(0.0, -14.0), Vector2(10.0, 8.0 + wing_flare), Vector2(0.0, 4.0), Vector2(-10.0, 8.0 + wing_flare)])

## Focus shows the true hitbox as a white dot in a vermilion ring with an ink keyline,
## plus a turning seal ring at graze distance. It is drawn last so nothing covers it.
func _draw_focus_marks() -> void:
	var ring_alpha: float = 0.45 * focus_ratio
	var turn: float = animation_time * 1.6
	for arc_index in range(3):
		var start: float = turn + TAU * float(arc_index) / 3.0
		draw_arc(Vector2.ZERO, graze_radius, start, start + TAU / 4.5, 12, Color(1.0, 0.95, 0.86, ring_alpha), 1.5, true)
	draw_circle(Vector2.ZERO, hitbox_radius + 3.4, KEYLINE)
	draw_circle(Vector2.ZERO, hitbox_radius + 2.0, SEAL_RED)
	draw_circle(Vector2.ZERO, hitbox_radius, Color(1.0, 1.0, 1.0, 1.0))
