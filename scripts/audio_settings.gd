extends RefCounted

## Music / SFX volume and the global mute, stored next to the language in
## user://settings.cfg and applied to the buses in res://default_bus_layout.tres.

const SETTINGS_PATH := "user://settings.cfg"
const SECTION := "settings"
const KEY_MUSIC := "music_volume"
const KEY_SFX := "sfx_volume"
const KEY_MUTED := "muted"
const BUS_MASTER := &"Master"
const BUS_MUSIC := &"Music"
const BUS_SFX := &"SFX"
const MAX_LEVEL := 10
const DEFAULT_LEVEL := 10

static var music_level := DEFAULT_LEVEL
static var sfx_level := DEFAULT_LEVEL
static var muted := false

static func load_and_apply() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		music_level = _clamp_level(config.get_value(SECTION, KEY_MUSIC, DEFAULT_LEVEL))
		sfx_level = _clamp_level(config.get_value(SECTION, KEY_SFX, DEFAULT_LEVEL))
		muted = bool(config.get_value(SECTION, KEY_MUTED, false))
	apply()

static func level(bus: StringName) -> int:
	return music_level if bus == BUS_MUSIC else sfx_level

## Steps one bus by `delta` levels; returns true when the level actually changed.
static func step(bus: StringName, delta: int) -> bool:
	var next := _clamp_level(level(bus) + delta)
	if next == level(bus):
		return false
	if bus == BUS_MUSIC:
		music_level = next
	else:
		sfx_level = next
	apply()
	save()
	return true

static func toggle_mute() -> void:
	muted = not muted
	apply()
	save()

static func apply() -> void:
	_set_bus(BUS_MUSIC, music_level)
	_set_bus(BUS_SFX, sfx_level)
	var master := AudioServer.get_bus_index(BUS_MASTER)
	if master >= 0:
		AudioServer.set_bus_mute(master, muted)

## Levels follow a squared curve, so each step sounds roughly even (5 is about -12 dB).
static func level_to_db(value: int) -> float:
	var ratio := float(value) / float(MAX_LEVEL)
	return linear_to_db(ratio * ratio) if value > 0 else -80.0

static func save() -> void:
	var config := ConfigFile.new()
	config.load(SETTINGS_PATH)
	config.set_value(SECTION, KEY_MUSIC, music_level)
	config.set_value(SECTION, KEY_SFX, sfx_level)
	config.set_value(SECTION, KEY_MUTED, muted)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Failed to save audio settings (error %d)." % error)

static func _set_bus(bus: StringName, value: int) -> void:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		push_warning("Audio bus %s is missing." % bus)
		return
	AudioServer.set_bus_volume_db(index, level_to_db(value))
	AudioServer.set_bus_mute(index, value <= 0)

static func _clamp_level(value) -> int:
	return clampi(int(value), 0, MAX_LEVEL)
