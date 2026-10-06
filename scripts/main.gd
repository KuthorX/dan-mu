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
const I18n = preload("res://scripts/i18n.gd")
const DebugHooksScript = preload("res://scripts/debug_hooks.gd")
const ScreenFrameScript = preload("res://scripts/screen_frame.gd")

enum GameState { MENU, DIALOGUE, REWARD, PLAYING, TRANSITION, PAUSED, GAME_OVER, VICTORY }

const WINDOW_SIZE := Vector2i(960, 960)
const PLAYFIELD_RECT := Rect2(24.0, 24.0, 560.0, 912.0)
const SAVE_PATH := "user://save.cfg"
const SAVE_VERSION := 2
const FINAL_STAGE := 5
const MAX_POWER := 200.0
const BASE_OPTION_COUNT_BY_TIER := [2, 2, 4, 4, 6, 6, 8, 8]
const MAX_PLAYER_OPTIONS := 10
const MAX_PLAYER_OPTION_BONUS := 8
const PLAYER_SHIPS := [
	{
		"key": "spirit", "label": "SHIP_SPIRIT",
		"description": "SHIP_SPIRIT_DESC",
		"fast_speed": 330.0, "slow_speed": 165.0,
		"primary_color": Color(0.72, 0.96, 1.0),
		"secondary_color": Color(0.95, 0.74, 1.0)
	},
	{
		"key": "gale", "label": "SHIP_GALE",
		"description": "SHIP_GALE_DESC",
		"fast_speed": 352.0, "slow_speed": 172.0,
		"graze_radius": 26.0,
		"primary_color": Color(0.62, 1.0, 0.88),
		"secondary_color": Color(1.0, 0.86, 0.52)
	},
	{
		"key": "lance", "label": "SHIP_LANCE",
		"description": "SHIP_LANCE_DESC",
		"fast_speed": 318.0, "slow_speed": 154.0,
		"hitbox_radius": 3.2,
		"primary_color": Color(1.0, 0.88, 0.58),
		"secondary_color": Color(0.72, 0.84, 1.0)
	}
]
const DIFFICULTIES := [
	{
		"key": "easy", "label": "DIFF_EASY", "enemy_hp": 0.84, "enemy_bullet_speed": 0.90,
		"enemy_fire_interval": 1.14, "enemy_density": -1, "boss_hp": 0.88,
		"boss_bullet_speed": 0.92, "boss_fire_interval": 1.12, "boss_density": -1,
		"score_multiplier": 1.00
	},
	{
		"key": "normal", "label": "DIFF_NORMAL", "enemy_hp": 1.00, "enemy_bullet_speed": 1.00,
		"enemy_fire_interval": 1.00, "enemy_density": 0, "boss_hp": 1.00,
		"boss_bullet_speed": 1.00, "boss_fire_interval": 1.00, "boss_density": 0,
		"score_multiplier": 1.18
	},
	{
		"key": "hard", "label": "DIFF_HARD", "enemy_hp": 1.14, "enemy_bullet_speed": 1.08,
		"enemy_fire_interval": 0.92, "enemy_density": 1, "boss_hp": 1.16,
		"boss_bullet_speed": 1.08, "boss_fire_interval": 0.90, "boss_density": 1,
		"score_multiplier": 1.42
	},
	{
		"key": "lunatic", "label": "DIFF_LUNATIC", "enemy_hp": 1.28, "enemy_bullet_speed": 1.16,
		"enemy_fire_interval": 0.84, "enemy_density": 2, "boss_hp": 1.30,
		"boss_bullet_speed": 1.16, "boss_fire_interval": 0.82, "boss_density": 2,
		"score_multiplier": 1.78
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
var ship_index := 0
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
var current_bomb_profile: Dictionary = {}
var reward_options: Array = []
var reward_index := 0
var reward_title := ""
var reward_subtitle := ""
var reward_refreshes := 0
var reward_intro_timer := 0.0
var reward_input_armed := true
var endless_unlocked := true
var menu_mode_index := 0
var endless_mode_active := false
var endless_wave := 0
var endless_score_multiplier := 1.0
var endless_leaderboard: Array = []
var endless_run_time := 0.0
var endless_spawn_events: Array = []
var endless_spawn_index := 0
var endless_wave_elapsed := 0.0
var endless_clear_grace := 0.0
var infinite_lives_cheat := false
var player_damage_multiplier := 1.0
var player_fire_rate_multiplier := 1.0
var player_option_bonus := 0
var pickup_magnet_bonus := 0.0
var reward_score_bonus_multiplier := 1.0
var bomb_visual_angle := 0.0

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
var bosses: Array = []

var enemy_bullets: Array = []
var player_bullets: Array = []
var enemies: Array = []
var pickups: Array = []

func _ready() -> void:
	randomize()
	I18n.apply_saved_or_default()
	_apply_window_title()
	if DisplayServer.get_name() != "headless" and not OS.has_feature("web"):
		get_window().size = WINDOW_SIZE
	get_tree().auto_accept_quit = false
	ensure_input_map()
	_build_scene()
	_load_best_score()
	_return_to_title()
	var hook_params: Dictionary = DebugHooksScript.read_params()
	if hook_params.has(DebugHooksScript.PARAM_SHOT):
		add_child(DebugHooksScript.new().setup(self, hook_params))

func _build_scene() -> void:
	add_child(ScreenFrameScript.new().configure(Vector2(WINDOW_SIZE), playfield_rect))
	# everything in the world is clipped to the playfield so nothing spills onto the frame
	var world_clip := Control.new()
	world_clip.position = playfield_rect.position
	world_clip.size = playfield_rect.size
	world_clip.clip_contents = true
	world_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(world_clip)
	world_root = Node2D.new()
	world_root.position = -playfield_rect.position
	world_clip.add_child(world_root)
	background = BackgroundScript.new()
	background.configure(playfield_rect)
	background.z_index = -2
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
	hud.connect("language_toggle_requested", Callable(self, "_toggle_language"))

func _process(delta: float) -> void:
	_update_shake(delta)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit_cleanly()

## Audio playbacks are only released by the AudioServer on a later frame, so
## stop them first and quit after the server has had time to drop them.
func _quit_cleanly() -> void:
	if audio:
		audio.shutdown()
	for _frame in range(3):
		await get_tree().process_frame
	get_tree().quit()

func _physics_process(delta: float) -> void:
	if state == GameState.PLAYING:
		stage_time += delta
		if endless_mode_active:
			endless_run_time += delta
			_update_endless_mode(delta)
		elif stage_director:
			stage_director.update(self, delta)
		_update_bomb(delta)
	elif state == GameState.REWARD:
		var was_locked: bool = reward_intro_timer > 0.0
		reward_intro_timer = max(0.0, reward_intro_timer - delta)
		if not reward_input_armed and reward_intro_timer <= 0.0 and not Input.is_action_pressed(&"shoot") and not Input.is_action_pressed(&"ui_accept"):
			reward_input_armed = true
			_update_reward_selection_ui(false)
		elif was_locked and reward_intro_timer <= 0.0:
			_update_reward_selection_ui(false)
	elif state == GameState.TRANSITION:
		stage_transition_timer -= delta
		if stage_transition_timer <= 0.0 and pending_stage > 0:
			_begin_stage(pending_stage)
	background.set_danger_level(1.0 if _active_boss_count() > 0 else 0.0)
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if _handle_cheat_input(event):
		get_viewport().set_input_as_handled()
		return
	if state == GameState.MENU:
		if event.is_action_pressed(&"toggle_language"):
			_toggle_language()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed(&"focus"):
			_cycle_menu_mode()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed(&"move_up"):
			_cycle_difficulty(-1)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed(&"move_down"):
			_cycle_difficulty(1)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed(&"move_left"):
			_cycle_ship(-1)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed(&"move_right"):
			_cycle_ship(1)
			get_viewport().set_input_as_handled()
			return
	if state == GameState.REWARD:
		if reward_intro_timer > 0.0 or not reward_input_armed:
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed(&"move_up") or event.is_action_pressed(&"move_left"):
			_cycle_reward_selection(-1)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed(&"move_down") or event.is_action_pressed(&"move_right"):
			_cycle_reward_selection(1)
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed(&"focus"):
			_refresh_reward_selection()
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
			GameState.REWARD:
				_confirm_reward_selection()
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

func _handle_cheat_input(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	if not event.is_pressed() or event.is_echo():
		return false
	if event.physical_keycode != KEY_P:
		return false
	_toggle_infinite_lives_cheat()
	return true

func _toggle_infinite_lives_cheat() -> void:
	infinite_lives_cheat = not infinite_lives_cheat
	if infinite_lives_cheat:
		lives = max(lives, 99)
		show_banner(tr("BANNER_CHEAT_ON"), tr("BANNER_CHEAT_ON_SUB"))
		hud.flash(Color(1.0, 0.82, 0.56), 0.28, 0.26)
		background.trigger_pulse(Color(1.0, 0.78, 0.56), 0.2, 0.3)
	else:
		show_banner(tr("BANNER_CHEAT_OFF"), tr("BANNER_CHEAT_OFF_SUB"))
		hud.flash(Color(0.62, 0.88, 1.0), 0.22, 0.22)
	audio.play_confirm()
	_update_hud()

func ensure_input_map() -> void:
	_bind_action(&"move_left", [KEY_A, KEY_LEFT])
	_bind_action(&"move_right", [KEY_D, KEY_RIGHT])
	_bind_action(&"move_up", [KEY_W, KEY_UP])
	_bind_action(&"move_down", [KEY_S, KEY_DOWN])
	_bind_action(&"shoot", [KEY_Z, KEY_SPACE])
	_bind_action(&"focus", [KEY_SHIFT])
	_bind_action(&"bomb", [KEY_X])
	_bind_action(&"pause", [KEY_ESCAPE])
	_bind_action(&"toggle_language", [KEY_L])
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
	lives = 99 if infinite_lives_cheat else 3
	bombs = 3
	power = 35.0
	current_bomb_profile.clear()
	reward_options.clear()
	reward_index = 0
	reward_title = ""
	reward_subtitle = ""
	reward_refreshes = 0
	reward_intro_timer = 0.0
	endless_mode_active = false
	endless_wave = 0
	endless_score_multiplier = 1.0
	endless_run_time = 0.0
	endless_spawn_events.clear()
	endless_spawn_index = 0
	endless_wave_elapsed = 0.0
	endless_clear_grace = 0.0
	player_damage_multiplier = 1.0
	player_fire_rate_multiplier = 1.0
	player_option_bonus = 0
	pickup_magnet_bonus = 0.0
	reward_score_bonus_multiplier = 1.0
	bomb_visual_angle = 0.0
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
	player = PlayerScript.new().setup(self, get_ship_config())
	player.begin_run()
	player.connect("bomb_requested", Callable(self, "try_use_bomb"))
	player_layer.add_child(player)
	audio.play_confirm()
	if menu_mode_index == 1 and endless_unlocked:
		_begin_endless_run()
	else:
		_begin_stage(1)

func _begin_stage(stage_number: int) -> void:
	endless_mode_active = false
	current_stage = stage_number
	pending_stage = 0
	stage_transition_timer = 0.0
	stage_time = 0.0
	bomb_timer = 0.0
	bomb_tick = 0.0
	bomb_visual_angle = 0.0
	current_boss_config.clear()
	reward_options.clear()
	reward_index = 0
	reward_title = ""
	reward_subtitle = ""
	reward_refreshes = 0
	reward_intro_timer = 0.0
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
	show_banner(stage_info.get("title", tr("UI_STAGE_FALLBACK")), stage_info.get("subtitle", ""))
	audio.play_stage_theme(stage_number)
	queue_redraw()

func _begin_endless_run() -> void:
	endless_mode_active = true
	stage_director = null
	current_stage = 1
	pending_stage = 0
	stage_transition_timer = 0.0
	stage_time = 0.0
	bomb_timer = 0.0
	bomb_tick = 0.0
	bomb_visual_angle = 0.0
	current_boss_config.clear()
	reward_options.clear()
	reward_index = 0
	reward_title = ""
	reward_subtitle = ""
	reward_refreshes = 0
	endless_wave = 0
	endless_score_multiplier = 1.0
	endless_run_time = 0.0
	endless_spawn_events.clear()
	endless_spawn_index = 0
	endless_wave_elapsed = 0.0
	endless_clear_grace = 0.0
	_clear_combat_layers(true)
	background.set_stage_theme(1)
	if player and is_instance_valid(player):
		player.prepare_for_stage(2.2)
	state = GameState.PLAYING
	hud.hide_overlay()
	hud.end_dialogue()
	hud.flash(Color(0.96, 0.78, 1.0), 0.38, 0.3)
	show_banner(tr("MODE_ENDLESS"), tr("BANNER_ENDLESS_SUB"))
	background.trigger_pulse(Color(0.96, 0.78, 1.0), 0.24, 0.36)
	audio.play_stage_theme(5)
	_begin_endless_wave()

func _endless_wave_multiplier() -> float:
	return 1.0 + float(max(0, endless_wave - 1)) * 0.12

func _endless_board_title() -> String:
	return tr("ENDLESS_BOARD_TITLE")

func _endless_board_text() -> String:
	if endless_leaderboard.is_empty():
		return tr("ENDLESS_BOARD_EMPTY")
	var lines: Array[String] = []
	for index in range(min(4, endless_leaderboard.size())):
		var record: Dictionary = endless_leaderboard[index]
		var total_seconds: int = int(record.get("time", 0))
		var minutes: int = total_seconds / 60
		var seconds: int = total_seconds % 60
		lines.append(tr("ENDLESS_BOARD_ROW") % [index + 1, int(record.get("wave", 0)), int(record.get("score", 0)), minutes, seconds])
		lines.append("   %s / %s" % [_ship_label_for(str(record.get("ship", "spirit"))), _difficulty_label_for(str(record.get("difficulty", "normal")))])
	return "\n".join(lines)

func _sort_endless_records(a: Dictionary, b: Dictionary) -> bool:
	var a_wave: int = int(a.get("wave", 0))
	var b_wave: int = int(b.get("wave", 0))
	if a_wave == b_wave:
		return int(a.get("score", 0)) > int(b.get("score", 0))
	return a_wave > b_wave

func _return_to_title() -> void:
	_clear_combat_layers(false)
	stage_director = null
	endless_mode_active = false
	endless_wave = 0
	endless_score_multiplier = 1.0
	endless_run_time = 0.0
	endless_spawn_events.clear()
	endless_spawn_index = 0
	endless_wave_elapsed = 0.0
	endless_clear_grace = 0.0
	current_bomb_profile.clear()
	reward_options.clear()
	reward_index = 0
	reward_title = ""
	reward_subtitle = ""
	reward_refreshes = 0
	reward_intro_timer = 0.0
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
	hud.show_title(best_score, get_difficulty_labels(), difficulty_index, get_ship_label(), get_ship_description(), _menu_mode_label(), _menu_mode_description(), _endless_board_title(), _endless_board_text())
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
	if victory and not endless_mode_active:
		endless_unlocked = true
	if endless_mode_active:
		_record_endless_result()
	state = GameState.VICTORY if victory else GameState.GAME_OVER
	stage_director = null
	endless_mode_active = false
	endless_wave = 0
	endless_score_multiplier = 1.0
	endless_spawn_events.clear()
	endless_spawn_index = 0
	endless_wave_elapsed = 0.0
	endless_clear_grace = 0.0
	reward_options.clear()
	reward_title = ""
	reward_subtitle = ""
	reward_refreshes = 0
	reward_intro_timer = 0.0
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
	bosses.clear()
	boss = null

func is_gameplay_active() -> bool:
	return state == GameState.PLAYING

func _endless_theme_stage() -> int:
	return 1 + int(posmod(endless_wave - 1, FINAL_STAGE))

func _begin_endless_wave() -> void:
	endless_wave += 1
	endless_score_multiplier = _endless_wave_multiplier()
	current_stage = _endless_theme_stage()
	stage_time = 0.0
	endless_wave_elapsed = 0.0
	endless_spawn_index = 0
	endless_clear_grace = 0.85
	endless_spawn_events = _build_endless_wave_events(endless_wave)
	current_boss_config.clear()
	background.set_stage_theme(current_stage)
	show_banner(tr("BANNER_ENDLESS_WAVE") % endless_wave, tr("BANNER_ENDLESS_WAVE_SUB"))
	background.trigger_pulse(Color(0.92, 0.76, 1.0), 0.2, 0.28)
	if player and is_instance_valid(player):
		player.set_invulnerable(0.9)
	audio.play_stage_theme(5)

func _sort_endless_events(a: Dictionary, b: Dictionary) -> bool:
	return float(a.get("time", 0.0)) < float(b.get("time", 0.0))

func _build_endless_wave_events(wave: int) -> Array:
	var events: Array = []
	var intensity: float = 1.0 + float(wave - 1) * 0.08
	var lanes: int = min(8, 4 + int(floor(float(wave) / 3.0)))
	for opener in range(lanes):
		events.append({
			"time": 0.8 + float(opener) * 0.22,
			"type": "enemy",
			"config": {
				"name": "mirror" if wave % 2 == 0 else "anchor",
				"spawn": Vector2(-40.0, 86.0 + float(opener) * 24.0),
				"motion": &"curve",
				"velocity": Vector2(176.0 + intensity * 18.0, 114.0 + intensity * 8.0),
				"curve_strength": 42.0,
				"hp": 32.0 + intensity * 8.0,
				"radius": 18.0,
				"shoot_pattern": &"split_fan",
				"shoot_interval": 0.78,
				"bullet_speed": 198.0 + intensity * 12.0,
				"shot_count": 4,
				"spread_deg": 46.0,
				"bullet_shape": &"needle",
				"bullet_color": Color(0.72, 0.98, 1.0),
				"score": 1800 + wave * 80,
				"point_drops": 1
			}
		})
		events.append({
			"time": 0.92 + float(opener) * 0.22,
			"type": "enemy",
			"config": {
				"name": "reaper" if wave % 2 == 0 else "shade",
				"spawn": Vector2(648.0, 108.0 + float(opener) * 24.0),
				"motion": &"curve",
				"velocity": Vector2(-176.0 - intensity * 18.0, 114.0 + intensity * 8.0),
				"curve_strength": -42.0,
				"hp": 32.0 + intensity * 8.0,
				"radius": 18.0,
				"shoot_pattern": &"mine_burst",
				"shoot_interval": 0.96,
				"bullet_speed": 186.0 + intensity * 10.0,
				"ring_count": 8,
				"shot_count": 4,
				"spread_deg": 44.0,
				"bullet_shape": &"orb",
				"bullet_color": Color(1.0, 0.68, 0.58),
				"score": 1800 + wave * 80,
				"point_drops": 1
			}
		})
	for mid in range(3 + int(wave / 4)):
		events.append({
			"time": 3.4 + float(mid) * 0.58,
			"type": "enemy",
			"config": {
				"name": "guardian",
				"spawn": Vector2(110.0 + float(mid % 3) * 160.0, -80.0),
				"motion": &"approach_hold",
				"destination": Vector2(110.0 + float(mid % 3) * 160.0, 164.0 + float(mid % 2) * 20.0),
				"hold_time": 1.9,
				"retreat_velocity": Vector2(0.0, 128.0),
				"approach_speed": 1.8,
				"hp": 96.0 + intensity * 18.0,
				"radius": 24.0,
				"shoot_pattern": &"cross_fan",
				"shoot_interval": 0.68,
				"bullet_speed": 196.0 + intensity * 10.0,
				"shot_count": 6,
				"spread_deg": 72.0,
				"bullet_shape": &"petal",
				"bullet_color": Color(0.88, 0.62, 1.0),
				"score": 4200 + wave * 120,
				"point_drops": 2,
				"power_drops": 1
			}
		})
	if wave % 5 == 0:
		events.append({"time": 6.8, "type": "boss", "config": _build_endless_boss_config(wave, false)})
	if wave >= 10 and wave % 10 == 0:
		events.append({"time": 6.6, "type": "boss", "config": _build_endless_boss_config(wave, true)})
		events.append({"time": 7.4, "type": "boss", "config": _build_endless_boss_config(wave + 1, true)})
	events.sort_custom(Callable(self, "_sort_endless_events"))
	return events

func _build_endless_boss_config(wave: int, allow_multi := false) -> Dictionary:
	var title_suffix := tr("ENDLESS_CORE_TWIN") if allow_multi else tr("ENDLESS_CORE_SINGLE")
	var accent := Color(1.0, 0.74, 0.56) if wave % 2 == 0 else Color(0.74, 0.96, 1.0)
	var secondary := Color(0.72, 0.94, 1.0) if wave % 2 == 0 else Color(1.0, 0.72, 0.64)
	var hp_scale: float = 1.0 + float(wave - 1) * 0.09
	return {
		"allow_multi": allow_multi,
		"name": tr("ENDLESS_BOSS_NAME") % [wave, title_suffix],
		"subtitle": tr("ENDLESS_BOSS_SUB"),
		"radius": 34.0 if allow_multi else 40.0,
		"accent_color": accent,
		"secondary_color": secondary,
		"portrait_side": "right",
		"mood": "angry",
		"motif": "crown",
		"phases": [
			{"name": tr("PHASE_FINAL_LATTICE_WHEEL"), "hp": (420.0 if allow_multi else 760.0) * hp_scale, "color": accent, "bonus": 80000, "pattern": &"eclipse_lattice", "subtitle": tr("ENDLESS_P1_SUB"), "mood": "angry", "motif": "gear", "quote": tr("ENDLESS_P1_QUOTE")},
			{"name": tr("PHASE_CROWN_JUDGMENT"), "hp": (540.0 if allow_multi else 980.0) * hp_scale, "color": secondary, "bonus": 120000, "pattern": &"crown_judgment", "subtitle": tr("ENDLESS_P2_SUB"), "mood": "angry", "motif": "crown", "quote": tr("ENDLESS_P2_QUOTE")}
		]
	}

func _update_endless_mode(delta: float) -> void:
	endless_wave_elapsed += delta
	while endless_spawn_index < endless_spawn_events.size() and endless_wave_elapsed >= float(endless_spawn_events[endless_spawn_index].get("time", 0.0)):
		var event: Dictionary = endless_spawn_events[endless_spawn_index]
		endless_spawn_index += 1
		match str(event.get("type", "enemy")):
			"enemy":
				spawn_enemy(event.get("config", {}))
			"boss":
				spawn_boss(event.get("config", {}))
	var spawns_done: bool = endless_spawn_index >= endless_spawn_events.size()
	if spawns_done and enemies.is_empty() and _active_boss_count() == 0:
		endless_clear_grace -= delta
		if endless_clear_grace <= 0.0 and reward_options.is_empty() and state == GameState.PLAYING:
			offer_wave_reward(tr("REWARD_ENDLESS_TITLE"), tr("REWARD_ENDLESS_SUB") % endless_wave)

func get_extended_playfield_rect(margin: float) -> Rect2:
	return Rect2(playfield_rect.position - Vector2.ONE * margin, playfield_rect.size + Vector2.ONE * margin * 2.0)

func get_player_spawn_position() -> Vector2:
	return Vector2(playfield_rect.position.x + playfield_rect.size.x * 0.5, playfield_rect.position.y + playfield_rect.size.y - 90.0)

func point_of_collection_active() -> bool:
	return player and player.is_collectable() and player.global_position.y <= playfield_rect.position.y + 150.0 + pickup_magnet_bonus * 0.35

func get_power_tier() -> int:
	return clamp(int(floor(max(power, 0.0) / 25.0)) + 1, 1, 8)

func get_max_power() -> int:
	return int(MAX_POWER)

func get_player_damage_multiplier() -> float:
	return player_damage_multiplier

func get_player_shot_interval() -> float:
	return max(0.045, 0.09 * player_fire_rate_multiplier)

func get_player_bonus_option_count() -> int:
	return player_option_bonus

func get_player_total_option_count() -> int:
	var base_count: int = BASE_OPTION_COUNT_BY_TIER[clamp(get_power_tier() - 1, 0, BASE_OPTION_COUNT_BY_TIER.size() - 1)]
	return min(MAX_PLAYER_OPTIONS, base_count + player_option_bonus)

func get_pickup_magnet_bonus() -> float:
	return pickup_magnet_bonus

func get_reward_score_bonus_multiplier() -> float:
	return reward_score_bonus_multiplier

func angle_to_player(origin: Vector2) -> float:
	if player and player.is_targetable():
		return (player.global_position - origin).angle()
	return -PI * 0.5

func get_difficulty_config() -> Dictionary:
	return DIFFICULTIES[clamp(difficulty_index, 0, DIFFICULTIES.size() - 1)]

func get_difficulty_key() -> String:
	return str(get_difficulty_config().get("key", "normal"))

func get_difficulty_label() -> String:
	return tr(str(get_difficulty_config().get("label", "DIFF_NORMAL")))

func get_difficulty_rank() -> int:
	return int(get_difficulty_config().get("boss_density", 0))

func get_difficulty_labels() -> Array:
	var labels: Array = []
	for config in DIFFICULTIES:
		labels.append(tr(str(config.get("label", ""))))
	return labels

func get_ship_config() -> Dictionary:
	return PLAYER_SHIPS[clamp(ship_index, 0, PLAYER_SHIPS.size() - 1)]

func get_ship_label() -> String:
	return tr(str(get_ship_config().get("label", "SHIP_SPIRIT")))

func get_ship_description() -> String:
	return tr(str(get_ship_config().get("description", "")))

func _menu_mode_label() -> String:
	if menu_mode_index == 1 and endless_unlocked:
		return tr("MODE_ENDLESS")
	return tr("MODE_STORY")

func _menu_mode_description() -> String:
	if menu_mode_index == 1:
		return tr("MODE_ENDLESS_DESC")
	return tr("MODE_STORY_DESC")

func _toggle_language() -> void:
	if state != GameState.MENU:
		return
	I18n.toggle_locale()
	_apply_window_title()
	hud.show_title(best_score, get_difficulty_labels(), difficulty_index, get_ship_label(), get_ship_description(), _menu_mode_label(), _menu_mode_description(), _endless_board_title(), _endless_board_text())
	audio.play_confirm()
	_update_hud()

func _apply_window_title() -> void:
	var title := tr("WINDOW_TITLE")
	if OS.has_feature("web"):
		JavaScriptBridge.eval("document.title = %s;" % JSON.stringify(title))
	elif DisplayServer.get_name() != "headless":
		get_window().title = title

func _ship_key_for(value: String) -> String:
	return str(I18n.find_entry(PLAYER_SHIPS, value).get("key", "spirit"))

func _ship_label_for(value: String) -> String:
	return tr(str(I18n.find_entry(PLAYER_SHIPS, value).get("label", "SHIP_SPIRIT")))

func _difficulty_key_for(value: String) -> String:
	return str(I18n.find_entry(DIFFICULTIES, value).get("key", "normal"))

func _difficulty_label_for(value: String) -> String:
	return tr(str(I18n.find_entry(DIFFICULTIES, value).get("label", "DIFF_NORMAL")))

func _cycle_menu_mode() -> void:
	menu_mode_index = 1 - menu_mode_index
	hud.update_title_menu(get_difficulty_labels(), difficulty_index, get_ship_label(), get_ship_description(), _menu_mode_label(), _menu_mode_description(), _endless_board_title(), _endless_board_text())
	audio.play_confirm()
	_update_hud()

func _record_endless_result() -> void:
	if endless_wave <= 0:
		return
	endless_leaderboard.append({
		"wave": endless_wave,
		"score": score,
		"difficulty": get_difficulty_key(),
		"ship": str(get_ship_config().get("key", "spirit")),
		"time": int(round(endless_run_time))
	})
	endless_leaderboard.sort_custom(Callable(self, "_sort_endless_records"))
	while endless_leaderboard.size() > 5:
		endless_leaderboard.pop_back()

func _reward_pool() -> Array:
	return [
		"power_cache",
		"rapid_trigger",
		"overclock",
		"drone_array",
		"bomb_stock",
		"vital_core",
		"magnet_field",
		"graze_drive",
		"resonance_core",
		"phoenix_drive"
	]

func _reward_rarity(reward_id: String) -> String:
	match reward_id:
		"power_cache", "bomb_stock", "magnet_field":
			return "common"
		"resonance_core", "phoenix_drive":
			return "epic"
		_:
			return "rare"

func _reward_rarity_label(rarity: String) -> String:
	match rarity:
		"epic":
			return tr("RARITY_EPIC")
		"rare":
			return tr("RARITY_RARE")
		_:
			return tr("RARITY_COMMON")

func _reward_rarity_color(rarity: String) -> Color:
	match rarity:
		"epic":
			return Color(1.0, 0.72, 0.48)
		"rare":
			return Color(0.84, 0.72, 1.0)
	return Color(0.62, 0.96, 1.0)

func _reward_weight(reward_id: String) -> float:
	var rarity: String = _reward_rarity(reward_id)
	var stage_factor: float = float(max(0, current_stage - 1))
	var weight := 1.0
	match rarity:
		"common":
			weight = max(1.8, 7.2 - stage_factor * 1.1)
		"rare":
			weight = 3.8 + stage_factor * 1.25
		"epic":
			weight = 0.45 + stage_factor * 0.75
	if reward_id == "power_cache":
		weight += clamp((120.0 - power) / 22.0, 0.0, 3.5)
	elif reward_id == "bomb_stock":
		weight += clamp(float(4 - bombs), 0.0, 3.0)
	elif reward_id == "vital_core":
		weight += clamp(float(4 - lives), 0.0, 3.5)
	elif reward_id == "drone_array" and get_player_total_option_count() >= MAX_PLAYER_OPTIONS:
		weight *= 0.3
	elif reward_id == "magnet_field" and pickup_magnet_bonus >= 120.0:
		weight *= 0.2
	elif reward_id == "graze_drive":
		weight += clamp(float(graze) / 120.0, 0.0, 2.0)
	return max(0.15, weight)

func _pick_weighted_reward_id(pool: Array) -> String:
	var total_weight := 0.0
	for reward_id_variant in pool:
		var reward_id: String = str(reward_id_variant)
		total_weight += _reward_weight(reward_id)
	if total_weight <= 0.0:
		return str(pool[0])
	var roll := randf() * total_weight
	for reward_id_variant in pool:
		var reward_id: String = str(reward_id_variant)
		roll -= _reward_weight(reward_id)
		if roll <= 0.0:
			return reward_id
	return str(pool[pool.size() - 1])

func _sort_reward_options(a: Dictionary, b: Dictionary) -> bool:
	var rarity_order := {"common": 0, "rare": 1, "epic": 2}
	var a_rarity := int(rarity_order.get(str(a.get("rarity", "common")), 0))
	var b_rarity := int(rarity_order.get(str(b.get("rarity", "common")), 0))
	if a_rarity == b_rarity:
		return str(a.get("label", "")) < str(b.get("label", ""))
	return a_rarity > b_rarity

func _build_reward_options() -> Array:
	var pool: Array = _reward_pool().duplicate()
	var built: Array = []
	while built.size() < 3 and not pool.is_empty():
		var reward_id: String = _pick_weighted_reward_id(pool)
		built.append(_describe_reward_option(reward_id))
		pool.erase(reward_id)
	built.sort_custom(Callable(self, "_sort_reward_options"))
	return built

func _describe_reward_option(reward_id: String) -> Dictionary:
	var rarity: String = _reward_rarity(reward_id)
	var rarity_label: String = _reward_rarity_label(rarity)
	var rarity_color: Color = _reward_rarity_color(rarity)
	match reward_id:
		"power_cache":
			return {"id": reward_id, "label": tr("REWARD_POWER_CACHE"), "description": tr("REWARD_POWER_CACHE_DESC"), "detail": tr("REWARD_POWER_CACHE_DETAIL") % [int(power), int(MAX_POWER)], "rarity": rarity, "rarity_label": rarity_label, "rarity_color": rarity_color, "accent_color": Color(1.0, 0.82, 0.48)}
		"rapid_trigger":
			return {"id": reward_id, "label": tr("REWARD_RAPID_TRIGGER"), "description": tr("REWARD_RAPID_TRIGGER_DESC"), "detail": tr("REWARD_RAPID_TRIGGER_DETAIL") % [get_player_shot_interval(), max(0.045, get_player_shot_interval() * 0.92)], "rarity": rarity, "rarity_label": rarity_label, "rarity_color": rarity_color, "accent_color": Color(0.62, 0.96, 1.0)}
		"overclock":
			return {"id": reward_id, "label": tr("REWARD_OVERCLOCK"), "description": tr("REWARD_OVERCLOCK_DESC"), "detail": tr("REWARD_OVERCLOCK_DETAIL") % [player_damage_multiplier, min(2.6, player_damage_multiplier + 0.12)], "rarity": rarity, "rarity_label": rarity_label, "rarity_color": rarity_color, "accent_color": Color(1.0, 0.62, 0.68)}
		"drone_array":
			return {"id": reward_id, "label": tr("REWARD_DRONE_ARRAY"), "description": tr("REWARD_DRONE_ARRAY_DESC"), "detail": tr("REWARD_DRONE_ARRAY_DETAIL") % [get_player_total_option_count(), min(MAX_PLAYER_OPTIONS, get_player_total_option_count() + 1)], "rarity": rarity, "rarity_label": rarity_label, "rarity_color": rarity_color, "accent_color": Color(0.92, 0.72, 1.0)}
		"bomb_stock":
			return {"id": reward_id, "label": tr("REWARD_BOMB_STOCK"), "description": tr("REWARD_BOMB_STOCK_DESC"), "detail": tr("REWARD_BOMB_STOCK_DETAIL") % [bombs, min(6, bombs + 1)], "rarity": rarity, "rarity_label": rarity_label, "rarity_color": rarity_color, "accent_color": Color(1.0, 0.84, 0.6)}
		"vital_core":
			return {"id": reward_id, "label": tr("REWARD_VITAL_CORE"), "description": tr("REWARD_VITAL_CORE_DESC"), "detail": tr("REWARD_VITAL_CORE_DETAIL") % [lives, min(6, lives + 1)], "rarity": rarity, "rarity_label": rarity_label, "rarity_color": rarity_color, "accent_color": Color(0.78, 1.0, 0.82)}
		"magnet_field":
			return {"id": reward_id, "label": tr("REWARD_MAGNET_FIELD"), "description": tr("REWARD_MAGNET_FIELD_DESC"), "detail": tr("REWARD_MAGNET_FIELD_DETAIL") % [pickup_magnet_bonus, min(180.0, pickup_magnet_bonus + 36.0)], "rarity": rarity, "rarity_label": rarity_label, "rarity_color": rarity_color, "accent_color": Color(0.56, 0.96, 1.0)}
		"graze_drive":
			return {"id": reward_id, "label": tr("REWARD_GRAZE_DRIVE"), "description": tr("REWARD_GRAZE_DRIVE_DESC"), "detail": tr("REWARD_GRAZE_DRIVE_DETAIL") % [reward_score_bonus_multiplier, min(2.5, reward_score_bonus_multiplier + 0.18)], "rarity": rarity, "rarity_label": rarity_label, "rarity_color": rarity_color, "accent_color": Color(0.74, 0.94, 1.0)}
		"resonance_core":
			return {"id": reward_id, "label": tr("REWARD_RESONANCE_CORE"), "description": tr("REWARD_RESONANCE_CORE_DESC"), "detail": tr("REWARD_RESONANCE_CORE_DETAIL"), "rarity": rarity, "rarity_label": rarity_label, "rarity_color": rarity_color, "accent_color": Color(1.0, 0.74, 0.52)}
		"phoenix_drive":
			return {"id": reward_id, "label": tr("REWARD_PHOENIX_DRIVE"), "description": tr("REWARD_PHOENIX_DRIVE_DESC"), "detail": tr("REWARD_PHOENIX_DRIVE_DETAIL"), "rarity": rarity, "rarity_label": rarity_label, "rarity_color": rarity_color, "accent_color": Color(1.0, 0.64, 0.7)}
	return {"id": reward_id, "label": tr("REWARD_SUPPLY"), "description": tr("REWARD_SUPPLY_DESC"), "detail": tr("REWARD_SUPPLY_DETAIL"), "rarity": "common", "rarity_label": tr("RARITY_COMMON"), "rarity_color": Color(0.62, 0.96, 1.0), "accent_color": Color(0.76, 0.92, 1.0)}

func offer_wave_reward(title: String, subtitle: String) -> void:
	if state != GameState.PLAYING:
		return
	reward_options = _build_reward_options()
	if reward_options.is_empty():
		return
	reward_index = 0
	reward_title = title
	reward_subtitle = subtitle
	reward_refreshes = 1 + int(current_stage >= 3)
	reward_intro_timer = 0.38
	reward_input_armed = false
	bomb_timer = 0.0
	current_bomb_profile.clear()
	cancel_all_enemy_bullets(false)
	if player and is_instance_valid(player):
		player.set_invulnerable(0.9)
	state = GameState.REWARD
	_update_reward_selection_ui(true)
	hud.flash(Color(0.8, 0.9, 1.0), 0.22, 0.24)
	audio.play_confirm()
	_update_hud()

func _cycle_reward_selection(direction: int) -> void:
	if reward_options.is_empty() or reward_intro_timer > 0.0:
		return
	reward_index = posmod(reward_index + direction, reward_options.size())
	_update_reward_selection_ui(false)
	audio.play_confirm()

func _refresh_reward_selection() -> void:
	if state != GameState.REWARD or reward_refreshes <= 0 or reward_intro_timer > 0.0:
		return
	reward_refreshes -= 1
	reward_options = _build_reward_options()
	reward_index = 0
	reward_intro_timer = 0.26
	reward_input_armed = false
	_update_reward_selection_ui(true)
	hud.flash(Color(0.92, 0.82, 1.0), 0.18, 0.2)
	audio.play_confirm()

func _confirm_reward_selection() -> void:
	if reward_intro_timer > 0.0 or reward_options.is_empty() or reward_index < 0 or reward_index >= reward_options.size():
		return
	var option: Dictionary = reward_options[reward_index]
	_apply_reward_option(option)
	show_banner(tr("BANNER_REWARD_ACQUIRED"), str(option.get("label", tr("UI_UPGRADE"))))
	background.trigger_pulse(option.get("accent_color", Color(0.76, 0.92, 1.0)), 0.22, 0.32)
	hud.hide_overlay()
	reward_options.clear()
	reward_index = 0
	reward_title = ""
	reward_subtitle = ""
	reward_refreshes = 0
	reward_intro_timer = 0.0
	reward_input_armed = true
	if player and is_instance_valid(player):
		player.set_invulnerable(1.0)
	state = GameState.PLAYING
	if endless_mode_active:
		_begin_endless_wave()
	audio.play_confirm()
	_update_hud()

func _update_reward_selection_ui(restart_anim: bool) -> void:
	hud.show_reward_selection(reward_title, reward_subtitle, reward_options, reward_index, reward_refreshes, reward_intro_timer > 0.0, restart_anim)

func _apply_reward_option(option: Dictionary) -> void:
	var reward_id: String = str(option.get("id", "power_cache"))
	match reward_id:
		"power_cache":
			power = min(MAX_POWER, power + 18.0)
		"rapid_trigger":
			player_fire_rate_multiplier = max(0.55, player_fire_rate_multiplier * 0.92)
		"overclock":
			player_damage_multiplier = min(2.6, player_damage_multiplier + 0.12)
		"drone_array":
			player_option_bonus = min(MAX_PLAYER_OPTION_BONUS, player_option_bonus + 1)
		"bomb_stock":
			bombs = min(6, bombs + 1)
		"vital_core":
			if lives < 6:
				lives += 1
			else:
				add_score(50000)
		"magnet_field":
			pickup_magnet_bonus = min(180.0, pickup_magnet_bonus + 36.0)
		"graze_drive":
			reward_score_bonus_multiplier = min(2.5, reward_score_bonus_multiplier + 0.18)
		"resonance_core":
			power = min(MAX_POWER, power + 12.0)
			player_fire_rate_multiplier = max(0.5, player_fire_rate_multiplier * 0.94)
			player_damage_multiplier = min(2.8, player_damage_multiplier + 0.08)
		"phoenix_drive":
			var life_before: int = lives
			var bomb_before: int = bombs
			lives = min(6, lives + 1)
			bombs = min(6, bombs + 1)
			if lives == life_before and bombs == bomb_before:
				add_score(80000)
		_:
			power = min(MAX_POWER, power + 10.0)

func _cycle_difficulty(direction: int) -> void:
	difficulty_index = posmod(difficulty_index + direction, DIFFICULTIES.size())
	hud.update_title_menu(get_difficulty_labels(), difficulty_index, get_ship_label(), get_ship_description(), _menu_mode_label(), _menu_mode_description(), _endless_board_title(), _endless_board_text())
	audio.play_confirm()
	_update_hud()

func _cycle_ship(direction: int) -> void:
	ship_index = posmod(ship_index + direction, PLAYER_SHIPS.size())
	hud.update_title_menu(get_difficulty_labels(), difficulty_index, get_ship_label(), get_ship_description(), _menu_mode_label(), _menu_mode_description(), _endless_board_title(), _endless_board_text())
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
	if not bosses.has(new_boss):
		bosses.append(new_boss)
	boss = bosses[0] if not bosses.is_empty() else new_boss

func unregister_boss(old_boss) -> void:
	bosses.erase(old_boss)
	boss = bosses[0] if not bosses.is_empty() else null

func _active_boss_count() -> int:
	var count := 0
	for entry in bosses:
		if is_instance_valid(entry) and not bool(entry.get("dead")):
			count += 1
	return count

func _active_boss_states() -> Array:
	var states: Array = []
	for entry in bosses:
		if is_instance_valid(entry) and not bool(entry.get("dead")):
			states.append({
				"hp": entry.hp,
				"max_hp": entry.max_hp,
				"phase_name": entry.current_phase_name,
				"accent_color": entry.current_color,
			})
	return states

func spawn_player_bullet(position: Vector2, velocity: Vector2, options := {}) -> void:
	var adjusted_options: Dictionary = options.duplicate(true)
	adjusted_options["damage"] = float(adjusted_options.get("damage", 1.0)) * get_player_damage_multiplier()
	var bullet = BulletScript.new().setup(self, position, velocity, &"player", adjusted_options)
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
	var base_hp: float = float(adjusted.get("hp", 24.0))
	var radius: float = float(adjusted.get("radius", 16.0))
	var hp_balance := 1.0
	if radius <= 18.0:
		hp_balance = 0.74
	elif radius <= 22.0:
		hp_balance = 0.84
	elif radius <= 26.0:
		hp_balance = 0.92
	adjusted["hp"] = base_hp * float(difficulty.get("enemy_hp", 1.0)) * hp_balance
	adjusted["bullet_speed"] = float(adjusted.get("bullet_speed", 180.0)) * float(difficulty.get("enemy_bullet_speed", 1.0))
	adjusted["shoot_interval"] = max(0.08, float(adjusted.get("shoot_interval", 1.0)) * float(difficulty.get("enemy_fire_interval", 1.0)))
	var density: int = int(difficulty.get("enemy_density", 0))
	if adjusted.has("shot_count"):
		adjusted["shot_count"] = max(1, int(adjusted.get("shot_count", 1)) + density)
	if adjusted.has("ring_count"):
		adjusted["ring_count"] = max(6, int(adjusted.get("ring_count", 10)) + density * 2)
	return adjusted

func spawn_boss(config := {}) -> void:
	var allow_multi: bool = bool(config.get("allow_multi", false))
	if ((not allow_multi and boss) or state != GameState.PLAYING):
		return
	var boss_config: Dictionary = _scaled_boss_config(config)
	if current_boss_config.is_empty() or not allow_multi:
		current_boss_config = boss_config.duplicate(true)
	var new_boss = BossScript.new().setup(self, boss_config)
	enemy_layer.add_child(new_boss)
	background.trigger_pulse(boss_config.get("accent_color", Color(1.0, 0.84, 0.6)), 0.32, 0.65)
	hud.flash(boss_config.get("accent_color", Color(1.0, 0.84, 0.6)), 0.5, 0.4)
	hud.show_boss_spotlight(_boss_spotlight_config(), 2.6)
	shake_screen(0.8, 6.0)
	audio.play_boss_theme(5 if endless_mode_active else current_stage)

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

func _boss_spotlight_config(phase_name := "") -> Dictionary:
	var spotlight: Dictionary = current_boss_config.duplicate(true)
	if spotlight.is_empty():
		return spotlight
	if phase_name == "":
		spotlight["quote"] = str(spotlight.get("quote", ""))
		return spotlight
	spotlight["phase_name"] = phase_name
	var phases: Array = spotlight.get("phases", [])
	for phase_data in phases:
		var phase: Dictionary = phase_data
		if str(phase.get("name", "")) != phase_name:
			continue
		spotlight["accent_color"] = phase.get("color", spotlight.get("accent_color", Color(1.0, 0.82, 0.52)))
		spotlight["subtitle"] = str(phase.get("subtitle", spotlight.get("subtitle", "")))
		spotlight["mood"] = str(phase.get("mood", spotlight.get("mood", "calm")))
		spotlight["motif"] = str(phase.get("motif", spotlight.get("motif", "ribbon")))
		spotlight["portrait_side"] = str(phase.get("portrait_side", spotlight.get("portrait_side", "right")))
		spotlight["quote"] = str(phase.get("quote", spotlight.get("quote", "")))
		break
	return spotlight

func try_player_bullet_hit(bullet) -> bool:
	for boss_entry in bosses.duplicate():
		if is_instance_valid(boss_entry) and boss_entry.is_targetable():
			if bullet.global_position.distance_squared_to(boss_entry.global_position) <= pow(boss_entry.radius + bullet.radius, 2.0):
				if boss_entry.take_damage(bullet.damage):
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
	current_bomb_profile.clear()
	player.on_got_hit()
	spawn_explosion_effect(player.global_position, Color(1.0, 0.55, 0.72), 34.0, 0.6)
	spawn_spark_effect(player.global_position, Color(1.0, 0.7, 0.82), 48.0, 0.35, 18)
	hud.flash(Color(1.0, 0.45, 0.55), 0.55, 0.3)
	background.trigger_pulse(Color(1.0, 0.4, 0.55), 0.24, 0.4)
	shake_screen(0.6, 10.0)
	cancel_all_enemy_bullets(true)
	if infinite_lives_cheat:
		lives = max(lives, 99)
	else:
		lives -= 1
	bombs = 3
	var remaining_power: float = max(12.0, floor(power * 0.5))
	var lost_power: float = max(0.0, power - remaining_power)
	power = remaining_power
	_spawn_power_loss(player.global_position, lost_power)
	audio.play_player_hit()
	if lives <= 0:
		player.visible_ship = false
		finish_run(false)
	else:
		player.start_respawn()
	_update_hud()

func _spawn_power_loss(origin: Vector2, lost_power := 40.0) -> void:
	if lost_power <= 0.0:
		return
	var item_count: int = clamp(int(ceil(max(lost_power, 0.0) / 12.0)), 2, 10)
	for index in range(item_count):
		var offset: Vector2 = Vector2.RIGHT.rotated((TAU * float(index) / float(max(1, item_count))) + randf() * 0.3) * randf_range(10.0, 30.0)
		var pickup = PickupScript.new().setup(self, origin + offset, &"power", {
			"velocity": Vector2(offset.x * 3.5, -100.0 - randf_range(0.0, 30.0))
		})
		pickup_layer.add_child(pickup)

func try_use_bomb() -> void:
	if state != GameState.PLAYING or bomb_timer > 0.0 or bombs <= 0 or not player or not player.is_targetable():
		return
	current_bomb_profile = player.get_bomb_profile()
	bombs -= 1
	bomb_timer = float(current_bomb_profile.get("duration", 1.1))
	bomb_tick = 0.0
	bomb_visual_angle = 0.0
	player.set_invulnerable(float(current_bomb_profile.get("invuln", 1.8)))
	var bomb_primary: Color = current_bomb_profile.get("primary_color", Color(0.7, 0.96, 1.0))
	var bomb_secondary: Color = current_bomb_profile.get("secondary_color", Color(1.0, 0.7, 0.96))
	_spawn_bomb_start_fx(str(current_bomb_profile.get("type", "barrier")), bomb_primary, bomb_secondary, float(current_bomb_profile.get("clear_radius", 300.0)))
	cancel_all_enemy_bullets(true)
	power = min(MAX_POWER, power + float(current_bomb_profile.get("bonus_power", 0.0)))
	hud.flash(Color(0.86, 0.96, 1.0), 0.72, 0.36)
	background.trigger_pulse(Color(0.76, 0.92, 1.0), 0.34, 0.55)
	shake_screen(0.45, 7.0)
	audio.play_bomb()
	_update_hud()

func _update_bomb(delta: float) -> void:
	if bomb_timer <= 0.0:
		current_bomb_profile.clear()
		return
	bomb_timer -= delta
	bomb_tick -= delta
	bomb_visual_angle += delta * 6.0
	if player and player.is_targetable() and bomb_tick <= 0.0:
		var bomb_type := str(current_bomb_profile.get("type", "barrier"))
		var tick_time: float = float(current_bomb_profile.get("tick", 0.18))
		var clear_radius: float = float(current_bomb_profile.get("clear_radius", 280.0))
		var enemy_damage: float = float(current_bomb_profile.get("enemy_damage", 34.0))
		var boss_damage: float = float(current_bomb_profile.get("boss_damage", 46.0))
		var bomb_primary: Color = current_bomb_profile.get("primary_color", Color(0.86, 0.96, 1.0))
		var bomb_secondary: Color = current_bomb_profile.get("secondary_color", Color(1.0, 0.7, 0.96))
		bomb_tick = tick_time
		_spawn_bomb_tick_fx(bomb_type, bomb_primary, bomb_secondary, clear_radius)
		for bullet in enemy_bullets.duplicate():
			if is_instance_valid(bullet) and bullet.global_position.distance_squared_to(player.global_position) <= pow(clear_radius, 2.0):
				bullet.destroy(false, true)
		if bomb_type == "lance":
			var beam_half_width: float = float(current_bomb_profile.get("beam_half_width", 46.0))
			spawn_spark_effect(player.global_position + Vector2(0.0, -220.0), bomb_primary, 142.0, 0.24, 18)
			for enemy in enemies.duplicate():
				if is_instance_valid(enemy) and enemy.is_targetable() and enemy.global_position.y <= player.global_position.y + 24.0:
					if abs(enemy.global_position.x - player.global_position.x) <= beam_half_width:
						enemy.take_damage(enemy_damage)
			if boss and is_instance_valid(boss) and boss.is_targetable():
				if abs(boss.global_position.x - player.global_position.x) <= beam_half_width * 2.0:
					boss.take_damage(boss_damage)
		else:
			for enemy in enemies.duplicate():
				if is_instance_valid(enemy) and enemy.is_targetable():
					if enemy.global_position.distance_squared_to(player.global_position) <= pow(clear_radius + 64.0, 2.0):
						enemy.take_damage(enemy_damage)
			if boss and is_instance_valid(boss) and boss.is_targetable():
				boss.take_damage(boss_damage)
			if bomb_type == "tempest":
				var pull_radius: float = float(current_bomb_profile.get("pickup_pull_radius", clear_radius))
				for pickup in pickups.duplicate():
					if is_instance_valid(pickup) and pickup.global_position.distance_squared_to(player.global_position) <= pow(pull_radius, 2.0):
						pickup.homing = true

func _spawn_bomb_start_fx(bomb_type: String, primary: Color, secondary: Color, clear_radius: float) -> void:
	match bomb_type:
		"tempest":
			spawn_ring_effect(player.global_position, primary, 14.0, clear_radius + 56.0, 0.95, 4.0)
			for orbit_index in range(5):
				var orbit_angle: float = TAU * float(orbit_index) / 5.0
				var orbit_position = player.global_position + Vector2.RIGHT.rotated(orbit_angle) * 42.0
				spawn_spark_effect(orbit_position, secondary, 74.0, 0.46, 16)
		"lance":
			spawn_ring_effect(player.global_position, primary, 18.0, clear_radius * 0.84, 0.72, 4.2)
			for beam_index in range(5):
				var beam_position = player.global_position + Vector2(0.0, -86.0 - float(beam_index) * 118.0)
				spawn_spark_effect(beam_position, primary.lightened(0.12), 126.0, 0.42, 20)
			spawn_explosion_effect(player.global_position + Vector2(0.0, -clear_radius * 0.55), secondary, 42.0, 0.42)
		_:
			spawn_ring_effect(player.global_position, primary, 18.0, clear_radius + 20.0, 1.0, 5.0)
			spawn_ring_effect(player.global_position, secondary, 10.0, clear_radius * 0.72, 0.7, 3.0)
			spawn_spark_effect(player.global_position, Color(1.0, 0.92, 0.68), 92.0, 0.65, 26)

func _spawn_bomb_tick_fx(bomb_type: String, primary: Color, secondary: Color, clear_radius: float) -> void:
	match bomb_type:
		"tempest":
			spawn_ring_effect(player.global_position, primary, 10.0, min(168.0, clear_radius * 0.42), 0.28, 2.0)
			for orbit_index in range(3):
				var swirl_angle: float = bomb_visual_angle + TAU * float(orbit_index) / 3.0
				var emitter = player.global_position + Vector2.RIGHT.rotated(swirl_angle) * 64.0
				spawn_spark_effect(emitter, secondary, 56.0, 0.22, 12)
		"lance":
			for beam_index in range(4):
				var beam_position = player.global_position + Vector2(0.0, -70.0 - float(beam_index) * 126.0)
				spawn_spark_effect(beam_position, primary, 102.0, 0.2, 14)
			spawn_ring_effect(player.global_position, secondary, 8.0, 62.0, 0.2, 2.0)
		_:
			spawn_ring_effect(player.global_position, primary, 12.0, min(160.0, clear_radius * 0.55), 0.35, 2.0)
			for orbit_index in range(2):
				var orbit_angle: float = bomb_visual_angle + PI * float(orbit_index)
				var orbit_position = player.global_position + Vector2.RIGHT.rotated(orbit_angle) * 34.0
				spawn_spark_effect(orbit_position, secondary, 42.0, 0.22, 10)

func on_player_graze(position: Vector2) -> void:
	graze += 1
	add_score(int((80.0 + power * 4.0) * get_reward_score_bonus_multiplier()))
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
		if power >= MAX_POWER:
			add_score(2200)
		else:
			power = min(MAX_POWER, power + 10.0)
			add_score(360)
		audio.play_pickup(true)
	else:
		var bonus_ratio := 1.0
		if player:
			bonus_ratio = clamp(1.0 - inverse_lerp(playfield_rect.position.y + playfield_rect.size.y, playfield_rect.position.y, player.global_position.y), 0.25, 1.0)
		add_score(int((900.0 + 1800.0 * bonus_ratio) * get_reward_score_bonus_multiplier()))
		audio.play_pickup(false)
	spawn_ring_effect(pickup.global_position, Color(1.0, 1.0, 1.0), 4.0, 22.0, 0.18, 2.0)
	_update_hud()

func cancel_all_enemy_bullets(with_score := false, show_effect := false) -> void:
	for bullet in enemy_bullets.duplicate():
		if is_instance_valid(bullet):
			if with_score:
				add_score(8)
			bullet.destroy(show_effect and not should_reduce_minor_fx(), true)

func should_reduce_minor_fx() -> bool:
	if effect_layer == null:
		return false
	return enemy_bullets.size() + player_bullets.size() >= 220 or effect_layer.get_child_count() >= 70

func spawn_ring_effect(position: Vector2, color: Color, from_radius: float, to_radius: float, duration := 0.45, width := 3.0) -> void:
	color = BulletScript.ink_palette(color)
	if effect_layer != null and effect_layer.get_child_count() >= 150:
		return
	if should_reduce_minor_fx() and to_radius <= 26.0 and duration <= 0.22:
		return
	var effect = EffectScript.new().configure_ring(color, from_radius, to_radius, duration, width)
	effect.global_position = position
	effect_layer.add_child(effect)

func spawn_explosion_effect(position: Vector2, color: Color, size := 22.0, duration := 0.55) -> void:
	color = BulletScript.ink_palette(color)
	if effect_layer != null and effect_layer.get_child_count() >= 150:
		return
	if should_reduce_minor_fx():
		size *= 0.82
		duration *= 0.9
	var effect = EffectScript.new().configure_explosion(color, size, duration)
	effect.global_position = position
	effect_layer.add_child(effect)

func spawn_spark_effect(position: Vector2, color: Color, length := 28.0, duration := 0.35, fragments := 12) -> void:
	color = BulletScript.ink_palette(color)
	if effect_layer != null and effect_layer.get_child_count() >= 150:
		return
	if should_reduce_minor_fx():
		fragments = max(5, int(round(float(fragments) * 0.55)))
		length *= 0.86
		duration *= 0.88
	var effect = EffectScript.new().configure_sparks(color, length, duration, fragments)
	effect.global_position = position
	effect_layer.add_child(effect)

func shake_screen(duration: float, strength: float) -> void:
	shake_time = max(shake_time, duration)
	shake_strength = max(shake_strength, strength)

func _update_shake(delta: float) -> void:
	if shake_time > 0.0:
		shake_time = max(0.0, shake_time - delta)
		world_root.position = -playfield_rect.position + Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
		shake_strength = lerpf(shake_strength, 0.0, delta * 3.4)
	else:
		world_root.position = -playfield_rect.position
		shake_strength = 0.0

func add_score(amount: int) -> void:
	var scaled_amount: int = int(round(float(amount) * float(get_difficulty_config().get("score_multiplier", 1.0)) * endless_score_multiplier))
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
	var is_break: bool = phase_name == BossScript.PHASE_BREAK
	hud.set_boss_state(true, current_hp, max_hp_value, tr("UI_PHASE_BREAK") if is_break else phase_name)
	if not is_break:
		var spotlight_config: Dictionary = _boss_spotlight_config(phase_name)
		var pulse_color: Color = spotlight_config.get("accent_color", Color(1.0, 0.82, 0.52))
		hud.flash(pulse_color, 0.32, 0.26)
		background.trigger_pulse(pulse_color, 0.18, 0.26)
		hud.show_boss_spotlight(spotlight_config, 2.15 if _is_last_boss_phase(phase_name) else 1.75)
		audio.play_phase_break()

func _is_last_boss_phase(phase_name: String) -> bool:
	var phases: Array = current_boss_config.get("phases", [])
	return not phases.is_empty() and str(phases[phases.size() - 1].get("name", "")) == phase_name

func on_boss_phase_cleared(phase_name: String) -> void:
	show_banner(tr("BANNER_SPELL_BREAK"), phase_name)
	hud.flash(Color(1.0, 0.88, 0.52), 0.5, 0.35)
	background.trigger_pulse(Color(1.0, 0.84, 0.56), 0.24, 0.42)
	shake_screen(0.5, 9.0)
	audio.play_phase_break()

func on_boss_defeated(defeated_boss = null) -> void:
	add_score(220000 + current_stage * 40000)
	background.trigger_pulse(Color(1.0, 0.94, 0.72), 0.4, 0.7)
	hud.flash(Color(1.0, 0.95, 0.8), 0.8, 0.55)
	if endless_mode_active:
		var remaining_bosses := 0
		for entry in bosses:
			if not is_instance_valid(entry):
				continue
			if entry == defeated_boss:
				continue
			if bool(entry.get("dead")):
				continue
			remaining_bosses += 1
		if remaining_bosses <= 0:
			show_banner(tr("BANNER_ALL_BOSSES_DOWN"), tr("BANNER_ALL_BOSSES_DOWN_SUB"))
		return
	if current_stage < FINAL_STAGE:
		_start_stage_transition()
	else:
		show_banner(tr("BANNER_ALL_CLEAR"), tr("BANNER_ALL_CLEAR_SUB"))
		finish_run(true)

func _start_stage_transition() -> void:
	state = GameState.TRANSITION
	stage_director = null
	pending_stage = current_stage + 1
	stage_transition_timer = 3.2
	cancel_all_enemy_bullets(false)
	_clear_combat_layers(true)
	bombs = min(bombs + 1, 6)
	if player and is_instance_valid(player):
		player.prepare_for_stage(3.5)
	var next_director = StageDirectorScript.new().setup(pending_stage, get_difficulty_key())
	var stage_info: Dictionary = next_director.get_stage_info()
	hud.show_stage_transition(pending_stage, stage_info.get("title", "Next Stage"), stage_info.get("subtitle", ""))
	show_banner(tr("BANNER_STAGE_END") % current_stage, tr("BANNER_STAGE_END_SUB"))
	background.trigger_pulse(stage_info.get("accent_color", Color(1.0, 1.0, 1.0)), 0.28, 0.6)
	audio.play_stage_transition()

func _update_hud() -> void:
	hud.set_status({
		"score": score,
		"best_score": best_score,
		"lives": lives,
		"bombs": bombs,
		"power": int(power),
		"power_max": int(MAX_POWER),
		"graze": graze,
		"stage_text": (tr("HUD_ENDLESS_STAGE") % [endless_wave, endless_score_multiplier]) if endless_mode_active else (tr("HUD_STAGE_PROGRESS") % [current_stage, FINAL_STAGE]),
		"difficulty_text": get_difficulty_label()
	})
	if state == GameState.MENU:
		hud.update_title_menu(get_difficulty_labels(), difficulty_index, get_ship_label(), get_ship_description(), _menu_mode_label(), _menu_mode_description(), _endless_board_title(), _endless_board_text())
	var boss_states: Array = _active_boss_states()
	if not boss_states.is_empty():
		hud.set_boss_states(boss_states)
	elif state != GameState.MENU:
		hud.set_boss_states([])

func _load_best_score() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		best_score = int(config.get_value("save", "best_score", 0))
		var unlocked_value = config.get_value("save", "endless_unlocked", true)
		endless_unlocked = bool(unlocked_value)
		var serialized_board = config.get_value("save", "endless_leaderboard_json", "")
		if serialized_board is String and str(serialized_board) != "":
			endless_leaderboard = _deserialize_endless_leaderboard(str(serialized_board))
		else:
			var legacy_board = config.get_value("save", "endless_leaderboard", [])
			endless_leaderboard = _normalize_endless_leaderboard(legacy_board)
		if int(config.get_value("save", "save_version", 1)) < SAVE_VERSION:
			_save_best_score()
	endless_unlocked = true

func _save_best_score() -> void:
	var config := ConfigFile.new()
	config.set_value("save", "save_version", SAVE_VERSION)
	config.set_value("save", "best_score", best_score)
	config.set_value("save", "endless_unlocked", endless_unlocked)
	config.set_value("save", "endless_leaderboard_json", _serialize_endless_leaderboard())
	config.save(SAVE_PATH)

func _serialize_endless_leaderboard() -> String:
	return JSON.stringify(_normalize_endless_leaderboard(endless_leaderboard))

func _deserialize_endless_leaderboard(serialized: String) -> Array:
	var parsed = JSON.parse_string(serialized)
	if parsed == null:
		return []
	return _normalize_endless_leaderboard(parsed)

func _normalize_endless_leaderboard(raw_value) -> Array:
	var normalized: Array = []
	if raw_value is Array:
		for entry in raw_value:
			if not (entry is Dictionary):
				continue
			normalized.append({
				"wave": max(0, int(entry.get("wave", 0))),
				"score": max(0, int(entry.get("score", 0))),
				"difficulty": _difficulty_key_for(str(entry.get("difficulty", "normal"))),
				"ship": _ship_key_for(str(entry.get("ship", "spirit"))),
				"time": max(0, int(entry.get("time", 0))),
			})
	normalized.sort_custom(Callable(self, "_sort_endless_records"))
	while normalized.size() > 5:
		normalized.pop_back()
	return normalized

func on_player_shot(focus_ratio: float) -> void:
	audio.play_player_shot(focus_ratio)

func on_enemy_fired(pattern: StringName) -> void:
	audio.play_enemy_fire(pattern)
