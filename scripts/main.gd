extends Node2D

const BackgroundScript = preload("res://scripts/background.gd")
const PlayerScript = preload("res://scripts/player.gd")
const BulletScript = preload("res://scripts/bullet.gd")
const EnemyScript = preload("res://scripts/enemy.gd")
const PickupScript = preload("res://scripts/pickup.gd")
const BossScript = preload("res://scripts/boss.gd")
const HudScript = preload("res://scripts/hud.gd")
const StageDirectorScript = preload("res://scripts/stage_director.gd")
const EffectScript = preload("res://scripts/effect.gd")
const AudioManagerScript = preload("res://scripts/audio_manager.gd")

enum GameState { MENU, DIALOGUE, PLAYING, TRANSITION, PAUSED, GAME_OVER, VICTORY }

const WINDOW_SIZE := Vector2i(960, 960)
const PLAYFIELD_RECT := Rect2(24.0, 24.0, 560.0, 912.0)
const SAVE_PATH := "user://save.cfg"
const FINAL_STAGE := 2
const DIFFICULTIES := [
	{
		"key": "easy", "label": "Easy", "enemy_hp": 0.84, "enemy_bullet_speed": 0.90,
		"enemy_fire_interval": 1.14, "enemy_density": -1, "boss_hp": 0.88,
		"boss_bullet_speed": 0.92, "boss_fire_interval": 1.12, "boss_density": -1,
		"score_multiplier": 0.90
	},
	{
		"key": "normal", "label": "Normal", "enemy_hp": 1.00, "enemy_bullet_speed": 1.00,
		"enemy_fire_interval": 1.00, "enemy_density": 0, "boss_hp": 1.00,
		"boss_bullet_speed": 1.00, "boss_fire_interval": 1.00, "boss_density": 0,
		"score_multiplier": 1.00
	},
	{
		"key": "hard", "label": "Hard", "enemy_hp": 1.14, "enemy_bullet_speed": 1.08,
		"enemy_fire_interval": 0.92, "enemy_density": 1, "boss_hp": 1.16,
		"boss_bullet_speed": 1.08, "boss_fire_interval": 0.90, "boss_density": 1,
		"score_multiplier": 1.15
	},
	{
		"key": "lunatic", "label": "Lunatic", "enemy_hp": 1.28, "enemy_bullet_speed": 1.16,
		"enemy_fire_interval": 0.84, "enemy_density": 2, "boss_hp": 1.30,
		"boss_bullet_speed": 1.16, "boss_fire_interval": 0.82, "boss_density": 2,
		"score_multiplier": 1.32
	}
]

var playfield_rect := PLAYFIELD_RECT
var state := GameState.MENU
var score := 0
var best_score := 0
var graze := 0
var lives := 3
var bombs := 3
var power := 35.0
var current_stage := 1
var difficulty_index := 1
var stage_time := 0.0
var bomb_timer := 0.0
var bomb_tick := 0.0
var shake_time := 0.0
var shake_strength := 0.0
var stage_transition_timer := 0.0
var pending_stage := 0
var dialogue_resume_state := GameState.PLAYING
var dialogue_scene: Dictionary = {}
var dialogue_lines: Array = []
var dialogue_index := 0
var current_boss_config: Dictionary = {}

var world_root: Node2D
var background
var enemy_bullet_layer: Node2D
var enemy_layer: Node2D
var pickup_layer: Node2D
var player_bullet_layer: Node2D
var effect_layer: Node2D
var player_layer: Node2D
var hud
var audio
var stage_director = null
var player = null
var boss = null

var enemy_bullets: Array = []
var player_bullets: Array = []
var enemies: Array = []
var pickups: Array = []

func _ready() -> void:
	randomize()
	if DisplayServer.get_name() != "headless":
		get_window().size = WINDOW_SIZE
	ensure_input_map()
	_build_scene()
	_load_best_score()
	_return_to_title()

func _build_scene() -> void:
	world_root = Node2D.new()
	add_child(world_root)
	background = BackgroundScript.new()
	background.configure(playfield_rect)
	world_root.add_child(background)
	pickup_layer = Node2D.new()
	pickup_layer.name = "Pickups"
	world_root.add_child(pickup_layer)
	enemy_bullet_layer = Node2D.new()
	enemy_bullet_layer.name = "EnemyBullets"
	world_root.add_child(enemy_bullet_layer)
	enemy_layer = Node2D.new()
	enemy_layer.name = "Enemies"
	world_root.add_child(enemy_layer)
	player_bullet_layer = Node2D.new()
	player_bullet_layer.name = "PlayerBullets"
	world_root.add_child(player_bullet_layer)
	effect_layer = Node2D.new()
	effect_layer.name = "Effects"
	world_root.add_child(effect_layer)
	player_layer = Node2D.new()
	player_layer.name = "PlayerLayer"
	world_root.add_child(player_layer)
	audio = AudioManagerScript.new()
	add_child(audio)
	hud = HudScript.new()
	hud.setup(playfield_rect, WINDOW_SIZE)
	add_child(hud)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(WINDOW_SIZE.x, WINDOW_SIZE.y)), Color(0.01, 0.015, 0.03), true)
	draw_rect(playfield_rect, Color(0.0, 0.0, 0.0, 0.0), false, 3.0)
	draw_rect(Rect2(playfield_rect.position - Vector2(2.0, 2.0), playfield_rect.size + Vector2(4.0, 4.0)), Color(0.52, 0.92, 1.0, 0.3), false, 2.0)

func _process(delta: float) -> void:
	_update_shake(delta)

func _physics_process(delta: float) -> void:
	if state == GameState.PLAYING:
		stage_time += delta
		if stage_director:
			stage_director.update(self, delta)
		_update_bomb(delta)
	elif state == GameState.TRANSITION:
		stage_transition_timer -= delta
		if stage_transition_timer <= 0.0 and pending_stage > 0:
			_begin_stage(pending_stage)
	background.set_danger_level(1.0 if boss and is_instance_valid(boss) else 0.0)
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if state == GameState.MENU:
		if event.is_action_pressed(&"move_up") or event.is_action_pressed(&"move_left"):
			_cycle_difficulty(-1)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed(&"move_down") or event.is_action_pressed(&"move_right"):
			_cycle_difficulty(1)
			get_viewport().set_input_as_handled()
			return
	if state == GameState.DIALOGUE and (event.is_action_pressed(&"shoot") or event.is_action_pressed(&"ui_accept")):
		if hud.is_dialogue_fully_revealed():
			_advance_dialogue()
		else:
			hud.reveal_dialogue_line()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"pause"):
		match state:
			GameState.PLAYING:
				pause_game()
			GameState.PAUSED:
				resume_game()
			GameState.GAME_OVER, GameState.VICTORY:
				_return_to_title()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"shoot") or event.is_action_pressed(&"ui_accept"):
		match state:
			GameState.MENU:
				start_new_game()
			GameState.PAUSED:
				resume_game()
			GameState.GAME_OVER, GameState.VICTORY:
				start_new_game()
			_:
				pass
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed(&"bomb"):
		if state == GameState.PAUSED:
			_return_to_title()
			get_viewport().set_input_as_handled()

func ensure_input_map() -> void:
	_bind_action(&"move_left", [KEY_A, KEY_LEFT])
	_bind_action(&"move_right", [KEY_D, KEY_RIGHT])
	_bind_action(&"move_up", [KEY_W, KEY_UP])
	_bind_action(&"move_down", [KEY_S, KEY_DOWN])
	_bind_action(&"shoot", [KEY_Z, KEY_SPACE])
	_bind_action(&"focus", [KEY_SHIFT])
	_bind_action(&"bomb", [KEY_X])
	_bind_action(&"pause", [KEY_ESCAPE, KEY_P])
	_bind_action(&"ui_accept", [KEY_ENTER, KEY_KP_ENTER])

func _bind_action(action: StringName, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for keycode in keys:
		var exists := false
		for current in InputMap.action_get_events(action):
			if current is InputEventKey and current.physical_keycode == keycode:
				exists = true
				break
		if not exists:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action, event)

func start_new_game() -> void:
	score = 0
	graze = 0
	lives = 3
	bombs = 3
	power = 35.0
	current_stage = 1
	pending_stage = 0
	stage_transition_timer = 0.0
	dialogue_scene.clear()
	dialogue_lines.clear()
	dialogue_index = 0
	current_boss_config.clear()
	_clear_combat_layers(false)
	hud.hide_title()
	hud.hide_overlay()
	hud.end_dialogue()
	player = PlayerScript.new().setup(self)
	player.begin_run()
	player.connect("bomb_requested", Callable(self, "try_use_bomb"))
	player_layer.add_child(player)
	audio.play_confirm()
	_begin_stage(1)

func _begin_stage(stage_number: int) -> void:
	current_stage = stage_number
	pending_stage = 0
	stage_transition_timer = 0.0
	stage_time = 0.0
	bomb_timer = 0.0
	bomb_tick = 0.0
	current_boss_config.clear()
	_clear_combat_layers(true)
	stage_director = StageDirectorScript.new().setup(stage_number, get_difficulty_key())
	var stage_info: Dictionary = stage_director.get_stage_info()
	background.set_stage_theme(stage_number)
	background.trigger_pulse(stage_info.get("accent_color", Color(1.0, 1.0, 1.0)), 0.28, 0.55)
	if player and is_instance_valid(player):
		player.prepare_for_stage(2.0)
	state = GameState.PLAYING
	hud.hide_overlay()
	hud.end_dialogue()
	hud.flash(stage_info.get("accent_color", Color(1.0, 1.0, 1.0)), 0.45, 0.35)
	show_banner(stage_info.get("title", "Stage"), stage_info.get("subtitle", ""))
	audio.play_stage_theme(stage_number)
	queue_redraw()

func _return_to_title() -> void:
	_clear_combat_layers(false)
	stage_director = null
	dialogue_scene.clear()
	dialogue_lines.clear()
	dialogue_index = 0
	current_boss_config.clear()
	state = GameState.MENU
	pending_stage = 0
	stage_transition_timer = 0.0
	background.set_stage_theme(1)
	background.set_danger_level(0.0)
	hud.set_boss_state(false, 0.0, 1.0, "")
	hud.end_dialogue()
	hud.show_title(best_score, get_difficulty_labels(), difficulty_index)
	hud.flash(Color(0.62, 0.9, 1.0), 0.25, 0.25)
	audio.play_title_theme()
	_update_hud()

func pause_game() -> void:
	if state != GameState.PLAYING:
		return
	state = GameState.PAUSED
	hud.show_pause()
	hud.flash(Color(0.62, 0.82, 1.0), 0.18, 0.18)
	audio.play_pause()
	_update_hud()

func resume_game() -> void:
	if state != GameState.PAUSED:
		return
	state = GameState.PLAYING
	hud.hide_overlay()
	audio.play_confirm()
	_update_hud()

func finish_run(victory: bool) -> void:
	state = GameState.VICTORY if victory else GameState.GAME_OVER
	stage_director = null
	dialogue_scene.clear()
	dialogue_lines.clear()
	dialogue_index = 0
	if score >= best_score:
		best_score = score
		_save_best_score()
	hud.show_result(victory, score, best_score)
	hud.set_boss_state(false, 0.0, 1.0, "")
	if victory:
		audio.play_game_clear()
	_update_hud()

func _clear_combat_layers(keep_player: bool) -> void:
	for layer in [pickup_layer, enemy_bullet_layer, enemy_layer, player_bullet_layer, effect_layer]:
		for child in layer.get_children():
			child.queue_free()
	if not keep_player:
		for child in player_layer.get_children():
			child.queue_free()
		player = null
	enemy_bullets.clear()
	player_bullets.clear()
	enemies.clear()
	pickups.clear()
	boss = null

func is_gameplay_active() -> bool:
	return state == GameState.PLAYING

func get_extended_playfield_rect(margin: float) -> Rect2:
	return Rect2(playfield_rect.position - Vector2.ONE * margin, playfield_rect.size + Vector2.ONE * margin * 2.0)

func get_player_spawn_position() -> Vector2:
	return Vector2(playfield_rect.position.x + playfield_rect.size.x * 0.5, playfield_rect.position.y + playfield_rect.size.y - 90.0)

func point_of_collection_active() -> bool:
	return player and player.is_collectable() and player.global_position.y <= playfield_rect.position.y + 150.0

func get_power_tier() -> int:
	if power < 25.0:
		return 1
	if power < 50.0:
		return 2
	if power < 75.0:
		return 3
	return 4

func angle_to_player(origin: Vector2) -> float:
	if player and player.is_targetable():
		return (player.global_position - origin).angle()
	return -PI * 0.5

func get_difficulty_config() -> Dictionary:
	return DIFFICULTIES[clamp(difficulty_index, 0, DIFFICULTIES.size() - 1)]

func get_difficulty_key() -> String:
	return str(get_difficulty_config().get("key", "normal"))

func get_difficulty_label() -> String:
	return str(get_difficulty_config().get("label", "Normal"))

func get_difficulty_rank() -> int:
	return int(get_difficulty_config().get("boss_density", 0))

func get_difficulty_labels() -> Array:
	var labels: Array = []
	for config in DIFFICULTIES:
		labels.append(str(config.get("label", "")))
	return labels

func _cycle_difficulty(direction: int) -> void:
	difficulty_index = posmod(difficulty_index + direction, DIFFICULTIES.size())
	hud.update_title_difficulty(get_difficulty_labels(), difficulty_index)
	audio.play_confirm()
	_update_hud()

func register_bullet(bullet) -> void:
	if bullet.faction == &"enemy":
		enemy_bullets.append(bullet)
	else:
		player_bullets.append(bullet)

func unregister_bullet(bullet) -> void:
	enemy_bullets.erase(bullet)
	player_bullets.erase(bullet)

func register_enemy(enemy) -> void:
	enemies.append(enemy)

func unregister_enemy(enemy) -> void:
	enemies.erase(enemy)

func register_pickup(pickup) -> void:
	pickups.append(pickup)

func unregister_pickup(pickup) -> void:
	pickups.erase(pickup)

func register_boss(new_boss) -> void:
	boss = new_boss

func unregister_boss(old_boss) -> void:
	if boss == old_boss:
		boss = null

func spawn_player_bullet(position: Vector2, velocity: Vector2, options := {}) -> void:
	var bullet = BulletScript.new().setup(self, position, velocity, &"player", options)
	player_bullet_layer.add_child(bullet)

func spawn_enemy_bullet(position: Vector2, velocity: Vector2, options := {}) -> void:
	var bullet = BulletScript.new().setup(self, position, velocity, &"enemy", options)
	enemy_bullet_layer.add_child(bullet)

func spawn_fan(origin: Vector2, base_angle: float, count: int, spread_deg: float, speed: float, faction: StringName, options := {}) -> void:
	if count <= 0:
		return
	if count == 1:
		var direction_single: Vector2 = Vector2.RIGHT.rotated(base_angle) * speed
		if faction == &"player":
			spawn_player_bullet(origin, direction_single, options)
		else:
			spawn_enemy_bullet(origin, direction_single, options)
		return
	var spread_rad: float = deg_to_rad(spread_deg)
	for index in range(count):
		var weight: float = float(index) / float(count - 1)
		var angle: float = base_angle + lerpf(-spread_rad * 0.5, spread_rad * 0.5, weight)
		var direction: Vector2 = Vector2.RIGHT.rotated(angle) * speed
		if faction == &"player":
			spawn_player_bullet(origin, direction, options)
		else:
			spawn_enemy_bullet(origin, direction, options)

func spawn_radial_burst(origin: Vector2, count: int, speed: float, start_angle: float, faction: StringName, options := {}) -> void:
	for index in range(count):
		var angle: float = start_angle + TAU * float(index) / float(max(1, count))
		var direction: Vector2 = Vector2.RIGHT.rotated(angle) * speed
		if faction == &"player":
			spawn_player_bullet(origin, direction, options)
		else:
			spawn_enemy_bullet(origin, direction, options)

func spawn_enemy(config: Dictionary) -> void:
	if state != GameState.PLAYING:
		return
	var adjusted_config: Dictionary = _scaled_enemy_config(config)
	var enemy = EnemyScript.new().setup(self, adjusted_config)
	enemy_layer.add_child(enemy)

func _scaled_enemy_config(config: Dictionary) -> Dictionary:
	var adjusted: Dictionary = config.duplicate(true)
	var difficulty: Dictionary = get_difficulty_config()
	adjusted["hp"] = float(adjusted.get("hp", 24.0)) * float(difficulty.get("enemy_hp", 1.0))
	adjusted["bullet_speed"] = float(adjusted.get("bullet_speed", 180.0)) * float(difficulty.get("enemy_bullet_speed", 1.0))
	adjusted["shoot_interval"] = max(0.08, float(adjusted.get("shoot_interval", 1.0)) * float(difficulty.get("enemy_fire_interval", 1.0)))
	var density: int = int(difficulty.get("enemy_density", 0))
	if adjusted.has("shot_count"):
		adjusted["shot_count"] = max(1, int(adjusted.get("shot_count", 1)) + density)
	if adjusted.has("ring_count"):
		adjusted["ring_count"] = max(6, int(adjusted.get("ring_count", 10)) + density * 2)
	return adjusted

func spawn_boss(config := {}) -> void:
	if boss or state != GameState.PLAYING:
		return
	var boss_config: Dictionary = _scaled_boss_config(config)
	current_boss_config = boss_config.duplicate(true)
	show_banner(str(boss_config.get("name", "Boss Approaching")), str(boss_config.get("subtitle", "")))
	var new_boss = BossScript.new().setup(self, boss_config)
	enemy_layer.add_child(new_boss)
	background.trigger_pulse(boss_config.get("accent_color", Color(1.0, 0.84, 0.6)), 0.32, 0.65)
	hud.flash(boss_config.get("accent_color", Color(1.0, 0.84, 0.6)), 0.5, 0.4)
	hud.show_boss_spotlight(boss_config, 2.6)
	shake_screen(0.8, 6.0)
	audio.play_boss_theme(current_stage)

func _scaled_boss_config(config: Dictionary) -> Dictionary:
	var adjusted: Dictionary = config.duplicate(true)
	var difficulty: Dictionary = get_difficulty_config()
	var phases: Array = adjusted.get("phases", [])
	var new_phases: Array = []
	for phase in phases:
		var entry: Dictionary = phase.duplicate(true)
		entry["hp"] = float(entry.get("hp", 500.0)) * float(difficulty.get("boss_hp", 1.0))
		new_phases.append(entry)
	adjusted["phases"] = new_phases
	return adjusted

func try_player_bullet_hit(bullet) -> bool:
	if boss and is_instance_valid(boss) and boss.is_targetable():
		if bullet.global_position.distance_squared_to(boss.global_position) <= pow(boss.radius + bullet.radius, 2.0):
			if boss.take_damage(bullet.damage):
				add_score(10)
			return true
	for enemy in enemies.duplicate():
		if is_instance_valid(enemy) and enemy.is_targetable():
			if bullet.global_position.distance_squared_to(enemy.global_position) <= pow(enemy.radius + bullet.radius, 2.0):
				enemy.take_damage(bullet.damage)
				add_score(4)
				return true
	return false

func on_player_hit() -> void:
	if state != GameState.PLAYING or not player or not player.can_be_hit():
		return
	player.on_got_hit()
	spawn_explosion_effect(player.global_position, Color(1.0, 0.55, 0.72), 34.0, 0.6)
	spawn_spark_effect(player.global_position, Color(1.0, 0.7, 0.82), 48.0, 0.35, 18)
	hud.flash(Color(1.0, 0.45, 0.55), 0.55, 0.3)
	background.trigger_pulse(Color(1.0, 0.4, 0.55), 0.24, 0.4)
	shake_screen(0.6, 10.0)
	cancel_all_enemy_bullets(true)
	lives -= 1
	bombs = 3
	power = max(10.0, power - 20.0)
	_spawn_power_loss(player.global_position)
	audio.play_player_hit()
	if lives <= 0:
		player.visible_ship = false
		finish_run(false)
	else:
		player.start_respawn()
	_update_hud()

func _spawn_power_loss(origin: Vector2) -> void:
	for index in range(4):
		var offset: Vector2 = Vector2.RIGHT.rotated((TAU * float(index) / 4.0) + randf() * 0.3) * randf_range(10.0, 28.0)
		var pickup = PickupScript.new().setup(self, origin + offset, &"power", {
			"velocity": Vector2(offset.x * 3.5, -100.0 - randf_range(0.0, 30.0))
		})
		pickup_layer.add_child(pickup)

func try_use_bomb() -> void:
	if state != GameState.PLAYING or bomb_timer > 0.0 or bombs <= 0 or not player or not player.is_targetable():
		return
	bombs -= 1
	bomb_timer = 1.1
	bomb_tick = 0.0
	player.set_invulnerable(1.8)
	spawn_ring_effect(player.global_position, Color(0.7, 0.96, 1.0), 18.0, 320.0, 1.0, 5.0)
	spawn_ring_effect(player.global_position, Color(1.0, 0.7, 0.96), 10.0, 220.0, 0.7, 3.0)
	spawn_spark_effect(player.global_position, Color(1.0, 0.92, 0.68), 92.0, 0.65, 26)
	cancel_all_enemy_bullets(true)
	hud.flash(Color(0.86, 0.96, 1.0), 0.72, 0.36)
	background.trigger_pulse(Color(0.76, 0.92, 1.0), 0.34, 0.55)
	shake_screen(0.45, 7.0)
	audio.play_bomb()
	_update_hud()

func _update_bomb(delta: float) -> void:
	if bomb_timer <= 0.0:
		return
	bomb_timer -= delta
	bomb_tick -= delta
	if player and player.is_targetable() and bomb_tick <= 0.0:
		bomb_tick = 0.18
		spawn_ring_effect(player.global_position, Color(0.86, 0.96, 1.0), 12.0, 140.0, 0.35, 2.0)
		for bullet in enemy_bullets.duplicate():
			if is_instance_valid(bullet) and bullet.global_position.distance_squared_to(player.global_position) <= pow(280.0, 2.0):
				bullet.destroy(true, true)
		for enemy in enemies.duplicate():
			if is_instance_valid(enemy) and enemy.is_targetable():
				enemy.take_damage(34.0)
		if boss and is_instance_valid(boss) and boss.is_targetable():
			boss.take_damage(46.0)

func on_player_graze(position: Vector2) -> void:
	graze += 1
	add_score(80 + int(power * 4.0))
	if graze % 8 == 0:
		spawn_ring_effect(position, Color(0.74, 0.94, 1.0), 4.0, 20.0, 0.18, 2.0)
	if graze % 4 == 0:
		spawn_spark_effect(position, Color(0.86, 0.98, 1.0), 24.0, 0.15, 10)
	audio.play_graze()
	_update_hud()

func on_enemy_destroyed(enemy) -> void:
	add_score(enemy.score_value)
	spawn_explosion_effect(enemy.global_position, enemy.bullet_color, enemy.radius * 1.5, 0.55)
	spawn_spark_effect(enemy.global_position, enemy.bullet_color.lightened(0.2), enemy.radius * 2.2, 0.3, 12)
	audio.play_enemy_down()
	for index in range(int(enemy.point_drops)):
		var point_item = PickupScript.new().setup(self, enemy.global_position, &"point", {
			"velocity": Vector2(randf_range(-50.0, 50.0), randf_range(-140.0, -70.0))
		})
		pickup_layer.add_child(point_item)
	for index in range(int(enemy.power_drops)):
		var power_item = PickupScript.new().setup(self, enemy.global_position, &"power", {
			"velocity": Vector2(randf_range(-42.0, 42.0), randf_range(-150.0, -80.0))
		})
		pickup_layer.add_child(power_item)

func collect_pickup(pickup) -> void:
	if pickup.pickup_type == &"power":
		if power >= 100.0:
			add_score(1600)
		else:
			power = min(100.0, power + 12.0)
			add_score(300)
		audio.play_pickup(true)
	else:
		var bonus_ratio := 1.0
		if player:
			bonus_ratio = clamp(1.0 - inverse_lerp(playfield_rect.position.y + playfield_rect.size.y, playfield_rect.position.y, player.global_position.y), 0.25, 1.0)
		add_score(int(900 + 1800 * bonus_ratio))
		audio.play_pickup(false)
	spawn_ring_effect(pickup.global_position, Color(1.0, 1.0, 1.0), 4.0, 22.0, 0.18, 2.0)
	_update_hud()

func cancel_all_enemy_bullets(with_score := false) -> void:
	for bullet in enemy_bullets.duplicate():
		if is_instance_valid(bullet):
			if with_score:
				add_score(8)
			bullet.destroy(true, true)

func spawn_ring_effect(position: Vector2, color: Color, from_radius: float, to_radius: float, duration := 0.45, width := 3.0) -> void:
	var effect = EffectScript.new().configure_ring(color, from_radius, to_radius, duration, width)
	effect.global_position = position
	effect_layer.add_child(effect)

func spawn_explosion_effect(position: Vector2, color: Color, size := 22.0, duration := 0.55) -> void:
	var effect = EffectScript.new().configure_explosion(color, size, duration)
	effect.global_position = position
	effect_layer.add_child(effect)

func spawn_spark_effect(position: Vector2, color: Color, length := 28.0, duration := 0.35, fragments := 12) -> void:
	var effect = EffectScript.new().configure_sparks(color, length, duration, fragments)
	effect.global_position = position
	effect_layer.add_child(effect)

func shake_screen(duration: float, strength: float) -> void:
	shake_time = max(shake_time, duration)
	shake_strength = max(shake_strength, strength)

func _update_shake(delta: float) -> void:
	if shake_time > 0.0:
		shake_time = max(0.0, shake_time - delta)
		world_root.position = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
		shake_strength = lerpf(shake_strength, 0.0, delta * 3.4)
	else:
		world_root.position = Vector2.ZERO
		shake_strength = 0.0

func add_score(amount: int) -> void:
	var scaled_amount: int = int(round(float(amount) * float(get_difficulty_config().get("score_multiplier", 1.0))))
	score += scaled_amount
	if score > best_score:
		best_score = score

func show_banner(title: String, subtitle := "") -> void:
	hud.show_banner(title, subtitle)

func start_dialogue(scene: Dictionary) -> void:
	if scene.is_empty():
		return
	dialogue_scene = scene.duplicate(true)
	dialogue_lines = dialogue_scene.get("lines", [])
	if dialogue_lines.is_empty():
		return
	dialogue_index = 0
	dialogue_resume_state = GameState.PLAYING
	state = GameState.DIALOGUE
	hud.begin_dialogue(dialogue_scene)
	_show_dialogue_line()

func _show_dialogue_line() -> void:
	if dialogue_index < 0 or dialogue_index >= dialogue_lines.size():
		_finish_dialogue()
		return
	var line: Dictionary = dialogue_lines[dialogue_index]
	hud.show_dialogue_line(line, dialogue_index + 1, dialogue_lines.size())

func _advance_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index >= dialogue_lines.size():
		_finish_dialogue()
	else:
		_show_dialogue_line()

func _finish_dialogue() -> void:
	hud.end_dialogue()
	dialogue_scene.clear()
	dialogue_lines.clear()
	dialogue_index = 0
	state = dialogue_resume_state

func on_boss_phase_changed(phase_name: String, current_hp: float, max_hp_value: float) -> void:
	hud.set_boss_state(true, current_hp, max_hp_value, phase_name)
	if phase_name != "Phase Break":
		show_banner(phase_name, "小心阅读弹流间的空隙")
		hud.flash(Color(1.0, 0.92, 0.68), 0.32, 0.26)
		background.trigger_pulse(Color(1.0, 0.82, 0.52), 0.18, 0.26)
		if phase_name.begins_with("Last Spell") and not current_boss_config.is_empty():
			hud.show_boss_spotlight(current_boss_config, 2.1)
		audio.play_phase_break()

func on_boss_phase_cleared(phase_name: String) -> void:
	show_banner("Phase Break", phase_name)
	hud.flash(Color(1.0, 0.88, 0.52), 0.5, 0.35)
	background.trigger_pulse(Color(1.0, 0.84, 0.56), 0.24, 0.42)
	shake_screen(0.5, 9.0)
	audio.play_phase_break()

func on_boss_defeated() -> void:
	add_score(220000 + current_stage * 40000)
	background.trigger_pulse(Color(1.0, 0.94, 0.72), 0.4, 0.7)
	hud.flash(Color(1.0, 0.95, 0.8), 0.8, 0.55)
	if current_stage < FINAL_STAGE:
		_start_stage_transition()
	else:
		show_banner("All Clear", "你突破了最后的边界")
		finish_run(true)

func _start_stage_transition() -> void:
	state = GameState.TRANSITION
	stage_director = null
	pending_stage = current_stage + 1
	stage_transition_timer = 3.2
	cancel_all_enemy_bullets(false)
	_clear_combat_layers(true)
	bombs = min(bombs + 1, 5)
	if player and is_instance_valid(player):
		player.prepare_for_stage(3.5)
	var next_director = StageDirectorScript.new().setup(pending_stage, get_difficulty_key())
	var stage_info: Dictionary = next_director.get_stage_info()
	hud.show_stage_transition(pending_stage, stage_info.get("title", "Next Stage"), stage_info.get("subtitle", ""))
	show_banner("Stage %d Clear" % current_stage, "短暂整备后进入下一关")
	background.trigger_pulse(stage_info.get("accent_color", Color(1.0, 1.0, 1.0)), 0.28, 0.6)
	audio.play_stage_transition()

func _update_hud() -> void:
	hud.set_status({
		"score": score,
		"best_score": best_score,
		"lives": lives,
		"bombs": bombs,
		"power": int(power),
		"graze": graze,
		"stage_text": "Stage %d / %d" % [current_stage, FINAL_STAGE],
		"state_text": _state_text(),
		"difficulty_text": get_difficulty_label()
	})
	if state == GameState.MENU:
		hud.update_title_difficulty(get_difficulty_labels(), difficulty_index)
	if boss and is_instance_valid(boss):
		hud.set_boss_state(true, boss.hp, boss.max_hp, boss.current_phase_name)
	elif state != GameState.MENU:
		hud.set_boss_state(false, 0.0, 1.0, "")

func _state_text() -> String:
	match state:
		GameState.MENU:
			return "Title"
		GameState.DIALOGUE:
			return "Dialogue"
		GameState.PLAYING:
			return "Battle"
		GameState.TRANSITION:
			return "Transition"
		GameState.PAUSED:
			return "Paused"
		GameState.GAME_OVER:
			return "Game Over"
		GameState.VICTORY:
			return "All Clear"
	return ""

func _load_best_score() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		best_score = int(config.get_value("save", "best_score", 0))

func _save_best_score() -> void:
	var config := ConfigFile.new()
	config.set_value("save", "best_score", best_score)
	config.save(SAVE_PATH)

func on_player_shot(focus_ratio: float) -> void:
	audio.play_player_shot(focus_ratio)

func on_enemy_fired(pattern: StringName) -> void:
	audio.play_enemy_fire(pattern)
