extends Control

## Music and SFX levels written on the paper sheet like the ofuda's power tally:
## one brush tick per step, inked up to the level. The selected line gets the same
## vermilion brush tick as the title menu.

const UiTheme = preload("res://scripts/ui_theme.gd")

const ROW_KEYS := ["UI_SOUND_MUSIC", "UI_SOUND_SFX"]
const ROW_H := 46.0
const LABEL_W := 120.0
const TICKS_X := 136.0
const TICK_STEP := 24.0
const VALUE_W := 52.0
const NOTE_GAP := 12.0

var levels: Array = [0, 0]
var max_level := 10
var selected := 0
var muted := false
var name_labels: Array = []
var value_labels: Array = []
var note: Label

func setup(width: float) -> Control:
	size = Vector2(width, ROW_H * ROW_KEYS.size() + NOTE_GAP + 24.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for index in range(ROW_KEYS.size()):
		var y: float = ROW_H * float(index)
		var row_name := UiTheme.make_label(ROW_KEYS[index], Vector2(18.0, y), UiTheme.SerifFont, 20, UiTheme.INK, LABEL_W)
		add_child(row_name)
		name_labels.append(row_name)
		var value := UiTheme.make_label("", Vector2(width - VALUE_W, y + 2.0), UiTheme.SerifFont, 18, UiTheme.INK, VALUE_W, HORIZONTAL_ALIGNMENT_RIGHT)
		value.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		add_child(value)
		value_labels.append(value)
	note = UiTheme.make_label("", Vector2(0.0, ROW_H * ROW_KEYS.size() + NOTE_GAP), UiTheme.SerifFont, 14, UiTheme.INK_SOFT, width, HORIZONTAL_ALIGNMENT_CENTER)
	note.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	add_child(note)
	return self

func show_levels(music_level: int, sfx_level: int, top_level: int, selected_row: int, is_muted: bool) -> void:
	levels = [music_level, sfx_level]
	max_level = max(1, top_level)
	selected = selected_row
	muted = is_muted
	for index in range(ROW_KEYS.size()):
		var active: bool = index == selected
		name_labels[index].add_theme_color_override("font_color", UiTheme.INK if active else UiTheme.INK_SOFT)
		value_labels[index].text = tr("UI_SOUND_OFF") if int(levels[index]) <= 0 else str(levels[index])
		value_labels[index].add_theme_color_override("font_color", UiTheme.INK if active else UiTheme.INK_SOFT)
	note.text = tr("UI_SOUND_MUTED") if muted else tr("UI_SOUND_MUTE_HINT")
	note.add_theme_color_override("font_color", UiTheme.VERMILION if muted else UiTheme.INK_SOFT)
	queue_redraw()

func _draw() -> void:
	for index in range(ROW_KEYS.size()):
		var mid_y: float = ROW_H * float(index) + 17.0
		if index == selected:
			_draw_marker(Vector2(0.0, mid_y))
		var filled: int = 0 if muted else int(levels[index])
		for tick in range(max_level):
			var x: float = TICKS_X + TICK_STEP * (float(tick) + 0.5)
			var lean: float = sin(float(tick) * 2.3) * 1.2
			var inked: bool = tick < filled
			var color: Color = UiTheme.INK if inked else UiTheme.INK_FAINT
			draw_line(Vector2(x - lean, mid_y - 9.0), Vector2(x + lean, mid_y + 9.0), color, 4.0 if inked else 1.5, true)

## A short tapering brush tick, heavy at the press and thin at the lift.
func _draw_marker(start: Vector2) -> void:
	for step in range(8):
		var t := float(step) / 8.0
		var a := start + Vector2(t * 12.0, -t * 3.0)
		var b := start + Vector2((t + 0.125) * 12.0, -(t + 0.125) * 3.0)
		draw_line(a, b, UiTheme.VERMILION, lerpf(7.0, 1.5, t), true)
