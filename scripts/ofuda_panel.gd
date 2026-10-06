extends Control

## The HUD as a bone-washi talisman (ofuda) pasted on the frame, kept like a ledger:
## every group sits on the same 84px rhythm, labels left, figures right.
## Lives are vermilion dabs, bombs are ink dabs, power is a tally of brush ticks.
## On the title screen the strip carries the best score, the leaderboard and the keys.

const UiTheme = preload("res://scripts/ui_theme.gd")
const I18n = preload("res://scripts/i18n.gd")
const PaperTexture = preload("res://art/ui/ofuda.png")
const SealTexture = preload("res://art/ui/seal.png")
const DabTexture = preload("res://art/ui/dab.png")

const PANEL_SIZE := Vector2(324.0, 924.0)
const PAD := 24.0
const CONTENT_W := 276.0
const MAX_LIFE_DABS := 7
const MAX_BOMB_DABS := 8
## Empty slots are drawn faintly up to these counts so an empty stock still reads.
const LIFE_SLOTS := 3
const BOMB_SLOTS := 3
const PAPER_MARGIN := 8.0
## The difficulty seal is pressed once, inside the foot of the strip, slightly askew.
const SEAL_RECT := Rect2(Vector2(PAD, 788.0), Vector2(116.0, 116.0))
const SEAL_ANGLE_DEG := 4.0
const POWER_TICKS := 20
const ROW := 84.0
const LIVES_Y := 320.0
const BEST_PLAY_Y := 248.0
const BEST_MENU_Y := 40.0
const KEYS_Y := 600.0
const KEY_ROW := 20.0
const STAGE_NAME_POS := Vector2(PAD + CONTENT_W - 52.0, 700.0)
const STAGE_NAME_HEIGHT := 200.0

var logo: Label
var logo_sub: Label
var score_value: Label
var best_label: Label
var best_value: Label
var lives_extra: Label
var power_value: Label
var graze_value: Label
var stage_value: Label
## The stage name runs down the empty foot of the strip in faint ink, like a scroll inscription.
var stage_name: Label
var board_header: Label
var board_body: Label
var key_rows: Control
var difficulty_text: Label
var play_nodes: Array = []
var menu_mode := false
var lives := 0
var bombs := 0
var power := 0.0
var power_max := 200.0

func _ready() -> void:
	size = PANEL_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo = _play(UiTheme.make_label("UI_BRAND_MARK", Vector2(PAD - 4.0, -2.0), UiTheme.BrushFont, 92, UiTheme.INK, CONTENT_W))
	var spaced := FontVariation.new()
	spaced.base_font = UiTheme.SerifFont
	spaced.spacing_glyph = 3
	logo_sub = _play(UiTheme.make_label("UI_BRAND_SUB", Vector2(PAD, 112.0), spaced, 14, UiTheme.VERMILION, CONTENT_W))
	_play(_stat_label("UI_STAT_SCORE", 168.0))
	score_value = _play(_value_label(Vector2(PAD - 2.0, 184.0), 40, UiTheme.INK))
	best_label = _stat_label("UI_STAT_BEST", BEST_PLAY_Y)
	best_value = _value_label(Vector2(PAD, BEST_PLAY_Y + 16.0), 18, UiTheme.INK_SOFT)
	_play(_stat_label("UI_STAT_LIVES", LIVES_Y))
	lives_extra = _play(_value_label(Vector2(PAD, LIVES_Y - 4.0), 18, UiTheme.INK, HORIZONTAL_ALIGNMENT_RIGHT))
	_play(_stat_label("UI_STAT_BOMBS", LIVES_Y + ROW))
	_play(_stat_label("UI_STAT_POWER", LIVES_Y + ROW * 2.0))
	power_value = _play(_value_label(Vector2(PAD, LIVES_Y + ROW * 2.0 - 4.0), 18, UiTheme.INK, HORIZONTAL_ALIGNMENT_RIGHT))
	_play(_stat_label("UI_STAT_GRAZE", LIVES_Y + ROW * 3.0))
	graze_value = _play(_value_label(Vector2(PAD, LIVES_Y + ROW * 3.0 - 4.0), 18, UiTheme.INK, HORIZONTAL_ALIGNMENT_RIGHT))
	_play(_stat_label("UI_STAT_STAGE", LIVES_Y + ROW * 4.0))
	stage_value = _play(UiTheme.make_label("", Vector2(PAD, LIVES_Y + ROW * 4.0 - 4.0), UiTheme.SerifFont, 18, UiTheme.INK, CONTENT_W, HORIZONTAL_ALIGNMENT_RIGHT))
	stage_name = _play(UiTheme.make_label("", STAGE_NAME_POS, UiTheme.BrushFont, 34, UiTheme.INK_FAINT, 48.0, HORIZONTAL_ALIGNMENT_CENTER))
	board_header = UiTheme.make_label("", Vector2(PAD, 150.0), UiTheme.SerifFont, 18, UiTheme.VERMILION, CONTENT_W)
	add_child(board_header)
	board_body = UiTheme.make_wrapped(UiTheme.make_label("", Vector2(PAD, 184.0), UiTheme.SerifFont, 14, UiTheme.INK, CONTENT_W), KEYS_Y - 200.0)
	add_child(board_body)
	key_rows = Control.new()
	key_rows.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(key_rows)
	difficulty_text = UiTheme.make_label("", SEAL_RECT.position + Vector2(6.0, 30.0), UiTheme.BrushFont, 40, UiTheme.PAPER, 104.0, HORIZONTAL_ALIGNMENT_CENTER)
	difficulty_text.pivot_offset = Vector2(52.0, 28.0)
	difficulty_text.rotation = deg_to_rad(SEAL_ANGLE_DEG)
	add_child(difficulty_text)
	refresh_language()

func _play(node: Control) -> Control:
	if node.get_parent() == null:
		add_child(node)
	play_nodes.append(node)
	return node

func _stat_label(key: String, y: float) -> Label:
	var label := UiTheme.make_label(key, Vector2(PAD, y), UiTheme.SerifFont, 14, UiTheme.INK_SOFT, 120.0)
	add_child(label)
	return label

func _value_label(pos: Vector2, font_size: int, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := UiTheme.make_label("", pos, _numeral_font(), font_size, color, CONTENT_W - (pos.x - PAD), align)
	label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	add_child(label)
	return label

## Serif numerals with tabular figures, so changing scores never shuffle sideways.
func _numeral_font() -> FontVariation:
	var numerals := FontVariation.new()
	numerals.base_font = UiTheme.SerifFont
	numerals.opentype_features = {"tnum": 1}
	return numerals

## Title screen: only the best score and the leaderboard; in play: the full strip.
func set_menu_mode(enabled: bool) -> void:
	menu_mode = enabled
	for node in play_nodes:
		node.visible = not enabled
	board_header.visible = enabled
	board_body.visible = enabled
	key_rows.visible = enabled
	var best_y: float = BEST_MENU_Y if enabled else BEST_PLAY_Y
	best_label.position.y = best_y
	best_value.position.y = best_y + 16.0
	best_value.add_theme_font_size_override("font_size", 40 if enabled else 18)
	best_value.add_theme_color_override("font_color", UiTheme.INK if enabled else UiTheme.INK_SOFT)
	queue_redraw()

func set_status(status: Dictionary) -> void:
	score_value.text = "%09d" % int(status.get("score", 0))
	var best_score := int(status.get("best_score", 0))
	best_value.text = "%09d" % best_score if best_score > 0 else tr("UI_NO_RECORD")
	lives = int(status.get("lives", 0))
	bombs = int(status.get("bombs", 0))
	power = float(status.get("power", 0))
	power_max = max(1.0, float(status.get("power_max", 200)))
	lives_extra.text = "× %d" % lives if lives > MAX_LIFE_DABS else ""
	power_value.text = "%d / %d" % [int(power), int(power_max)]
	graze_value.text = "%d" % int(status.get("graze", 0))
	stage_value.text = str(status.get("stage_text", ""))
	_set_stage_name(str(status.get("stage_name", "")))
	difficulty_text.text = str(status.get("difficulty_text", ""))
	UiTheme.fit_line(difficulty_text, 40 if I18n.current_locale() == I18n.LOCALE_ZH else 24, 14, 104.0)
	queue_redraw()

func show_board(title: String, body_text: String) -> void:
	board_header.text = title
	board_body.text = body_text

func refresh_language() -> void:
	UiTheme.fit_line(logo_sub, 14, 10, CONTENT_W)
	_build_key_rows()

## Click target for the last ledger line (L: switch language), in panel coordinates.
func language_row_rect() -> Rect2:
	var rows: int = tr("UI_TITLE_CONTROLS").split("\n").size()
	return Rect2(Vector2(PAD, KEYS_Y + KEY_ROW * float(rows - 1)), Vector2(CONTENT_W, KEY_ROW))

## The controls, set like ledger lines: key on the left, what it does on the right.
func _build_key_rows() -> void:
	for child in key_rows.get_children():
		child.queue_free()
	var lines: PackedStringArray = tr("UI_TITLE_CONTROLS").split("\n")
	for index in range(lines.size()):
		var parts: PackedStringArray = lines[index].split("|")
		var y: float = KEYS_Y + KEY_ROW * float(index)
		var key_label := UiTheme.make_label(parts[0], Vector2(PAD, y), UiTheme.SerifFont, 14, UiTheme.INK, CONTENT_W)
		key_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		key_rows.add_child(key_label)
		if parts.size() > 1:
			var action := UiTheme.make_label(parts[1], Vector2(PAD, y), UiTheme.SerifFont, 14, UiTheme.INK_SOFT, CONTENT_W, HORIZONTAL_ALIGNMENT_RIGHT)
			action.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
			key_rows.add_child(action)

func _draw() -> void:
	draw_texture_rect(PaperTexture, Rect2(-Vector2(PAPER_MARGIN, PAPER_MARGIN), PANEL_SIZE + Vector2(PAPER_MARGIN, PAPER_MARGIN) * 2.0), false)
	if not menu_mode:
		var life_count: int = 1 if lives > MAX_LIFE_DABS else clamp(lives, 0, MAX_LIFE_DABS)
		_draw_dabs(Vector2(PAD, LIVES_Y + 24.0), LIFE_SLOTS if lives <= MAX_LIFE_DABS else 1, 24.0, UiTheme.INK_FAINT)
		_draw_dabs(Vector2(PAD, LIVES_Y + 24.0), life_count, 24.0, UiTheme.VERMILION)
		_draw_dabs(Vector2(PAD, LIVES_Y + ROW + 24.0), BOMB_SLOTS, 24.0, UiTheme.INK_FAINT)
		_draw_dabs(Vector2(PAD, LIVES_Y + ROW + 24.0), clamp(bombs, 0, MAX_BOMB_DABS), 24.0, UiTheme.INK)
		_draw_power_stroke(Vector2(PAD, LIVES_Y + ROW * 2.0 + 26.0))
	draw_set_transform(SEAL_RECT.get_center(), deg_to_rad(SEAL_ANGLE_DEG), Vector2.ONE)
	draw_texture_rect(SealTexture, Rect2(-SEAL_RECT.size * 0.5, SEAL_RECT.size), false, UiTheme.VERMILION)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_dabs(origin: Vector2, count: int, dab_size: float, color: Color) -> void:
	for index in range(count):
		var rect := Rect2(origin + Vector2(float(index) * (dab_size + 4.0), 0.0), Vector2(dab_size, dab_size))
		draw_set_transform(rect.get_center(), float(index) * 1.7, Vector2.ONE)
		draw_texture_rect(DabTexture, Rect2(-rect.size * 0.5, rect.size), false, color)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

## Power is a row of brush ticks, like a tally; inked ticks are earned power.
func _draw_power_stroke(origin: Vector2) -> void:
	var filled: int = int(floor(POWER_TICKS * clamp(power / power_max, 0.0, 1.0)))
	var step: float = CONTENT_W / float(POWER_TICKS)
	for index in range(POWER_TICKS):
		var x: float = origin.x + step * (float(index) + 0.5)
		var lean: float = sin(float(index) * 2.3) * 1.2
		var inked: bool = index < filled
		var color: Color = UiTheme.INK if inked else UiTheme.INK_FAINT
		draw_line(Vector2(x - lean, origin.y - 2.0), Vector2(x + lean, origin.y + 12.0), color, 3.0 if inked else 1.0, true)

func _set_stage_name(text: String) -> void:
	var vertical_zh: bool = I18n.current_locale() == I18n.LOCALE_ZH
	var shown: String = "\n".join(text.split("")) if vertical_zh else text
	if stage_name.text == shown:
		return
	stage_name.text = shown
	# Chinese stacks one glyph per line; Latin text is turned on its side instead
	stage_name.rotation = 0.0 if vertical_zh else PI * 0.5
	stage_name.size = Vector2(48.0, STAGE_NAME_HEIGHT) if vertical_zh else Vector2(STAGE_NAME_HEIGHT, 48.0)
	stage_name.position = STAGE_NAME_POS if vertical_zh else STAGE_NAME_POS + Vector2(44.0, 0.0)
	if vertical_zh:
		stage_name.add_theme_font_size_override("font_size", 34)
	else:
		UiTheme.fit_line(stage_name, 22, 12, STAGE_NAME_HEIGHT - 48.0)
