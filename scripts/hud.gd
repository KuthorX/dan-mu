extends CanvasLayer

const ColorFx = preload("res://scripts/color_fx.gd")
const TitleArtScript = preload("res://scripts/title_art.gd")
const PortraitViewScript = preload("res://scripts/portrait_view.gd")
const DefaultUIFont = preload("res://fonts/NotoSansCJKsc-Regular.otf")
const I18n = preload("res://scripts/i18n.gd")

signal language_toggle_requested

var playfield_rect := Rect2(24.0, 24.0, 560.0, 912.0)
var window_size := Vector2i(960, 960)
var root: Control
var overlay: ColorRect
var overlay_header: Label
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
var score_value: Label
var best_score_value: Label
var lives_value: Label
var bombs_value: Label
var power_value: Label
var graze_value: Label
var stage_value: Label
var state_value: Label
var menu_board_header: Label
var menu_board_body: Label
var boss_label: Label
var boss_bar: ProgressBar
var boss_multi_container: Control
var boss_multi_rows: Array = []
var banner_title: Label
var banner_subtitle: Label
var banner_timer := 0.0
var banner_duration := 2.7
var title_container: Control
var title_art
var title_logo: Label
var title_subtitle: Label
var title_best: Label
var title_hint: Label
var title_ship_label: Label
var title_ship_description: Label
var title_mode_label: Label
var title_mode_description: Label
var title_controls: Label
var language_button: Button
var side_title: Label
var difficulty_labels: Array = []
var title_anim_time := 0.0
var dialogue_container: Control
var dialogue_name: Label
var dialogue_text: Label
var dialogue_hint: Label
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
var spotlight_phase: Label
var spotlight_quote: Label
var spotlight_portrait
var spotlight_timer := 0.0
var spotlight_duration := 0.0

func setup(rect: Rect2, viewport_size: Vector2i):
	playfield_rect = rect
	window_size = viewport_size
	return self

func _ready() -> void:
	layer = 10
	_build_ui()

func _process(delta: float) -> void:
	title_anim_time += delta
	if title_container.visible:
		title_logo.position.y = 112.0 + sin(title_anim_time * 1.2) * 7.0
		title_logo.modulate = Color(0.92, 0.98, 1.0, 0.92 + sin(title_anim_time * 2.4) * 0.08)
		title_subtitle.modulate = Color(0.68, 0.9, 1.0, 0.82 + sin(title_anim_time * 1.6) * 0.12)
		title_ship_label.modulate = Color(1.0, 0.9, 0.66, 0.9 + sin(title_anim_time * 3.2) * 0.08)
	for index in range(difficulty_labels.size()):
		var row: Label = difficulty_labels[index]
		if row.visible:
			row.position.x = 294.0 + (sin(title_anim_time * 5.0) * 5.0 if index == _current_title_selection_index() else 0.0)
	if banner_timer > 0.0:
		banner_timer = max(0.0, banner_timer - delta)
		var fade_in: float = clamp((banner_duration - banner_timer) / 0.28, 0.0, 1.0)
		var fade_out: float = clamp(banner_timer / 0.5, 0.0, 1.0)
		var alpha: float = min(fade_in, fade_out)
		banner_title.modulate.a = alpha
		banner_subtitle.modulate.a = alpha * 0.92
		banner_title.visible = alpha > 0.01
		banner_subtitle.visible = alpha > 0.01
	else:
		banner_title.visible = false
		banner_subtitle.visible = false
	if flash_timer > 0.0:
		flash_timer = max(0.0, flash_timer - delta)
		var ratio: float = 1.0 - flash_timer / max(flash_duration, 0.0001)
		var flash_color: Color = flash_rect.color
		flash_color.a = sin(ratio * PI) * flash_peak_alpha
		flash_rect.color = flash_color
		flash_rect.visible = flash_color.a > 0.001
	else:
		flash_rect.visible = false
	if dialogue_active and dialogue_visible_count < dialogue_full_text.length():
		dialogue_visible_count = min(dialogue_full_text.length(), dialogue_visible_count + int(delta * dialogue_typing_speed) + 1)
		dialogue_text.text = dialogue_full_text.substr(0, dialogue_visible_count)
	if spotlight_timer > 0.0:
		spotlight_timer = max(0.0, spotlight_timer - delta)
		var spotlight_ratio: float = clamp(spotlight_timer / max(spotlight_duration, 0.0001), 0.0, 1.0)
		spotlight_container.modulate.a = min(1.0, sin((1.0 - spotlight_ratio) * PI) * 1.2)
		spotlight_container.visible = spotlight_container.modulate.a > 0.02
	else:
		spotlight_container.visible = false
	if reward_container.visible:
		if reward_anim_timer > 0.0:
			reward_anim_timer = max(0.0, reward_anim_timer - delta)
		_update_reward_card_animation()

func _build_ui() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var side_panel := ColorRect.new()
	side_panel.position = Vector2(612.0, 18.0)
	side_panel.size = Vector2(330.0, 924.0)
	side_panel.color = Color(0.04, 0.05, 0.10, 0.92)
	root.add_child(side_panel)

	var side_glow := ColorRect.new()
	side_glow.position = Vector2(606.0, 18.0)
	side_glow.size = Vector2(4.0, 924.0)
	side_glow.color = Color(0.45, 0.92, 1.0, 0.65)
	root.add_child(side_glow)

	side_title = _make_label("UI_SIDE_TITLE", Vector2(634.0, 34.0), 34, Color(0.88, 0.96, 1.0), 250.0)
	root.add_child(side_title)

	score_value = _make_stat_row("UI_STAT_SCORE", 142.0)
	best_score_value = _make_stat_row("UI_STAT_BEST", 190.0)
	lives_value = _make_stat_row("UI_STAT_LIVES", 238.0)
	bombs_value = _make_stat_row("UI_STAT_BOMBS", 286.0)
	power_value = _make_stat_row("UI_STAT_POWER", 334.0)
	graze_value = _make_stat_row("UI_STAT_GRAZE", 382.0)
	stage_value = _make_stat_row("UI_STAT_STAGE", 430.0)
	state_value = _make_stat_row("UI_STAT_STATE", 478.0)

	var guide := _make_label(
		"UI_GUIDE",
		Vector2(634.0, 604.0),
		17,
		Color(0.88, 0.90, 1.0),
		268.0
	)
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide.size.y = 320.0
	root.add_child(guide)
	guide.visible = false
	menu_board_header = _make_label("UI_MODE_INFO", Vector2(634.0, 604.0), 20, Color(1.0, 0.9, 0.68), 250.0)
	root.add_child(menu_board_header)
	menu_board_header.visible = false
	menu_board_body = _make_label("", Vector2(634.0, 636.0), 16, Color(0.84, 0.92, 1.0), 268.0)
	menu_board_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	menu_board_body.size.y = 260.0
	root.add_child(menu_board_body)
	menu_board_body.visible = false

	title_container = Control.new()
	title_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(title_container)
	title_art = TitleArtScript.new()
	title_art.position = Vector2(50.0, 30.0)
	title_art.size = Vector2(500.0, 380.0)
	title_container.add_child(title_art)
	title_logo = _make_label("UI_TITLE_LOGO", Vector2(120.0, 112.0), 56, Color(0.92, 0.98, 1.0), 360.0, HORIZONTAL_ALIGNMENT_CENTER)
	title_container.add_child(title_logo)
	title_subtitle = _make_label("UI_TITLE_SUBTITLE", Vector2(114.0, 176.0), 20, Color(0.68, 0.9, 1.0), 370.0, HORIZONTAL_ALIGNMENT_CENTER)
	title_container.add_child(title_subtitle)
	title_best = _make_label("", Vector2(124.0, 222.0), 18, Color(1.0, 0.92, 0.72), 350.0, HORIZONTAL_ALIGNMENT_CENTER)
	title_container.add_child(title_best)
	var difficulty_box := ColorRect.new()
	difficulty_box.position = Vector2(108.0, 276.0)
	difficulty_box.size = Vector2(396.0, 162.0)
	difficulty_box.color = Color(0.06, 0.08, 0.14, 0.32)
	title_container.add_child(difficulty_box)
	var difficulty_header := _make_label("UI_SELECT_DIFFICULTY", Vector2(150.0, 286.0), 22, Color(0.88, 0.96, 1.0), 300.0, HORIZONTAL_ALIGNMENT_CENTER)
	title_container.add_child(difficulty_header)
	for index in range(4):
		var row := _make_label("", Vector2(250.0, 322.0 + float(index) * 30.0), 24, Color(0.72, 0.84, 1.0), 220.0, HORIZONTAL_ALIGNMENT_CENTER)
		difficulty_labels.append(row)
		title_container.add_child(row)
	title_hint = _make_label("UI_TITLE_HINT_DEFAULT", Vector2(118.0, 480.0), 17, Color(0.84, 0.94, 1.0), 360.0, HORIZONTAL_ALIGNMENT_CENTER)
	title_container.add_child(title_hint)
	title_hint.position = Vector2(92.0, 748.0)
	title_hint.size.x = 420.0
	title_hint.size.y = 28.0
	var ship_box := ColorRect.new()
	ship_box.position = Vector2(108.0, 450.0)
	ship_box.size = Vector2(396.0, 136.0)
	ship_box.color = Color(0.06, 0.08, 0.14, 0.32)
	title_container.add_child(ship_box)
	var ship_header := _make_label("UI_SELECT_SHIP", Vector2(150.0, 474.0), 22, Color(0.88, 0.96, 1.0), 300.0, HORIZONTAL_ALIGNMENT_CENTER)
	title_container.add_child(ship_header)
	title_ship_label = _make_label("", Vector2(106.0, 506.0), 28, Color(1.0, 0.9, 0.66), 388.0, HORIZONTAL_ALIGNMENT_CENTER)
	title_container.add_child(title_ship_label)
	title_ship_description = _make_label("", Vector2(104.0, 546.0), 18, Color(0.82, 0.92, 1.0), 392.0, HORIZONTAL_ALIGNMENT_CENTER)
	title_ship_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_ship_description.size.y = 54.0
	title_container.add_child(title_ship_description)
	var mode_box := ColorRect.new()
	mode_box.position = Vector2(108.0, 596.0)
	mode_box.size = Vector2(396.0, 124.0)
	mode_box.color = Color(0.06, 0.08, 0.14, 0.32)
	title_container.add_child(mode_box)
	var mode_header := _make_label("UI_SELECT_MODE", Vector2(150.0, 606.0), 22, Color(0.88, 0.96, 1.0), 300.0, HORIZONTAL_ALIGNMENT_CENTER)
	title_container.add_child(mode_header)
	title_mode_label = _make_label("", Vector2(106.0, 636.0), 24, Color(0.84, 0.94, 1.0), 388.0, HORIZONTAL_ALIGNMENT_CENTER)
	title_container.add_child(title_mode_label)
	title_mode_description = _make_label("", Vector2(106.0, 668.0), 18, Color(0.8, 0.9, 1.0), 388.0, HORIZONTAL_ALIGNMENT_CENTER)
	title_mode_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_mode_description.size.y = 46.0
	title_container.add_child(title_mode_description)
	title_controls = _make_label("UI_TITLE_CONTROLS", Vector2(98.0, 782.0), 18, Color(0.84, 0.92, 1.0), 408.0, HORIZONTAL_ALIGNMENT_CENTER)
	title_controls.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_controls.size.y = 106.0
	title_container.add_child(title_controls)
	language_button = Button.new()
	language_button.position = Vector2(playfield_rect.end.x - 168.0, playfield_rect.position.y + 10.0)
	language_button.size = Vector2(158.0, 34.0)
	language_button.focus_mode = Control.FOCUS_NONE
	language_button.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	language_button.add_theme_font_override("font", DefaultUIFont)
	language_button.add_theme_font_size_override("font_size", 16)
	language_button.pressed.connect(func() -> void: language_toggle_requested.emit())
	title_container.add_child(language_button)
	_refresh_language_ui()

	boss_label = _make_label("", Vector2(playfield_rect.position.x, 8.0), 22, Color(1.0, 0.9, 0.62), playfield_rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(boss_label)
	boss_label.visible = false

	boss_bar = ProgressBar.new()
	boss_bar.position = Vector2(playfield_rect.position.x + 24.0, 42.0)
	boss_bar.size = Vector2(playfield_rect.size.x - 48.0, 18.0)
	boss_bar.show_percentage = false
	boss_bar.visible = false
	root.add_child(boss_bar)
	boss_multi_container = Control.new()
	boss_multi_container.position = Vector2(playfield_rect.position.x + 22.0, 8.0)
	boss_multi_container.size = Vector2(playfield_rect.size.x - 44.0, 92.0)
	boss_multi_container.visible = false
	root.add_child(boss_multi_container)
	for row_index in range(2):
		var row := Control.new()
		row.position = Vector2(float(row_index) * 258.0, 0.0)
		row.size = Vector2(248.0, 44.0)
		boss_multi_container.add_child(row)
		var accent := ColorRect.new()
		accent.position = Vector2.ZERO
		accent.size = Vector2(248.0, 5.0)
		accent.color = Color(0.62, 0.96, 1.0, 0.9)
		row.add_child(accent)
		var side_bar := ColorRect.new()
		if row_index == 0:
			side_bar.position = Vector2(0.0, 8.0)
		else:
			side_bar.position = Vector2(242.0, 8.0)
		side_bar.size = Vector2(6.0, 30.0)
		row.add_child(side_bar)
		var label := _make_label("", Vector2(10.0, 6.0), 15, Color(1.0, 0.9, 0.62), 228.0, HORIZONTAL_ALIGNMENT_LEFT if row_index == 0 else HORIZONTAL_ALIGNMENT_RIGHT)
		row.add_child(label)
		var bar := ProgressBar.new()
		bar.position = Vector2(10.0, 24.0)
		bar.size = Vector2(228.0, 10.0)
		bar.show_percentage = false
		row.add_child(bar)
		boss_multi_rows.append({"row": row, "label": label, "bar": bar, "accent": accent, "side_bar": side_bar, "side": "left" if row_index == 0 else "right"})

	banner_title = _make_label("", Vector2(playfield_rect.position.x, playfield_rect.position.y + 280.0), 32, Color(0.95, 0.97, 1.0), playfield_rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	banner_title.visible = false
	root.add_child(banner_title)
	banner_subtitle = _make_label("", Vector2(playfield_rect.position.x, playfield_rect.position.y + 320.0), 18, Color(0.7, 0.92, 1.0), playfield_rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	banner_subtitle.visible = false
	root.add_child(banner_subtitle)

	overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.78)
	overlay.visible = false
	root.add_child(overlay)
	var panel := ColorRect.new()
	panel.position = Vector2(168.0, 220.0)
	panel.size = Vector2(624.0, 440.0)
	panel.color = Color(0.05, 0.06, 0.12, 0.94)
	overlay.add_child(panel)
	var outline_top := ColorRect.new()
	outline_top.position = Vector2(168.0, 220.0)
	outline_top.size = Vector2(624.0, 4.0)
	outline_top.color = Color(0.54, 0.94, 1.0, 0.85)
	overlay.add_child(outline_top)
	overlay_header = _make_label("", Vector2(200.0, 268.0), 38, Color(0.92, 0.98, 1.0), 560.0, HORIZONTAL_ALIGNMENT_CENTER)
	overlay.add_child(overlay_header)
	overlay_body = _make_label("", Vector2(220.0, 336.0), 22, Color(0.84, 0.9, 1.0), 520.0, HORIZONTAL_ALIGNMENT_CENTER)
	overlay_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_body.size.y = 150.0
	overlay.add_child(overlay_body)
	overlay_footer = _make_label("", Vector2(220.0, 492.0), 18, Color(0.62, 0.9, 1.0), 520.0, HORIZONTAL_ALIGNMENT_CENTER)
	overlay_footer.size.y = 90.0
	overlay.add_child(overlay_footer)
	reward_container = Control.new()
	reward_container.position = Vector2(184.0, 392.0)
	reward_container.size = Vector2(592.0, 206.0)
	reward_container.visible = false
	overlay.add_child(reward_container)
	for card_index in range(3):
		var card_root := Control.new()
		card_root.position = Vector2(float(card_index) * 198.0, 0.0)
		card_root.size = Vector2(182.0, 206.0)
		reward_container.add_child(card_root)
		var glow := ColorRect.new()
		glow.position = Vector2(-4.0, -4.0)
		glow.size = Vector2(190.0, 214.0)
		glow.color = Color(0.56, 0.94, 1.0, 0.18)
		glow.visible = false
		card_root.add_child(glow)
		var panel_back := ColorRect.new()
		panel_back.position = Vector2.ZERO
		panel_back.size = Vector2(182.0, 206.0)
		panel_back.color = Color(0.07, 0.08, 0.14, 0.94)
		card_root.add_child(panel_back)
		var accent_bar := ColorRect.new()
		accent_bar.position = Vector2.ZERO
		accent_bar.size = Vector2(182.0, 5.0)
		accent_bar.color = Color(0.62, 0.96, 1.0, 0.9)
		card_root.add_child(accent_bar)
		var rarity_label := _make_label("", Vector2(12.0, 12.0), 12, Color(0.82, 0.92, 1.0), 158.0, HORIZONTAL_ALIGNMENT_RIGHT)
		card_root.add_child(rarity_label)
		var title_label := _make_label("", Vector2(12.0, 24.0), 22, Color(0.98, 0.98, 1.0), 158.0, HORIZONTAL_ALIGNMENT_LEFT)
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_label.size.y = 52.0
		card_root.add_child(title_label)
		var desc_label := _make_label("", Vector2(12.0, 76.0), 15, Color(0.84, 0.9, 1.0), 158.0, HORIZONTAL_ALIGNMENT_LEFT)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.size.y = 72.0
		card_root.add_child(desc_label)
		var detail_label := _make_label("", Vector2(12.0, 152.0), 13, Color(0.7, 0.9, 1.0), 158.0, HORIZONTAL_ALIGNMENT_LEFT)
		detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		detail_label.size.y = 44.0
		card_root.add_child(detail_label)
		reward_cards.append({
			"root": card_root,
			"glow": glow,
			"panel": panel_back,
			"accent": accent_bar,
			"rarity": rarity_label,
			"title": title_label,
			"desc": desc_label,
			"detail": detail_label
		})

	dialogue_container = Control.new()
	dialogue_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	dialogue_container.visible = false
	root.add_child(dialogue_container)
	var dialogue_panel := ColorRect.new()
	dialogue_panel.position = Vector2(54.0, 670.0)
	dialogue_panel.size = Vector2(530.0, 230.0)
	dialogue_panel.color = Color(0.04, 0.05, 0.11, 0.92)
	dialogue_container.add_child(dialogue_panel)
	var dialogue_line := ColorRect.new()
	dialogue_line.position = Vector2(54.0, 670.0)
	dialogue_line.size = Vector2(530.0, 4.0)
	dialogue_line.color = Color(0.62, 0.92, 1.0, 0.88)
	dialogue_container.add_child(dialogue_line)
	dialogue_name = _make_label("", Vector2(84.0, 694.0), 24, Color(1.0, 0.92, 0.72), 300.0)
	dialogue_container.add_child(dialogue_name)
	dialogue_text = _make_label("", Vector2(84.0, 738.0), 22, Color(0.92, 0.96, 1.0), 458.0)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.size.y = 118.0
	dialogue_container.add_child(dialogue_text)
	dialogue_hint = _make_label("UI_DIALOGUE_NEXT", Vector2(388.0, 858.0), 18, Color(0.62, 0.88, 1.0), 154.0, HORIZONTAL_ALIGNMENT_RIGHT)
	dialogue_container.add_child(dialogue_hint)
	dialogue_index_label = _make_label("", Vector2(84.0, 856.0), 18, Color(0.68, 0.86, 1.0), 100.0)
	dialogue_container.add_child(dialogue_index_label)
	dialogue_left_portrait = PortraitViewScript.new()
	dialogue_left_portrait.position = Vector2(12.0, 428.0)
	dialogue_left_portrait.size = Vector2(236.0, 284.0)
	dialogue_left_portrait.visible = false
	dialogue_container.add_child(dialogue_left_portrait)
	dialogue_right_portrait = PortraitViewScript.new()
	dialogue_right_portrait.position = Vector2(348.0, 404.0)
	dialogue_right_portrait.size = Vector2(248.0, 310.0)
	dialogue_right_portrait.visible = false
	dialogue_container.add_child(dialogue_right_portrait)

	spotlight_container = Control.new()
	spotlight_container.position = Vector2(316.0, 120.0)
	spotlight_container.size = Vector2(270.0, 364.0)
	spotlight_container.visible = false
	root.add_child(spotlight_container)
	var spot_back := ColorRect.new()
	spot_back.position = Vector2.ZERO
	spot_back.size = Vector2(270.0, 364.0)
	spot_back.color = Color(0.05, 0.06, 0.12, 0.84)
	spotlight_container.add_child(spot_back)
	var spot_line := ColorRect.new()
	spot_line.position = Vector2(0.0, 0.0)
	spot_line.size = Vector2(270.0, 4.0)
	spot_line.color = Color(0.96, 0.88, 0.62, 0.88)
	spotlight_container.add_child(spot_line)
	spotlight_phase = _make_label("", Vector2(16.0, 10.0), 18, Color(1.0, 0.88, 0.62), 238.0, HORIZONTAL_ALIGNMENT_CENTER)
	spotlight_container.add_child(spotlight_phase)
	spotlight_portrait = PortraitViewScript.new()
	spotlight_portrait.position = Vector2(12.0, 34.0)
	spotlight_portrait.size = Vector2(246.0, 188.0)
	spotlight_container.add_child(spotlight_portrait)
	spotlight_title = _make_label("", Vector2(16.0, 226.0), 22, Color(1.0, 0.92, 0.72), 238.0, HORIZONTAL_ALIGNMENT_CENTER)
	spotlight_container.add_child(spotlight_title)
	spotlight_subtitle = _make_label("", Vector2(16.0, 256.0), 16, Color(0.72, 0.92, 1.0), 238.0, HORIZONTAL_ALIGNMENT_CENTER)
	spotlight_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	spotlight_subtitle.size.y = 46.0
	spotlight_container.add_child(spotlight_subtitle)
	spotlight_quote = _make_label("", Vector2(18.0, 302.0), 14, Color(0.94, 0.96, 1.0), 234.0, HORIZONTAL_ALIGNMENT_CENTER)
	spotlight_quote.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	spotlight_quote.size.y = 58.0
	spotlight_container.add_child(spotlight_quote)

	flash_rect = ColorRect.new()
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.color = Color(1.0, 1.0, 1.0, 0.0)
	flash_rect.visible = false
	root.add_child(flash_rect)

func _make_label(text: String, pos: Vector2, font_size: int, color: Color, width := 200.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = Vector2(width, 64.0)
	label.horizontal_alignment = align
	label.add_theme_font_override("font", DefaultUIFont)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _make_stat_row(title: String, y: float) -> Label:
	var key := _make_label(title, Vector2(634.0, y), 16, Color(0.62, 0.82, 1.0), 98.0)
	root.add_child(key)
	var value := _make_label("-", Vector2(758.0, y - 4.0), 24, Color(0.96, 0.97, 1.0), 150.0)
	root.add_child(value)
	return value

func set_status(status: Dictionary) -> void:
	score_value.text = "%09d" % int(status.get("score", 0))
	best_score_value.text = "%09d" % int(status.get("best_score", 0))
	lives_value.text = "x %d" % int(status.get("lives", 0))
	bombs_value.text = "x %d" % int(status.get("bombs", 0))
	power_value.text = "%d / %d" % [int(status.get("power", 0)), int(status.get("power_max", 100))]
	graze_value.text = "%d" % int(status.get("graze", 0))
	stage_value.text = str(status.get("stage_text", ""))
	state_value.text = str(status.get("state_text", ""))

func set_boss_state(visible: bool, current_hp: float, max_hp_value: float, phase_name: String) -> void:
	boss_multi_container.visible = false
	boss_label.visible = visible
	boss_bar.visible = visible
	if not visible:
		return
	boss_label.text = phase_name
	_fit_label_font(boss_label, 22, 14, playfield_rect.size.x)
	boss_bar.max_value = max(1.0, max_hp_value)
	boss_bar.value = clamp(current_hp, 0.0, max_hp_value)

func set_boss_states(states: Array) -> void:
	if states.is_empty():
		boss_multi_container.visible = false
		set_boss_state(false, 0.0, 1.0, "")
		return
	if states.size() == 1:
		var state: Dictionary = states[0]
		set_boss_state(true, float(state.get("hp", 0.0)), float(state.get("max_hp", 1.0)), str(state.get("phase_name", tr("UI_BOSS"))))
		return
	boss_label.visible = false
	boss_bar.visible = false
	boss_multi_container.visible = true
	for row_index in range(boss_multi_rows.size()):
		var row_data: Dictionary = boss_multi_rows[row_index]
		var visible: bool = row_index < states.size()
		row_data["row"].visible = visible
		if not visible:
			continue
		var state: Dictionary = states[row_index]
		var accent_color: Color = state.get("accent_color", Color(0.62, 0.96, 1.0))
		row_data["label"].text = str(state.get("phase_name", tr("UI_BOSS_N") % (row_index + 1)))
		row_data["label"].add_theme_color_override("font_color", Color(1.0, 0.96, 0.9) if row_data["side"] == "left" else Color(0.9, 0.98, 1.0))
		row_data["accent"].color = Color(accent_color.r, accent_color.g, accent_color.b, 0.95)
		row_data["side_bar"].color = Color(accent_color.r, accent_color.g, accent_color.b, 0.95)
		row_data["bar"].max_value = max(1.0, float(state.get("max_hp", 1.0)))
		row_data["bar"].value = clamp(float(state.get("hp", 0.0)), 0.0, float(state.get("max_hp", 1.0)))

func flash(color: Color, alpha := 0.6, duration := 0.25) -> void:
	flash_rect.color = ColorFx.alpha(color, alpha)
	flash_peak_alpha = alpha
	flash_duration = duration
	flash_timer = duration
	flash_rect.visible = true

func show_title(best_score: int, difficulty_names := [], selected_index := 1, ship_label := "", ship_description := "", mode_label := "", mode_description := "", board_title := "", board_body := "") -> void:
	overlay.visible = false
	dialogue_container.visible = false
	title_container.visible = true
	menu_board_header.visible = true
	menu_board_body.visible = true
	title_best.text = tr("UI_TITLE_BEST") % best_score
	if difficulty_names.is_empty():
		difficulty_names = [tr("DIFF_EASY"), tr("DIFF_NORMAL"), tr("DIFF_HARD"), tr("DIFF_LUNATIC")]
	_refresh_language_ui()
	_update_title_menu(difficulty_names, selected_index, ship_label, ship_description, mode_label, mode_description, board_title, board_body)

func update_title_difficulty(difficulty_names: Array, selected_index: int) -> void:
	_update_title_menu(difficulty_names, selected_index, title_ship_label.text.replace("< ", "").replace(" >", ""), title_ship_description.text, title_mode_label.text.replace("< ", "").replace(" >", ""), title_mode_description.text, menu_board_header.text, menu_board_body.text)

func update_title_menu(difficulty_names: Array, selected_index: int, ship_label := "", ship_description := "", mode_label := "", mode_description := "", board_title := "", board_body := "") -> void:
	_update_title_menu(difficulty_names, selected_index, ship_label, ship_description, mode_label, mode_description, board_title, board_body)

func _update_title_menu(difficulty_names: Array, selected_index: int, ship_label: String, ship_description: String, mode_label: String, mode_description: String, board_title: String, board_body: String) -> void:
	for index in range(difficulty_labels.size()):
		var label: Label = difficulty_labels[index]
		if index < difficulty_names.size():
			var selected := index == selected_index
			label.visible = true
			label.text = ("> " if selected else "  ") + str(difficulty_names[index])
			label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6) if selected else Color(0.72, 0.84, 1.0))
			label.add_theme_font_size_override("font_size", 28 if selected else 24)
		else:
			label.visible = false
	title_art.set_palette(Color(0.56 + float(selected_index) * 0.08, 0.88, 1.0), Color(1.0, 0.74, 0.46 + 0.08 * float(selected_index)))
	title_ship_label.text = "< %s >" % ship_label
	title_ship_description.text = ship_description
	title_mode_label.text = "< %s >" % mode_label
	title_mode_description.text = mode_description
	menu_board_header.text = board_title
	menu_board_body.text = board_body
	title_hint.text = tr("UI_TITLE_HINT") % difficulty_names[selected_index]
	_fit_label_font(title_hint, 17, 12, 420.0)
	title_container.set_meta("selected_index", selected_index)

func _current_title_selection_index() -> int:
	return int(title_container.get_meta("selected_index", 0))

func hide_title() -> void:
	title_container.visible = false
	menu_board_header.visible = false
	menu_board_body.visible = false

func show_pause() -> void:
	set_overlay(tr("UI_PAUSED"), tr("UI_PAUSED_BODY"), tr("UI_PAUSED_FOOTER"))

func show_stage_transition(stage_number: int, title: String, subtitle: String) -> void:
	set_overlay(tr("UI_STAGE_N") % stage_number, "%s\n\n%s" % [title, subtitle], tr("UI_STAGE_TRANSITION_FOOTER"))

func hide_overlay() -> void:
	overlay.visible = false

func show_result(victory: bool, score: int, best_score: int) -> void:
	var title := tr("UI_GAME_OVER")
	if victory:
		title = tr("UI_ALL_CLEAR")
	var body := tr("UI_RESULT_SCORES") % [score, best_score]
	if victory:
		body += "\n\n" + tr("UI_RESULT_VICTORY")
	else:
		body += "\n\n" + tr("UI_RESULT_DEFEAT")
	set_overlay(title, body, tr("UI_RESULT_FOOTER"))

func _reset_overlay_layout() -> void:
	reward_container.visible = false
	reward_anim_timer = 0.0
	reward_anim_duration = 0.0
	overlay_header.position = Vector2(200.0, 268.0)
	overlay_header.size = Vector2(560.0, 64.0)
	overlay_header.add_theme_font_size_override("font_size", 38)
	overlay_body.position = Vector2(220.0, 336.0)
	overlay_body.size = Vector2(520.0, 150.0)
	overlay_body.add_theme_font_size_override("font_size", 22)
	overlay_body.visible = true
	overlay_footer.position = Vector2(220.0, 492.0)
	overlay_footer.size = Vector2(520.0, 90.0)
	overlay_footer.add_theme_font_size_override("font_size", 18)
	overlay_footer.visible = true

func set_overlay(header: String, body: String, footer: String) -> void:
	overlay.visible = true
	_reset_overlay_layout()
	overlay_header.text = header
	_fit_label_font(overlay_header, 38, 22, 560.0)
	overlay_body.text = body
	overlay_footer.text = footer
	dialogue_container.visible = false

func show_reward_selection(title: String, subtitle: String, options: Array, selected_index: int, refreshes_left := 0, locked := false, restart_anim := false) -> void:
	overlay.visible = true
	_reset_overlay_layout()
	overlay_header.text = title
	_fit_label_font(overlay_header, 38, 22, 560.0)
	overlay_body.position = Vector2(206.0, 338.0)
	overlay_body.size = Vector2(548.0, 54.0)
	overlay_body.add_theme_font_size_override("font_size", 18)
	overlay_body.text = subtitle
	_fit_label_font(overlay_body, 18, 13, 548.0)
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
		var rarity_color: Color = option.get("rarity_color", Color(0.62, 0.96, 1.0))
		var accent_color: Color = option.get("accent_color", rarity_color)
		var selected: bool = card_index == selected_index
		card_nodes["glow"].visible = selected
		card_nodes["glow"].color = Color(accent_color.r, accent_color.g, accent_color.b, 0.22 if selected else 0.0)
		card_nodes["panel"].color = Color(0.09, 0.1, 0.16, 0.98) if selected else Color(0.06, 0.07, 0.12, 0.94)
		card_nodes["accent"].color = Color(accent_color.r, accent_color.g, accent_color.b, 0.95)
		card_nodes["rarity"].text = str(option.get("rarity_label", "COMMON"))
		card_nodes["rarity"].add_theme_color_override("font_color", rarity_color)
		card_nodes["title"].text = str(option.get("label", tr("UI_UPGRADE")))
		card_nodes["title"].add_theme_color_override("font_color", Color(1.0, 1.0, 1.0) if selected else Color(0.94, 0.96, 1.0))
		card_nodes["desc"].text = str(option.get("description", ""))
		card_nodes["detail"].text = str(option.get("detail", ""))
		card_nodes["detail"].add_theme_color_override("font_color", Color(accent_color.r, accent_color.g, accent_color.b, 0.92))
	overlay_footer.position = Vector2(206.0, 610.0)
	overlay_footer.size = Vector2(548.0, 64.0)
	overlay_footer.text = tr("UI_REWARD_REVEALING") if locked else (tr("UI_REWARD_FOOTER") % refreshes_left)
	dialogue_container.visible = false
	_update_reward_card_animation()

func _update_reward_card_animation() -> void:
	var reveal := 1.0
	if reward_anim_duration > 0.0:
		reveal = 1.0 - reward_anim_timer / max(reward_anim_duration, 0.0001)
		reveal = clamp(reveal, 0.0, 1.0)
		reveal = reveal * reveal * (3.0 - 2.0 * reveal)
	for card_data_variant in reward_cards:
		var card_data: Dictionary = card_data_variant
		var root_card: Control = card_data["root"]
		if not root_card.visible:
			continue
		var base_position: Vector2 = Vector2(0.0, 0.0)
		if card_data.has("base_pos"):
			base_position = card_data["base_pos"]
		else:
			base_position = root_card.position
			card_data["base_pos"] = base_position
		root_card.position = Vector2(base_position.x, base_position.y + (1.0 - reveal) * 24.0)
		root_card.modulate.a = reveal
	overlay_body.modulate.a = 0.35 + 0.65 * reveal
	overlay_footer.modulate.a = 0.35 + 0.65 * reveal

func show_banner(title: String, subtitle: String) -> void:
	banner_title.text = title
	_fit_label_font(banner_title, 32, 18, playfield_rect.size.x)
	banner_subtitle.text = subtitle
	_fit_label_font(banner_subtitle, 18, 12, playfield_rect.size.x)
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
	if cast.has("left"):
		dialogue_left_portrait.visible = true
		dialogue_left_portrait.configure(cast["left"])
	else:
		dialogue_left_portrait.visible = false
	if cast.has("right"):
		dialogue_right_portrait.visible = true
		dialogue_right_portrait.configure(cast["right"])
	else:
		dialogue_right_portrait.visible = false

func show_dialogue_line(line: Dictionary, current_index: int, total: int) -> void:
	dialogue_active = true
	dialogue_name.text = str(line.get("speaker", ""))
	dialogue_full_text = str(line.get("text", ""))
	dialogue_visible_count = 0
	dialogue_text.text = ""
	dialogue_index_label.text = "%d / %d" % [current_index, total]
	dialogue_hint.text = "UI_DIALOGUE_NEXT"
	var side := str(line.get("side", "left"))
	var active_color: Color = line.get("speaker_color", Color(1.0, 0.9, 0.72))
	dialogue_name.add_theme_color_override("font_color", active_color)
	if side == "left":
		dialogue_left_portrait.modulate = Color(1.0, 1.0, 1.0, 1.0)
		dialogue_right_portrait.modulate = Color(0.72, 0.72, 0.78, 0.45)
	else:
		dialogue_left_portrait.modulate = Color(0.72, 0.72, 0.78, 0.45)
		dialogue_right_portrait.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if line.has("portrait_update"):
		var update: Dictionary = line["portrait_update"]
		if side == "left":
			dialogue_left_portrait.configure(update)
		else:
			dialogue_right_portrait.configure(update)

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
	var accent: Color = config.get("accent_color", Color(1.0, 0.72, 0.5))
	var secondary: Color = config.get("secondary_color", Color(0.56, 0.92, 1.0))
	var portrait_side: String = str(config.get("portrait_side", "right"))
	spotlight_container.visible = true
	spotlight_container.modulate.a = 0.0
	spotlight_container.position = Vector2(36.0, 120.0) if portrait_side == "left" else Vector2(316.0, 120.0)
	spotlight_duration = duration
	spotlight_timer = duration
	spotlight_phase.text = str(config.get("phase_name", ""))
	spotlight_phase.visible = spotlight_phase.text != ""
	spotlight_phase.add_theme_color_override("font_color", ColorFx.alpha(accent.lightened(0.18), 0.96))
	spotlight_title.text = str(config.get("name", tr("UI_BOSS")))
	spotlight_title.add_theme_color_override("font_color", ColorFx.alpha(accent.lightened(0.28), 0.98))
	_fit_label_font(spotlight_title, 22, 14, 238.0)
	_fit_label_font(spotlight_phase, 18, 12, 238.0)
	spotlight_subtitle.text = str(config.get("subtitle", ""))
	spotlight_subtitle.add_theme_color_override("font_color", ColorFx.alpha(secondary.lightened(0.08), 0.94))
	spotlight_quote.text = str(config.get("quote", ""))
	spotlight_quote.visible = spotlight_quote.text != ""
	spotlight_quote.add_theme_color_override("font_color", ColorFx.alpha(Color(0.94, 0.96, 1.0), 0.92))
	spotlight_portrait.configure({
		"accent_color": accent,
		"secondary_color": secondary,
		"side": portrait_side,
		"mood": config.get("mood", "calm"),
		"motif": config.get("motif", "ribbon"),
		"title": spotlight_title.text
	})

func _refresh_language_ui() -> void:
	_fit_label_font(side_title, 34, 20, 250.0)
	if language_button:
		language_button.text = tr("UI_LANGUAGE_TOGGLE_ZH") if I18n.current_locale() == I18n.LOCALE_ZH else tr("UI_LANGUAGE_TOGGLE_EN")

## Shrinks a single-line label's font until its text fits max_width (longer English strings).
## Labels grow to fit their text, so the width is passed explicitly and restored afterwards.
func _fit_label_font(label: Label, base_size: int, min_size: int, max_width: float) -> void:
	var font_size := base_size
	var text := tr(label.text)
	while font_size > min_size and DefaultUIFont.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_width:
		font_size -= 1
	label.add_theme_font_size_override("font_size", font_size)
	label.size = Vector2(max_width, label.size.y)
