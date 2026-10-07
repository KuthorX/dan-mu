extends CanvasLayer

## HUD, title menu, overlays, dialogue and boss cut-ins.
## Visual language lives in ui_theme.gd; the status strip lives in ofuda_panel.gd.

const BulletScript = preload("res://scripts/bullet.gd")
const UiTheme = preload("res://scripts/ui_theme.gd")
const I18n = preload("res://scripts/i18n.gd")
const OfudaPanelScript = preload("res://scripts/ofuda_panel.gd")
const TitleArtScript = preload("res://scripts/title_art.gd")
const PortraitViewScript = preload("res://scripts/portrait_view.gd")
const VolumeRowsScript = preload("res://scripts/volume_rows.gd")
const SheetTexture = preload("res://art/ui/sheet.png")
const CardTexture = preload("res://art/ui/card.png")
const ScrollTexture = preload("res://art/ui/scroll.png")

signal language_toggle_requested

const SHEET_RECT := Rect2(52.0, 220.0, 504.0, 520.0)
const SHEET_RISE := 90.0
const SHEET_RISE_TIME := 0.32
const CARD_SIZE := Vector2(152.0, 204.0)
const CARD_GAP := 10.0
const DryBrushShader = preload("res://art/ui/dry_brush.gdshader")
const DIALOGUE_RECT := Rect2(40.0, 704.0, 528.0, 214.0)
const SIGNATURE_POS := Vector2(252.0, 300.0)
const MENU_X := 312.0
const MENU_W := 256.0
const FLASH_SCALE := 0.6

var playfield_rect := Rect2(24.0, 24.0, 560.0, 912.0)
var window_size := Vector2i(960, 960)
var root: Control
var ofuda
var overlay: ColorRect
var overlay_header: Label
var overlay_sheet: Control
var sheet_rise_timer := 0.0
var result_score_label: Label
var result_score_value: Label
var overlay_body: Label
var overlay_footer: Label
var reward_container: Control
var reward_cards: Array = []
var reward_anim_timer := 0.0
var reward_anim_duration := 0.0
var flash_rect: ColorRect
var flash_timer := 0.0
var flash_duration := 0.0
var flash_peak_alpha := 0.0
var boss_label: Label
var boss_bar: HpBar
var boss_multi_container: Control
var boss_multi_rows: Array = []
var banner_title: Label
var banner_subtitle: Label
var banner_timer := 0.0
var banner_duration := 2.7
var title_container: Control
var title_art
var title_ship_label: Label
var title_ship_description: Label
var title_mode_label: Label
var title_mode_description: Label
var title_start: Label
var language_button: Button
var difficulty_labels: Array = []
var title_anim_time := 0.0
var dialogue_container: Control
var dialogue_name: Label
var dialogue_text: Label
var dialogue_hint: Label
var volume_rows: Control
var dialogue_index_label: Label
var dialogue_left_portrait
var dialogue_right_portrait
var dialogue_full_text := ""
var dialogue_visible_count := 0
var dialogue_typing_speed := 64.0
var dialogue_active := false
var spotlight_container: Control
var spotlight_title: Label
var spotlight_subtitle: Label
var spotlight_quote: Label
var spotlight_portrait
var spotlight_timer := 0.0
var spotlight_duration := 0.0
var current_ship_label := ""
var current_mode_label := ""

func setup(rect: Rect2, viewport_size: Vector2i):
	playfield_rect = rect
	window_size = viewport_size
	return self

func _ready() -> void:
	layer = 10
	UiTheme.ensure_fallbacks()
	_build_ui()

func _process(delta: float) -> void:
	title_anim_time += delta
	if title_container.visible:
		title_start.modulate.a = 0.55 + 0.45 * absf(sin(title_anim_time * 2.2))
	_update_banner(delta)
	_update_flash(delta)
	if dialogue_active and dialogue_visible_count < dialogue_full_text.length():
		dialogue_visible_count = min(dialogue_full_text.length(), dialogue_visible_count + int(delta * dialogue_typing_speed) + 1)
		dialogue_text.text = dialogue_full_text.substr(0, dialogue_visible_count)
	_update_spotlight(delta)
	_update_sheet_rise(delta)
	if reward_container.visible:
		if reward_anim_timer > 0.0:
			reward_anim_timer = max(0.0, reward_anim_timer - delta)
		_update_reward_card_animation()

func _update_banner(delta: float) -> void:
	if banner_timer <= 0.0:
		banner_title.visible = false
		banner_subtitle.visible = false
		return
	banner_timer = max(0.0, banner_timer - delta)
	var fade_in: float = clamp((banner_duration - banner_timer) / 0.28, 0.0, 1.0)
	var fade_out: float = clamp(banner_timer / 0.5, 0.0, 1.0)
	var alpha: float = min(fade_in, fade_out)
	banner_title.modulate.a = alpha
	banner_subtitle.modulate.a = alpha * 0.92
	banner_title.visible = alpha > 0.01
	banner_subtitle.visible = alpha > 0.01 and banner_subtitle.text != ""

func _update_flash(delta: float) -> void:
	if flash_timer <= 0.0:
		flash_rect.visible = false
		return
	flash_timer = max(0.0, flash_timer - delta)
	var ratio: float = 1.0 - flash_timer / max(flash_duration, 0.0001)
	var flash_color: Color = flash_rect.color
	flash_color.a = sin(ratio * PI) * flash_peak_alpha
	flash_rect.color = flash_color
	flash_rect.visible = flash_color.a > 0.001

## Overlay sheets slide up from below the playfield like paper pushed over the scroll.
func _update_sheet_rise(delta: float) -> void:
	sheet_rise_timer = max(0.0, sheet_rise_timer - delta)
	var t: float = 1.0 - sheet_rise_timer / SHEET_RISE_TIME
	var eased: float = 1.0 - pow(1.0 - t, 3.0)
	overlay_sheet.position.y = SHEET_RECT.position.y - playfield_rect.position.y + (1.0 - eased) * SHEET_RISE
	overlay_sheet.modulate.a = eased

func _update_spotlight(delta: float) -> void:
	if spotlight_timer <= 0.0:
		spotlight_container.visible = false
		return
	spotlight_timer = max(0.0, spotlight_timer - delta)
	var progress: float = 1.0 - clamp(spotlight_timer / max(spotlight_duration, 0.0001), 0.0, 1.0)
	spotlight_container.modulate.a = min(1.0, sin(progress * PI) * 1.4)
	spotlight_container.visible = spotlight_container.modulate.a > 0.02
	var drift: float = (1.0 - progress) * 26.0
	spotlight_portrait.position.x = 6.0 + (drift if spotlight_portrait.side == "right" else -drift)

func _build_ui() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	ofuda = OfudaPanelScript.new()
	ofuda.position = Vector2(616.0, 18.0)
	root.add_child(ofuda)
	_build_title()
	_build_boss_bars()
	_build_banner()
	_build_dialogue()
	_build_spotlight()
	_build_overlay()
	flash_rect = ColorRect.new()
	flash_rect.position = playfield_rect.position
	flash_rect.size = playfield_rect.size
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_rect.color = Color(1.0, 1.0, 1.0, 0.0)
	flash_rect.visible = false
	root.add_child(flash_rect)

func _build_title() -> void:
	title_container = Control.new()
	title_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(title_container)
	title_art = TitleArtScript.new()
	title_art.position = Vector2.ZERO
	title_art.size = Vector2(window_size)
	title_container.add_child(title_art)
	var hero := UiTheme.make_label("UI_TITLE_HERO", Vector2(40.0, 58.0), UiTheme.BrushFont, 200, UiTheme.PAPER, 220.0, HORIZONTAL_ALIGNMENT_CENTER)
	hero.size.y = 520.0
	hero.add_theme_constant_override("line_spacing", -36)
	title_container.add_child(hero)
	var hero_material := ShaderMaterial.new()
	hero_material.shader = DryBrushShader
	hero.material = hero_material
	# the subtitle is signed under the logo in small brush hand, like a painter's inscription
	# the inscription runs down beside 幕, like a painter's signature on a hanging scroll
	var signature := UiTheme.make_label("", SIGNATURE_POS, UiTheme.BrushFont, 24, UiTheme.PAPER_DIM, 30.0)
	signature.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	title_container.add_child(signature)
	title_container.set_meta("signature", signature)
	_title_header("UI_SELECT_DIFFICULTY", 92.0)
	for index in range(4):
		var row := UiTheme.make_label("", Vector2(MENU_X + 14.0, 124.0 + float(index) * 46.0), UiTheme.SerifFont, 24, UiTheme.PAPER_DIM, MENU_W - 14.0)
		difficulty_labels.append(row)
		title_container.add_child(row)
	_title_header("UI_SELECT_SHIP", 336.0)
	title_ship_label = UiTheme.add_keyline(UiTheme.make_label("", Vector2(MENU_X, 364.0), UiTheme.SerifFont, 24, UiTheme.PAPER, MENU_W), 4)
	title_container.add_child(title_ship_label)
	title_ship_description = UiTheme.make_wrapped(UiTheme.make_label("", Vector2(MENU_X, 402.0), UiTheme.SerifFont, 15, UiTheme.PAPER_DIM, MENU_W), 66.0)
	title_container.add_child(title_ship_description)
	_title_header("UI_SELECT_MODE", 494.0)
	title_mode_label = UiTheme.add_keyline(UiTheme.make_label("", Vector2(MENU_X, 522.0), UiTheme.SerifFont, 24, UiTheme.PAPER, MENU_W), 4)
	title_container.add_child(title_mode_label)
	title_mode_description = UiTheme.make_wrapped(UiTheme.make_label("", Vector2(MENU_X, 560.0), UiTheme.SerifFont, 15, UiTheme.PAPER_DIM, MENU_W), 66.0)
	title_container.add_child(title_mode_description)
	title_start = UiTheme.add_keyline(UiTheme.make_label("UI_TITLE_START", Vector2(MENU_X, 676.0), UiTheme.SerifFont, 22, UiTheme.GOLD, MENU_W), 4)
	title_container.add_child(title_start)
	# the language switch is the "L" line of the key ledger on the ofuda; this is
	# just its click target, so the playfield carries no extra button
	language_button = Button.new()
	language_button.position = ofuda.position + ofuda.language_row_rect().position
	language_button.size = ofuda.language_row_rect().size
	language_button.focus_mode = Control.FOCUS_NONE
	language_button.flat = true
	language_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	language_button.pressed.connect(func() -> void: language_toggle_requested.emit())
	title_container.add_child(language_button)
	_refresh_language_ui()

func _title_header(key: String, y: float) -> void:
	title_container.add_child(UiTheme.make_label(key, Vector2(MENU_X, y), UiTheme.SerifFont, 14, UiTheme.VERMILION.lightened(0.25), MENU_W))

func _build_boss_bars() -> void:
	boss_bar = _make_boss_progress(Vector2(playfield_rect.position.x + 16.0, playfield_rect.position.y + 10.0), Vector2(playfield_rect.size.x - 32.0, 6.0))
	boss_bar.visible = false
	root.add_child(boss_bar)
	boss_label = UiTheme.add_keyline(UiTheme.make_label("", Vector2(playfield_rect.position.x + 16.0, playfield_rect.position.y + 18.0), UiTheme.SerifFont, 19, UiTheme.PAPER, playfield_rect.size.x - 32.0, HORIZONTAL_ALIGNMENT_RIGHT), 5)
	boss_label.visible = false
	root.add_child(boss_label)
	boss_multi_container = Control.new()
	boss_multi_container.position = Vector2(playfield_rect.position.x + 16.0, playfield_rect.position.y + 10.0)
	boss_multi_container.size = Vector2(playfield_rect.size.x - 32.0, 60.0)
	boss_multi_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	boss_multi_container.visible = false
	root.add_child(boss_multi_container)
	var row_width: float = (boss_multi_container.size.x - 16.0) * 0.5
	for row_index in range(2):
		var row := Control.new()
		row.position = Vector2(float(row_index) * (row_width + 16.0), 0.0)
		row.size = Vector2(row_width, 44.0)
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		boss_multi_container.add_child(row)
		var bar := _make_boss_progress(Vector2.ZERO, Vector2(row_width, 5.0))
		row.add_child(bar)
		var label := UiTheme.add_keyline(UiTheme.make_label("", Vector2(0.0, 8.0), UiTheme.SerifFont, 15, UiTheme.PAPER, row_width, HORIZONTAL_ALIGNMENT_LEFT if row_index == 0 else HORIZONTAL_ALIGNMENT_RIGHT), 4)
		row.add_child(label)
		boss_multi_rows.append({"row": row, "label": label, "bar": bar})

func _make_boss_progress(pos: Vector2, bar_size: Vector2) -> HpBar:
	var bar := HpBar.new()
	bar.position = pos
	bar.size = bar_size
	return bar

func _set_bar_color(bar: HpBar, color: Color) -> void:
	var ink: Color = BulletScript.ink_palette(color)
	bar.fill_color = Color(ink.r, ink.g, ink.b, 1.0)
	bar.queue_redraw()

## A hairline health bar: ink track with a keyline, filled in the phase colour.
class HpBar extends Control:
	var max_value := 1.0
	var value := 1.0:
		set(new_value):
			value = new_value
			queue_redraw()
	var fill_color := Color(0.84, 0.68, 0.36)

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect.grow(1.0), Color(0.02, 0.01, 0.03, 0.85), true)
		var ratio: float = clamp(value / max(max_value, 0.0001), 0.0, 1.0)
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * ratio, size.y)), fill_color, true)

func _build_banner() -> void:
	banner_title = UiTheme.add_keyline(UiTheme.make_label("", Vector2(playfield_rect.position.x, playfield_rect.position.y + 500.0), UiTheme.SerifFont, 32, UiTheme.PAPER, playfield_rect.size.x, HORIZONTAL_ALIGNMENT_CENTER), 8)
	banner_title.visible = false
	root.add_child(banner_title)
	banner_subtitle = UiTheme.add_keyline(UiTheme.make_label("", Vector2(playfield_rect.position.x, playfield_rect.position.y + 552.0), UiTheme.SerifFont, 17, UiTheme.GOLD, playfield_rect.size.x, HORIZONTAL_ALIGNMENT_CENTER), 6)
	banner_subtitle.visible = false
	root.add_child(banner_subtitle)

func _build_overlay() -> void:
	# the overlay is a slip of paper laid slightly askew on the playfield; the ofuda
	# beside it stays readable, because that is where the scores already live
	overlay = ColorRect.new()
	overlay.position = playfield_rect.position
	overlay.size = playfield_rect.size
	overlay.color = Color(0.02, 0.0, 0.01, 0.6)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.visible = false
	root.add_child(overlay)
	var sheet := Control.new()
	sheet.position = SHEET_RECT.position - playfield_rect.position
	sheet.size = SHEET_RECT.size
	sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(sheet)
	overlay_sheet = sheet
	sheet.add_child(UiTheme.paper_rect(SheetTexture, Rect2(Vector2.ZERO, SHEET_RECT.size)))
	var inner_w: float = SHEET_RECT.size.x - 68.0
	overlay_header = UiTheme.make_label("", Vector2(34.0, 40.0), UiTheme.BrushFont, 72, UiTheme.OXBLOOD, inner_w, HORIZONTAL_ALIGNMENT_CENTER)
	sheet.add_child(overlay_header)
	result_score_label = UiTheme.make_label("UI_RESULT_SCORE_LABEL", Vector2(34.0, 176.0), UiTheme.SerifFont, 15, UiTheme.INK_SOFT, inner_w, HORIZONTAL_ALIGNMENT_CENTER)
	sheet.add_child(result_score_label)
	var numerals := FontVariation.new()
	numerals.base_font = UiTheme.SerifFont
	numerals.opentype_features = {"tnum": 1}
	result_score_value = UiTheme.make_label("", Vector2(34.0, 198.0), numerals, 64, UiTheme.INK, inner_w, HORIZONTAL_ALIGNMENT_CENTER)
	result_score_value.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	sheet.add_child(result_score_value)
	overlay_body = UiTheme.make_wrapped(UiTheme.make_label("", Vector2(34.0, 180.0), UiTheme.SerifFont, 18, UiTheme.INK, inner_w, HORIZONTAL_ALIGNMENT_CENTER), 300.0)
	sheet.add_child(overlay_body)
	overlay_footer = UiTheme.make_wrapped(UiTheme.make_label("", Vector2(34.0, SHEET_RECT.size.y - 64.0), UiTheme.SerifFont, 14, UiTheme.OXBLOOD, inner_w, HORIZONTAL_ALIGNMENT_CENTER), 44.0)
	sheet.add_child(overlay_footer)
	volume_rows = VolumeRowsScript.new().setup(inner_w)
	volume_rows.position = Vector2(34.0, 290.0)
	volume_rows.visible = false
	sheet.add_child(volume_rows)
	reward_container = Control.new()
	reward_container.position = Vector2((SHEET_RECT.size.x - CARD_SIZE.x * 3.0 - CARD_GAP * 2.0) * 0.5, 230.0)
	reward_container.size = Vector2(CARD_SIZE.x * 3.0 + CARD_GAP * 2.0, CARD_SIZE.y)
	reward_container.visible = false
	sheet.add_child(reward_container)
	for card_index in range(3):
		reward_cards.append(_build_reward_card(card_index))

func _build_reward_card(card_index: int) -> Dictionary:
	var card_root := Control.new()
	card_root.position = Vector2(float(card_index) * (CARD_SIZE.x + CARD_GAP), 0.0)
	card_root.size = CARD_SIZE
	reward_container.add_child(card_root)
	card_root.add_child(UiTheme.paper_rect(CardTexture, Rect2(Vector2.ZERO, CARD_SIZE)))
	var frame := ColorRect.new()
	frame.position = Vector2(0.0, 0.0)
	frame.size = Vector2(CARD_SIZE.x, 6.0)
	card_root.add_child(frame)
	var selection := ReferenceRect.new()
	selection.position = Vector2(-5.0, -5.0)
	selection.size = CARD_SIZE + Vector2(10.0, 10.0)
	selection.editor_only = false
	selection.border_color = UiTheme.VERMILION
	selection.border_width = 3.0
	card_root.add_child(selection)
	var rarity_label := UiTheme.make_label("", Vector2(12.0, 12.0), UiTheme.SerifFont, 12, UiTheme.INK_SOFT, CARD_SIZE.x - 24.0, HORIZONTAL_ALIGNMENT_RIGHT)
	card_root.add_child(rarity_label)
	var title_label := UiTheme.make_wrapped(UiTheme.make_label("", Vector2(12.0, 28.0), UiTheme.SerifFont, 19, UiTheme.INK, CARD_SIZE.x - 24.0), 52.0)
	card_root.add_child(title_label)
	var desc_label := UiTheme.make_wrapped(UiTheme.make_label("", Vector2(12.0, 82.0), UiTheme.SerifFont, 14, UiTheme.INK, CARD_SIZE.x - 24.0), 70.0)
	card_root.add_child(desc_label)
	var detail_label := UiTheme.make_wrapped(UiTheme.make_label("", Vector2(12.0, 156.0), UiTheme.SerifFont, 12, UiTheme.OXBLOOD, CARD_SIZE.x - 24.0), 40.0)
	card_root.add_child(detail_label)
	return {"root": card_root, "frame": frame, "selection": selection, "rarity": rarity_label, "title": title_label, "desc": desc_label, "detail": detail_label, "base_pos": card_root.position}

func _build_dialogue() -> void:
	dialogue_container = Control.new()
	dialogue_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialogue_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_container.visible = false
	root.add_child(dialogue_container)
	dialogue_left_portrait = PortraitViewScript.new()
	dialogue_left_portrait.position = Vector2(24.0, 396.0)
	dialogue_left_portrait.size = Vector2(250.0, 316.0)
	dialogue_container.add_child(dialogue_left_portrait)
	dialogue_right_portrait = PortraitViewScript.new()
	dialogue_right_portrait.position = Vector2(334.0, 380.0)
	dialogue_right_portrait.size = Vector2(250.0, 332.0)
	dialogue_container.add_child(dialogue_right_portrait)
	dialogue_container.add_child(UiTheme.paper_rect(ScrollTexture, DIALOGUE_RECT))
	var inner_x: float = DIALOGUE_RECT.position.x + 28.0
	var inner_w: float = DIALOGUE_RECT.size.x - 56.0
	dialogue_name = UiTheme.make_label("", Vector2(inner_x, DIALOGUE_RECT.position.y + 18.0), UiTheme.SerifFont, 20, UiTheme.OXBLOOD, inner_w)
	dialogue_container.add_child(dialogue_name)
	dialogue_text = UiTheme.make_wrapped(UiTheme.make_label("", Vector2(inner_x, DIALOGUE_RECT.position.y + 58.0), UiTheme.SerifFont, 19, UiTheme.INK, inner_w), 110.0)
	dialogue_container.add_child(dialogue_text)
	dialogue_index_label = UiTheme.make_label("", Vector2(inner_x, DIALOGUE_RECT.end.y - 36.0), UiTheme.SerifFont, 13, UiTheme.INK_SOFT, 100.0)
	dialogue_index_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	dialogue_container.add_child(dialogue_index_label)
	dialogue_hint = UiTheme.make_label("UI_DIALOGUE_NEXT", Vector2(inner_x, DIALOGUE_RECT.end.y - 36.0), UiTheme.SerifFont, 13, UiTheme.INK_SOFT, inner_w, HORIZONTAL_ALIGNMENT_RIGHT)
	dialogue_container.add_child(dialogue_hint)

func _build_spotlight() -> void:
	spotlight_container = Control.new()
	spotlight_container.position = Vector2(316.0, 96.0)
	spotlight_container.size = Vector2(264.0, 400.0)
	spotlight_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spotlight_container.visible = false
	root.add_child(spotlight_container)
	spotlight_portrait = PortraitViewScript.new()
	spotlight_portrait.position = Vector2(6.0, 0.0)
	spotlight_portrait.size = Vector2(252.0, 300.0)
	spotlight_portrait.figure_alpha = 0.72
	spotlight_container.add_child(spotlight_portrait)
	# no panel behind the words: the boss's name is brushed straight onto the scroll.
	# The spell name itself lives only in the top-right corner, never twice.
	spotlight_title = UiTheme.add_keyline(UiTheme.make_label("", Vector2(12.0, 252.0), UiTheme.BrushFont, 30, UiTheme.PAPER, 240.0, HORIZONTAL_ALIGNMENT_CENTER), 6)
	spotlight_container.add_child(spotlight_title)
	spotlight_subtitle = UiTheme.make_wrapped(UiTheme.add_keyline(UiTheme.make_label("", Vector2(12.0, 296.0), UiTheme.SerifFont, 13, UiTheme.GOLD, 240.0, HORIZONTAL_ALIGNMENT_CENTER), 5), 40.0)
	spotlight_container.add_child(spotlight_subtitle)
	spotlight_quote = UiTheme.make_wrapped(UiTheme.add_keyline(UiTheme.make_label("", Vector2(12.0, 344.0), UiTheme.SerifFont, 14, UiTheme.PAPER, 240.0, HORIZONTAL_ALIGNMENT_CENTER), 5), 42.0)
	spotlight_container.add_child(spotlight_quote)

func set_status(status: Dictionary) -> void:
	ofuda.set_status(status)

func set_boss_state(visible: bool, current_hp: float, max_hp_value: float, phase_name: String) -> void:
	boss_multi_container.visible = false
	boss_label.visible = visible
	boss_bar.visible = visible
	if not visible:
		return
	boss_label.text = phase_name
	UiTheme.fit_line(boss_label, 19, 13, playfield_rect.size.x - 32.0)
	boss_bar.max_value = max(1.0, max_hp_value)
	boss_bar.value = clamp(current_hp, 0.0, max_hp_value)

func set_boss_states(states: Array) -> void:
	if states.is_empty():
		boss_multi_container.visible = false
		set_boss_state(false, 0.0, 1.0, "")
		return
	if states.size() == 1:
		var state: Dictionary = states[0]
		_set_bar_color(boss_bar, state.get("accent_color", UiTheme.GOLD))
		set_boss_state(true, float(state.get("hp", 0.0)), float(state.get("max_hp", 1.0)), str(state.get("phase_name", tr("UI_BOSS"))))
		return
	boss_label.visible = false
	boss_bar.visible = false
	boss_multi_container.visible = true
	for row_index in range(boss_multi_rows.size()):
		var row_data: Dictionary = boss_multi_rows[row_index]
		var row_visible: bool = row_index < states.size()
		row_data["row"].visible = row_visible
		if not row_visible:
			continue
		var state: Dictionary = states[row_index]
		row_data["label"].text = str(state.get("phase_name", tr("UI_BOSS_N") % (row_index + 1)))
		UiTheme.fit_line(row_data["label"], 15, 11, row_data["row"].size.x)
		_set_bar_color(row_data["bar"], state.get("accent_color", UiTheme.GOLD))
		row_data["bar"].max_value = max(1.0, float(state.get("max_hp", 1.0)))
		row_data["bar"].value = clamp(float(state.get("hp", 0.0)), 0.0, float(state.get("max_hp", 1.0)))

func flash(color: Color, alpha := 0.6, duration := 0.25) -> void:
	flash_peak_alpha = alpha * FLASH_SCALE
	flash_rect.color = Color(color.r, color.g, color.b, flash_peak_alpha)
	flash_duration = duration
	flash_timer = duration
	flash_rect.visible = true

func show_title(_best_score: int, difficulty_names := [], selected_index := 1, ship_label := "", ship_description := "", mode_label := "", mode_description := "", board_title := "", board_body := "") -> void:
	overlay.visible = false
	dialogue_container.visible = false
	title_container.visible = true
	ofuda.set_menu_mode(true)
	if difficulty_names.is_empty():
		difficulty_names = [tr("DIFF_EASY"), tr("DIFF_NORMAL"), tr("DIFF_HARD"), tr("DIFF_LUNATIC")]
	_refresh_language_ui()
	_update_title_menu(difficulty_names, selected_index, ship_label, ship_description, mode_label, mode_description, board_title, board_body)

func update_title_difficulty(difficulty_names: Array, selected_index: int) -> void:
	_update_title_menu(difficulty_names, selected_index, current_ship_label, title_ship_description.text, current_mode_label, title_mode_description.text, ofuda.board_header.text, ofuda.board_body.text)

func update_title_menu(difficulty_names: Array, selected_index: int, ship_label := "", ship_description := "", mode_label := "", mode_description := "", board_title := "", board_body := "") -> void:
	_update_title_menu(difficulty_names, selected_index, ship_label, ship_description, mode_label, mode_description, board_title, board_body)

func _update_title_menu(difficulty_names: Array, selected_index: int, ship_label: String, ship_description: String, mode_label: String, mode_description: String, board_title: String, board_body: String) -> void:
	for index in range(difficulty_labels.size()):
		var label: Label = difficulty_labels[index]
		label.visible = index < difficulty_names.size()
		if not label.visible:
			continue
		var selected := index == selected_index
		label.text = str(difficulty_names[index])
		label.add_theme_color_override("font_color", UiTheme.PAPER if selected else UiTheme.PAPER_DIM)
		label.add_theme_font_size_override("font_size", 26 if selected else 22)
	title_art.set_selected_row(Rect2(Vector2(MENU_X, 124.0 + float(selected_index) * 46.0), Vector2(MENU_W, 40.0)))
	current_ship_label = ship_label
	current_mode_label = mode_label
	title_ship_label.text = "‹ %s ›" % ship_label
	title_ship_description.text = ship_description
	UiTheme.fit_wrapped(title_ship_description, 15, 11)
	title_mode_label.text = "‹ %s ›" % mode_label
	title_mode_description.text = mode_description
	UiTheme.fit_wrapped(title_mode_description, 15, 11)
	ofuda.show_board(board_title, board_body)
	title_container.set_meta("selected_index", selected_index)

func hide_title() -> void:
	title_container.visible = false
	ofuda.set_menu_mode(false)

## `sound` holds music, sfx, max, selected and muted (see main.gd `_sound_state`).
func show_pause(sound: Dictionary) -> void:
	_show_volume_sheet(tr("UI_PAUSED"), tr("UI_PAUSED_BODY"), tr("UI_PAUSED_FOOTER"), sound)

## The title's sound sheet: the same paper slip as the pause, with only the levels.
func show_sound_sheet(sound: Dictionary) -> void:
	_show_volume_sheet(tr("UI_SOUND"), tr("UI_SOUND_BODY"), tr("UI_SOUND_FOOTER"), sound)

func update_volume(sound: Dictionary) -> void:
	volume_rows.show_levels(int(sound.get("music", 0)), int(sound.get("sfx", 0)), int(sound.get("max", 10)), int(sound.get("selected", 0)), bool(sound.get("muted", false)))

func is_sound_sheet_visible() -> bool:
	return overlay.visible and volume_rows.visible

func _show_volume_sheet(header: String, body: String, footer: String, sound: Dictionary) -> void:
	set_overlay(header, body, footer)
	overlay_body.size.y = 100.0
	UiTheme.fit_wrapped(overlay_body, 18, 12)
	volume_rows.visible = true
	update_volume(sound)

func show_stage_transition(stage_number: int, title: String, subtitle: String) -> void:
	set_overlay(tr("UI_STAGE_N") % stage_number, "%s\n\n%s" % [title, subtitle], tr("UI_STAGE_TRANSITION_FOOTER"))

func hide_overlay() -> void:
	overlay.visible = false

## The result is one inked word, the score set large beneath it, and the best line.
func show_result(victory: bool, score: int, best_score: int) -> void:
	var title := tr("UI_ALL_CLEAR") if victory else tr("UI_GAME_OVER")
	set_overlay(title, tr("UI_RESULT_BEST") % best_score, tr("UI_RESULT_FOOTER"))
	result_score_label.visible = true
	result_score_value.visible = true
	result_score_value.text = "%09d" % score
	overlay_body.position.y = 300.0

func _reset_overlay_layout() -> void:
	reward_container.visible = false
	volume_rows.visible = false
	reward_anim_timer = 0.0
	reward_anim_duration = 0.0
	overlay_body.position = Vector2(34.0, 180.0)
	overlay_body.size = Vector2(SHEET_RECT.size.x - 68.0, 250.0)
	overlay_body.add_theme_font_size_override("font_size", 18)
	result_score_label.visible = false
	result_score_value.visible = false
	if not overlay.visible or sheet_rise_timer <= 0.0:
		sheet_rise_timer = SHEET_RISE_TIME
	overlay_body.modulate.a = 1.0
	overlay_footer.modulate.a = 1.0

func set_overlay(header: String, body: String, footer: String) -> void:
	_reset_overlay_layout()
	overlay.visible = true
	overlay_header.text = header
	UiTheme.fit_line(overlay_header, 72, 32, SHEET_RECT.size.x - 68.0)
	overlay_body.text = body
	UiTheme.fit_wrapped(overlay_body, 18, 12)
	overlay_footer.text = footer
	UiTheme.fit_wrapped(overlay_footer, 15, 11)
	dialogue_container.visible = false

func show_reward_selection(title: String, subtitle: String, options: Array, selected_index: int, refreshes_left := 0, locked := false, restart_anim := false) -> void:
	var was_open: bool = overlay.visible
	_reset_overlay_layout()
	if was_open:
		sheet_rise_timer = 0.0
	overlay.visible = true
	overlay_header.text = title
	UiTheme.fit_line(overlay_header, 64, 30, SHEET_RECT.size.x - 68.0)
	overlay_body.position = Vector2(34.0, 150.0)
	overlay_body.size = Vector2(SHEET_RECT.size.x - 68.0, 50.0)
	overlay_body.text = subtitle
	UiTheme.fit_wrapped(overlay_body, 16, 11)
	reward_container.visible = true
	if restart_anim:
		reward_anim_duration = 0.34
		reward_anim_timer = reward_anim_duration
	for card_index in range(reward_cards.size()):
		var card_nodes: Dictionary = reward_cards[card_index]
		var active: bool = card_index < options.size()
		card_nodes["root"].visible = active
		if not active:
			continue
		var option: Dictionary = options[card_index]
		var rarity_color: Color = option.get("rarity_color", UiTheme.GOLD)
		var accent_color: Color = option.get("accent_color", rarity_color)
		var selected: bool = card_index == selected_index
		card_nodes["selection"].visible = selected
		card_nodes["frame"].color = accent_color.darkened(0.25)
		card_nodes["rarity"].text = str(option.get("rarity_label", "COMMON"))
		card_nodes["rarity"].add_theme_color_override("font_color", rarity_color.darkened(0.5))
		card_nodes["title"].text = str(option.get("label", tr("UI_UPGRADE")))
		UiTheme.fit_wrapped(card_nodes["title"], 19, 13)
		card_nodes["desc"].text = str(option.get("description", ""))
		UiTheme.fit_wrapped(card_nodes["desc"], 14, 10)
		card_nodes["detail"].text = str(option.get("detail", ""))
		card_nodes["detail"].add_theme_color_override("font_color", accent_color.darkened(0.55))
		UiTheme.fit_wrapped(card_nodes["detail"], 12, 9)
	overlay_footer.text = tr("UI_REWARD_REVEALING") if locked else (tr("UI_REWARD_FOOTER") % refreshes_left)
	UiTheme.fit_wrapped(overlay_footer, 15, 11)
	dialogue_container.visible = false
	_update_reward_card_animation()

func _update_reward_card_animation() -> void:
	var reveal := 1.0
	if reward_anim_duration > 0.0:
		reveal = clamp(1.0 - reward_anim_timer / max(reward_anim_duration, 0.0001), 0.0, 1.0)
		reveal = reveal * reveal * (3.0 - 2.0 * reveal)
	for card_data_variant in reward_cards:
		var card_data: Dictionary = card_data_variant
		var root_card: Control = card_data["root"]
		if not root_card.visible:
			continue
		var base_position: Vector2 = card_data["base_pos"]
		var lift: float = -8.0 if card_data["selection"].visible else 0.0
		root_card.position = Vector2(base_position.x, base_position.y + lift + (1.0 - reveal) * 24.0)
		root_card.modulate.a = reveal
	overlay_body.modulate.a = 0.35 + 0.65 * reveal
	overlay_footer.modulate.a = 0.35 + 0.65 * reveal

func show_banner(title: String, subtitle: String) -> void:
	banner_title.text = title
	UiTheme.fit_line(banner_title, 32, 18, playfield_rect.size.x - 24.0)
	banner_subtitle.text = subtitle
	UiTheme.fit_line(banner_subtitle, 17, 12, playfield_rect.size.x - 24.0)
	banner_title.size.x = playfield_rect.size.x
	banner_subtitle.size.x = playfield_rect.size.x
	banner_timer = banner_duration
	banner_title.visible = true
	banner_subtitle.visible = subtitle != ""
	banner_title.modulate.a = 0.0
	banner_subtitle.modulate.a = 0.0

func begin_dialogue(scene: Dictionary) -> void:
	dialogue_container.visible = true
	dialogue_active = false
	overlay.visible = false
	var cast: Dictionary = scene.get("cast", {})
	for side in ["left", "right"]:
		var portrait = dialogue_left_portrait if side == "left" else dialogue_right_portrait
		portrait.visible = cast.has(side)
		if portrait.visible:
			var config: Dictionary = cast[side].duplicate()
			config["figure"] = "maiden" if side == "left" else "sovereign"
			portrait.configure(config)

func show_dialogue_line(line: Dictionary, current_index: int, total: int) -> void:
	dialogue_active = true
	dialogue_name.text = str(line.get("speaker", ""))
	dialogue_full_text = str(line.get("text", ""))
	dialogue_visible_count = 0
	dialogue_text.text = ""
	dialogue_index_label.text = "%d / %d" % [current_index, total]
	var side := str(line.get("side", "left"))
	var speaker_color: Color = line.get("speaker_color", UiTheme.GOLD)
	dialogue_name.add_theme_color_override("font_color", speaker_color.darkened(0.62))
	var active_tint := Color(1.0, 1.0, 1.0, 1.0)
	var idle_tint := Color(0.6, 0.6, 0.66, 0.55)
	dialogue_left_portrait.modulate = active_tint if side == "left" else idle_tint
	dialogue_right_portrait.modulate = idle_tint if side == "left" else active_tint
	if line.has("portrait_update"):
		(dialogue_left_portrait if side == "left" else dialogue_right_portrait).configure(line["portrait_update"])

func is_dialogue_fully_revealed() -> bool:
	return dialogue_visible_count >= dialogue_full_text.length()

func reveal_dialogue_line() -> void:
	dialogue_visible_count = dialogue_full_text.length()
	dialogue_text.text = dialogue_full_text

func end_dialogue() -> void:
	dialogue_container.visible = false
	dialogue_active = false
	dialogue_full_text = ""
	dialogue_text.text = ""

func show_boss_spotlight(config: Dictionary, duration := 2.4) -> void:
	var accent: Color = config.get("accent_color", UiTheme.GOLD)
	var secondary: Color = config.get("secondary_color", UiTheme.VERDIGRIS)
	var portrait_side: String = str(config.get("portrait_side", "right"))
	spotlight_container.visible = true
	spotlight_container.modulate.a = 0.0
	spotlight_container.position = Vector2(playfield_rect.position.x + 12.0, 96.0) if portrait_side == "left" else Vector2(playfield_rect.end.x - spotlight_container.size.x - 12.0, 96.0)
	spotlight_duration = duration
	spotlight_timer = duration
	# brush hand only for CJK; Latin names stay in the serif so they keep their size
	spotlight_title.add_theme_font_override("font", UiTheme.BrushFont if I18n.current_locale() == I18n.LOCALE_ZH else UiTheme.SerifFont)
	spotlight_title.text = str(config.get("name", tr("UI_BOSS")))
	UiTheme.fit_line(spotlight_title, 30, 11, 232.0)
	spotlight_subtitle.text = str(config.get("subtitle", ""))
	UiTheme.fit_wrapped(spotlight_subtitle, 13, 10)
	spotlight_quote.text = str(config.get("quote", ""))
	spotlight_quote.visible = spotlight_quote.text != ""
	UiTheme.fit_wrapped(spotlight_quote, 14, 10)
	spotlight_portrait.configure({
		"figure": "sovereign",
		"accent_color": accent,
		"secondary_color": secondary,
		"side": portrait_side,
		"mood": config.get("mood", "calm"),
		"motif": config.get("motif", "ribbon"),
	})

func _refresh_language_ui() -> void:
	ofuda.refresh_language()
	var signature: Label = title_container.get_meta("signature")
	var inscription := tr("UI_BRAND_SUB")
	if TranslationServer.get_locale().begins_with("zh"):
		# CJK is set truly vertical, one character per line
		signature.rotation = 0.0
		signature.position = SIGNATURE_POS
		signature.text = "\n".join(inscription.split(""))
		signature.size = Vector2(30.0, 160.0)
	else:
		signature.rotation = PI * 0.5
		signature.position = SIGNATURE_POS + Vector2(24.0, 0.0)
		signature.text = inscription
		signature.size = Vector2(230.0, 30.0)
		UiTheme.fit_line(signature, 20, 12, 230.0)
