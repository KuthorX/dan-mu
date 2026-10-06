extends Control

## Title-screen mark drawn under the menu text: a vermilion brush tick beside the
## selected difficulty. (The only seal on screen lives on the ofuda.)

const UiTheme = preload("res://scripts/ui_theme.gd")

var selected_row := Rect2()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_selected_row(row: Rect2) -> void:
	selected_row = row
	queue_redraw()

func _draw() -> void:
	if selected_row.size.x <= 0.0:
		return
	# a short tapering brush tick, heavy at the press and thin at the lift
	var start := selected_row.position + Vector2(-2.0, selected_row.size.y * 0.55)
	for step in range(8):
		var t := float(step) / 8.0
		var a := start + Vector2(t * 12.0, -t * 3.0)
		var b := start + Vector2((t + 0.125) * 12.0, -(t + 0.125) * 3.0)
		draw_line(a, b, UiTheme.VERMILION, lerpf(7.0, 1.5, t), true)
