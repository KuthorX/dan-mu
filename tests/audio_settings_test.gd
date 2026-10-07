extends SceneTree

## Headless check for the volume settings: drives the real title and pause sheets
## with key presses, then checks the bus volumes and user://settings.cfg.
## Run: godot --headless --audio-driver Dummy -s res://tests/audio_settings_test.gd
## Any existing settings file is restored afterwards.

const AudioSettings = preload("res://scripts/audio_settings.gd")
const MainScene = preload("res://scenes/main.tscn")

var failures := 0
var backup := ""
var had_backup := false

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	if FileAccess.file_exists(AudioSettings.SETTINGS_PATH):
		had_backup = true
		backup = FileAccess.get_file_as_string(AudioSettings.SETTINGS_PATH)
		DirAccess.remove_absolute(AudioSettings.SETTINGS_PATH)
	AudioSettings.music_level = AudioSettings.DEFAULT_LEVEL
	AudioSettings.sfx_level = AudioSettings.DEFAULT_LEVEL
	AudioSettings.muted = false
	await _test_title_and_pause()
	await _test_reload()
	_restore()
	print("audio_settings_test: %s" % ("PASS" if failures == 0 else "FAIL (%d)" % failures))
	quit(1 if failures > 0 else 0)

func _test_title_and_pause() -> void:
	var game = MainScene.instantiate()
	root.add_child(game)
	await _frames(3)
	_check(AudioServer.get_bus_index(&"Music") > 0 and AudioServer.get_bus_index(&"SFX") > 0, "Music and SFX buses exist")
	_check(game.audio.bgm_player.bus == &"Music", "music player on Music bus")
	_check(game.audio.sfx_players[0].bus == &"SFX", "sfx players on SFX bus")
	_check(is_equal_approx(_bus_db(&"Music"), 0.0), "default music level is 0 dB")
	# title: V opens the sheet, A lowers music 3 steps, S + A lowers SFX 10 steps to off
	await _press(KEY_V)
	_check(game.sound_sheet_open and game.hud.is_sound_sheet_visible(), "V opens the sound sheet")
	for _i in range(3):
		await _press(KEY_A)
	await _press(KEY_S)
	for _i in range(12):
		await _press(KEY_A)
	_check(AudioSettings.music_level == 7, "music level 7 (got %d)" % AudioSettings.music_level)
	_check(is_equal_approx(_bus_db(&"Music"), AudioSettings.level_to_db(7)), "music bus at level 7 dB")
	_check(AudioSettings.sfx_level == 0 and AudioServer.is_bus_mute(AudioServer.get_bus_index(&"SFX")), "SFX off mutes the SFX bus")
	await _press(KEY_ESCAPE)
	_check(not game.sound_sheet_open and game.state == game.GameState.MENU, "Esc closes the sheet and stays on the title")
	# pause: D raises music, S + D brings SFX back to 2
	game.start_new_game()
	game.state = game.GameState.PLAYING
	await _frames(2)
	game.pause_game()
	_check(game.hud.is_sound_sheet_visible(), "pause shows the volume rows")
	await _press(KEY_D)
	await _press(KEY_S)
	await _press(KEY_D)
	await _press(KEY_D)
	_check(AudioSettings.music_level == 8 and AudioSettings.sfx_level == 2, "pause adjusts levels (got %d / %d)" % [AudioSettings.music_level, AudioSettings.sfx_level])
	_check(game.state == game.GameState.PAUSED, "volume keys keep the game paused")
	_check(is_equal_approx(_bus_db(&"SFX"), AudioSettings.level_to_db(2)) and not AudioServer.is_bus_mute(AudioServer.get_bus_index(&"SFX")), "SFX bus back on at level 2")
	await _press(KEY_M)
	_check(AudioSettings.muted and AudioServer.is_bus_mute(0), "M mutes the Master bus")
	game.audio.shutdown()
	game.queue_free()
	await _frames(3)
	await create_timer(0.1).timeout

func _test_reload() -> void:
	var config := ConfigFile.new()
	_check(config.load(AudioSettings.SETTINGS_PATH) == OK, "settings.cfg written")
	_check(int(config.get_value("settings", "music_volume", -1)) == 8, "music volume persisted")
	_check(int(config.get_value("settings", "sfx_volume", -1)) == 2, "sfx volume persisted")
	_check(bool(config.get_value("settings", "muted", false)), "mute persisted")
	# simulate a fresh launch: reset the buses and the cached levels, then load
	AudioSettings.music_level = 10
	AudioSettings.sfx_level = 10
	AudioSettings.muted = false
	AudioSettings.apply()
	AudioSettings.load_and_apply()
	_check(AudioSettings.music_level == 8 and AudioSettings.sfx_level == 2 and AudioSettings.muted, "levels reloaded from disk")
	_check(is_equal_approx(_bus_db(&"Music"), AudioSettings.level_to_db(8)), "reloaded music bus volume")
	_check(AudioServer.is_bus_mute(0), "reloaded master mute")
	# language toggling must keep the audio keys in the shared file
	var game = MainScene.instantiate()
	root.add_child(game)
	await _frames(3)
	await _press(KEY_M)
	await _press(KEY_L)
	await _press(KEY_L)
	config = ConfigFile.new()
	config.load(AudioSettings.SETTINGS_PATH)
	_check(not bool(config.get_value("settings", "muted", true)) and int(config.get_value("settings", "music_volume", -1)) == 8, "unmute saved and language save keeps volumes")
	_check(not AudioServer.is_bus_mute(0), "M unmutes the Master bus")
	game.audio.shutdown()
	game.queue_free()
	await _frames(3)
	await create_timer(0.1).timeout

func _restore() -> void:
	DirAccess.remove_absolute(AudioSettings.SETTINGS_PATH)
	if had_backup:
		var file := FileAccess.open(AudioSettings.SETTINGS_PATH, FileAccess.WRITE)
		file.store_string(backup)
		file.close()

func _bus_db(bus: StringName) -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus))

func _press(keycode: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = keycode
		event.pressed = pressed
		Input.parse_input_event(event)
		await _frames(1)

func _frames(count: int) -> void:
	for _i in range(count):
		await process_frame

func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   ", label)
	else:
		failures += 1
		printerr("  FAIL ", label)
