extends Node

## Plays DanMu's music cues and sound effects. The assets are rendered offline by
## tools/audio/ (see docs/audio-direction.md); this node only routes events to them.

const MUSIC := {
	"title": preload("res://audio/music/title.mp3"),
	"stage_a": preload("res://audio/music/stage_a.mp3"),
	"stage_b": preload("res://audio/music/stage_b.mp3"),
	"boss": preload("res://audio/music/boss.mp3"),
	"boss_final": preload("res://audio/music/boss_final.mp3"),
	"results": preload("res://audio/music/results.mp3"),
}
const SFX := {
	"shot": preload("res://audio/sfx/shot.wav"),
	"shot_focus": preload("res://audio/sfx/shot_focus.wav"),
	"enemy_fire": preload("res://audio/sfx/enemy_fire.wav"),
	"enemy_ring": preload("res://audio/sfx/enemy_ring.wav"),
	"enemy_spiral": preload("res://audio/sfx/enemy_spiral.wav"),
	"graze": preload("res://audio/sfx/graze.wav"),
	"enemy_hit": preload("res://audio/sfx/enemy_hit.wav"),
	"enemy_down": preload("res://audio/sfx/enemy_down.wav"),
	"pickup": preload("res://audio/sfx/pickup.wav"),
	"pickup_power": preload("res://audio/sfx/pickup_power.wav"),
	"extend": preload("res://audio/sfx/extend.wav"),
	"ui_move": preload("res://audio/sfx/ui_move.wav"),
	"confirm": preload("res://audio/sfx/confirm.wav"),
	"pause": preload("res://audio/sfx/pause.wav"),
	"cancel": preload("res://audio/sfx/cancel.wav"),
	"bomb": preload("res://audio/sfx/bomb.wav"),
	"spell_declare": preload("res://audio/sfx/spell_declare.wav"),
	"phase_break": preload("res://audio/sfx/phase_break.wav"),
	"player_hit": preload("res://audio/sfx/player_hit.wav"),
	"stage_clear": preload("res://audio/sfx/stage_clear.wav"),
	"game_clear": preload("res://audio/sfx/game_clear.wav"),
	"game_over": preload("res://audio/sfx/game_over.wav"),
}
## Stages 1-3 share the shrine-road theme; 4, 5 and endless use the lantern procession.
const STAGE_CUES := {1: "stage_a", 2: "stage_a", 3: "stage_a", 4: "stage_b", 5: "stage_b"}
const BGM_VOLUME_DB := -2.0
const JINGLE_VOLUME_DB := -4.0
const SFX_VOICES := 10

var bgm_player: AudioStreamPlayer
var jingle_player: AudioStreamPlayer
var sfx_players: Array = []
var sfx_index := 0
var clock := 0.0
var cooldowns := {}
var current_bgm_key := ""
## Cue to start once the current jingle finishes (results music after clear/game over).
var pending_bgm_key := ""
## How often each cue has fired; read by headless tests to confirm events reach audio.
var event_counts := {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_players()

func _process(delta: float) -> void:
	clock += delta
	if pending_bgm_key != "" and not jingle_player.playing:
		var key := pending_bgm_key
		pending_bgm_key = ""
		_play_bgm(key)

func _exit_tree() -> void:
	shutdown()

## Stops and detaches every stream so the AudioServer can release its playback
## objects before the engine shuts down (otherwise they leak at exit).
func shutdown() -> void:
	current_bgm_key = ""
	pending_bgm_key = ""
	for player in [bgm_player, jingle_player] + sfx_players:
		if player:
			player.stop()
			player.stream = null

func play_title_theme() -> void:
	_play_bgm("title")

func play_stage_theme(stage_number: int) -> void:
	_play_bgm(STAGE_CUES.get(stage_number, "stage_b"))

func play_boss_theme(stage_number: int) -> void:
	_play_bgm("boss_final" if stage_number >= 5 else "boss")

## Clear or game-over jingle, then the results theme once the jingle ends.
func play_results(victory: bool) -> void:
	stop_bgm()
	_play_jingle("game_clear" if victory else "game_over")
	pending_bgm_key = "results"

func stop_bgm() -> void:
	current_bgm_key = ""
	pending_bgm_key = ""
	if bgm_player:
		bgm_player.stop()

func play_ui_move() -> void:
	_play_sfx("ui_move", 0.03, -12.0)

func play_confirm() -> void:
	_play_sfx("confirm", 0.05, -8.0)

func play_cancel() -> void:
	_play_sfx("cancel", 0.05, -9.0)

func play_pause() -> void:
	_play_sfx("pause", 0.05, -8.0)

## Fires many times per second, so it sits far below the music.
func play_player_shot(focus_ratio: float) -> void:
	if focus_ratio > 0.55:
		_play_sfx("shot_focus", 0.06, -21.0)
	else:
		_play_sfx("shot", 0.06, -22.0)

func play_enemy_fire(pattern: StringName) -> void:
	match pattern:
		&"spiral", &"burst_ring":
			_play_sfx("enemy_spiral", 0.12, -19.0)
		&"ring", &"wall":
			_play_sfx("enemy_ring", 0.18, -18.0)
		_:
			_play_sfx("enemy_fire", 0.1, -20.0)

func play_graze() -> void:
	_play_sfx("graze", 0.035, -15.0)

func play_enemy_hit() -> void:
	_play_sfx("enemy_hit", 0.08, -20.0)

func play_pickup(power_item: bool) -> void:
	_play_sfx("pickup_power" if power_item else "pickup", 0.035, -13.0 if power_item else -14.0)

func play_extend() -> void:
	_play_sfx("extend", 0.3, -5.0)

func play_enemy_down() -> void:
	_play_sfx("enemy_down", 0.03, -10.0)

func play_player_hit() -> void:
	_play_sfx("player_hit", 0.1, -3.0)

func play_bomb() -> void:
	_play_sfx("bomb", 0.12, -3.0)

func play_spell_declare() -> void:
	_play_sfx("spell_declare", 0.3, -4.0)

func play_phase_break() -> void:
	_play_sfx("phase_break", 0.18, -4.0)

func play_stage_transition() -> void:
	_play_jingle("stage_clear")

func play_stage_clear() -> void:
	_play_jingle("stage_clear")

func play_game_clear() -> void:
	_play_jingle("game_clear")

func _build_players() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.volume_db = BGM_VOLUME_DB
	add_child(bgm_player)
	jingle_player = AudioStreamPlayer.new()
	jingle_player.volume_db = JINGLE_VOLUME_DB
	add_child(jingle_player)
	for _index in range(SFX_VOICES):
		var player := AudioStreamPlayer.new()
		add_child(player)
		sfx_players.append(player)

func _count(key: String) -> void:
	event_counts[key] = int(event_counts.get(key, 0)) + 1

func _play_bgm(key: String) -> void:
	pending_bgm_key = ""
	if current_bgm_key == key and bgm_player.playing:
		return
	current_bgm_key = key
	_count("bgm:" + key)
	bgm_player.stream = MUSIC[key]
	bgm_player.play()

func _play_jingle(key: String) -> void:
	_count(key)
	jingle_player.stream = SFX[key]
	jingle_player.play()

func _play_sfx(key: String, cooldown: float, volume_db: float) -> void:
	var next_allowed: float = cooldowns.get(key, -100.0)
	if clock < next_allowed:
		return
	cooldowns[key] = clock + cooldown
	_count(key)
	var player: AudioStreamPlayer = sfx_players[sfx_index]
	sfx_index = (sfx_index + 1) % sfx_players.size()
	player.stream = SFX[key]
	player.volume_db = volume_db
	player.play()
