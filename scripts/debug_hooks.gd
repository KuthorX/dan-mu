extends Node

## Capture hooks for headless screenshots and exit checks. Inactive in normal play:
## they only run when a `shot` value is passed, either as a desktop user argument
## (`godot -- --shot=boss`) or as a web URL query (`index.html?shot=boss`).
##
## Shots: menu, stage, boss, spotlight, dialogue, reward, pause, gameover, victory, close.
## Optional: `stage=N` picks the stage (1-5); `close` sends a window close request
## after one second so the clean-exit path can be checked for leaked objects.

const PARAM_SHOT := "shot"
const PARAM_STAGE := "stage"
const SETTLE_DELAY := 0.4
const STAGE_SKIP_TIME := 20.0
const BOSS_FIGHT_TIME := 5.5

var game = null
var params: Dictionary = {}

static func read_params() -> Dictionary:
	var result: Dictionary = {}
	var raw: Array = []
	if OS.has_feature("web"):
		var query = JavaScriptBridge.eval("window.location.search.substring(1)", true)
		if query is String and query != "":
			raw.append_array(str(query).split("&"))
	for arg in OS.get_cmdline_user_args():
		raw.append(str(arg).trim_prefix("--"))
	for pair_variant in raw:
		var pair: PackedStringArray = str(pair_variant).split("=", true, 1)
		if pair.size() == 2 and pair[0] != "":
			result[pair[0]] = pair[1]
	return result

func setup(game_ref, hook_params: Dictionary):
	game = game_ref
	params = hook_params
	return self

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	await get_tree().create_timer(SETTLE_DELAY).timeout
	var stage_number: int = clamp(int(params.get(PARAM_STAGE, "1")), 1, 5)
	match str(params.get(PARAM_SHOT, "")):
		"stage":
			_start_stage(stage_number)
			_skip_stage_to(STAGE_SKIP_TIME)
			await _settle(4.0)
		"boss", "spotlight":
			_start_stage(stage_number)
			_start_boss_fight()
			if params.get(PARAM_SHOT) == "boss":
				await _settle(BOSS_FIGHT_TIME)
		"dialogue":
			_start_stage(stage_number)
			_skip_stage_to_dialogue()
		"reward":
			_start_stage(stage_number)
			game.offer_wave_reward(tr("REWARD_WAVE"), tr("S1_REWARD_1"))
		"pause":
			_start_stage(stage_number)
			_skip_stage_to(STAGE_SKIP_TIME)
			await _settle(3.0)
			game.pause_game()
		"gameover", "victory":
			_start_stage(stage_number)
			_skip_stage_to(STAGE_SKIP_TIME)
			await _settle(2.0)
			game.score = 18452300
			if params.get(PARAM_SHOT) == "gameover":
				game.infinite_lives_cheat = false
				game.lives = 0
			game.finish_run(params.get(PARAM_SHOT) == "victory")
			Input.action_release(&"shoot")
			Input.action_release(&"focus")
		"close":
			await get_tree().create_timer(1.0).timeout
			get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)

func _start_stage(stage_number: int) -> void:
	game.infinite_lives_cheat = true
	game.start_new_game()
	if stage_number > 1:
		game._begin_stage(stage_number)
	# the cheat only keeps the run alive; the strip shows an ordinary stock, not × 99
	game.lives = 3
	game.power = 120.0
	Input.action_press(&"shoot")
	Input.action_press(&"focus")

func _skip_stage_to(time: float) -> void:
	var director = game.stage_director
	var kept: Array = []
	for event in director.events:
		if float(event.get("time", 0.0)) >= time and str(event.get("type", "")) != "reward":
			kept.append(event)
	director.events = kept
	director.index = 0
	director.elapsed = time

func _skip_stage_to_dialogue() -> void:
	var director = game.stage_director
	for event in director.events:
		if str(event.get("type", "")) == "dialogue":
			game.start_dialogue(event.get("scene", {}))
			game.hud.reveal_dialogue_line()
			break
	director.events = []

func _start_boss_fight() -> void:
	var director = game.stage_director
	var boss_config: Dictionary = director.boss_config
	director.events = []
	game.spawn_boss(boss_config)

## Lets the fight run with the player unhittable (without the invulnerability blink)
## and drifting, so bullets stay on screen.
func _settle(duration: float) -> void:
	var elapsed := 0.0
	while elapsed < duration:
		await get_tree().process_frame
		var delta: float = get_process_delta_time()
		elapsed += delta
		var player = game.player
		if player and is_instance_valid(player):
			player.active = false
			var rect: Rect2 = game.playfield_rect
			player.global_position = Vector2(rect.get_center().x + sin(elapsed * 0.9) * 90.0, rect.end.y - 150.0)
		if game.state == game.GameState.REWARD:
			game._confirm_reward_selection()
