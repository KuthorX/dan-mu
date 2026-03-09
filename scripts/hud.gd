extends CanvasLayer

const ColorFx = preload("res://scripts/color_fx.gd")
const TitleArtScript = preload("res://scripts/title_art.gd")
const PortraitViewScript = preload("res://scripts/portrait_view.gd")

var playfield_rect := Rect2(24.0, 24.0, 560.0, 912.0)
var window_size := Vector2i(960, 960)
var root: Control
var overlay: ColorRect
var overlay_header: Label
var overlay_body: Label
var overlay_footer: Label
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
var difficulty_value: Label
var boss_label: Label
var boss_bar: ProgressBar
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
	for index in range(difficulty_labels.size()):
		var row: Label = difficulty_labels[index]
		if row.visible and index == _current_title_selection_index():
			row.position.x = 294.0 + sin(title_anim_time * 5.0) * 5.0
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

	var side_title := _make_label("洛天依的奇妙冒险", Vector2(634.0, 34.0), 34, Color(0.88, 0.96, 1.0), 250.0)
	root.add_child(side_title)

	score_value = _make_stat_row("Score", 142.0)
	best_score_value = _make_stat_row("Best", 190.0)
	lives_value = _make_stat_row("Lives", 238.0)
	bombs_value = _make_stat_row("Bombs", 286.0)
	power_value = _make_stat_row("Power", 334.0)
	graze_value = _make_stat_row("Graze", 382.0)
	stage_value = _make_stat_row("Stage", 430.0)
	state_value = _make_stat_row("State", 478.0)
	difficulty_value = _make_stat_row("Difficulty", 526.0)

	var guide := _make_label(
		"Controls\nZ / Space  Fire / Confirm\nShift      Focus\nX          Bomb\nEsc / P    Pause\n\nMenu\n↑↓ / ←→    Select difficulty\n\nTips\n- 擦弹会稳定涨分\n- 对话中按 Z 可逐句推进\n- 高难度会强化弹速、密度与 Boss 压力",
		Vector2(634.0, 604.0),
		17,
		Color(0.88, 0.90, 1.0),
		268.0
	)
	guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	guide.size.y = 320.0
	root.add_child(guide)

	title_container = Control.new()
	title_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(title_container)
	title_art = TitleArtScript.new()
	title_art.position = Vector2(50.0, 30.0)
	title_art.size = Vector2(500.0, 380.0)
	title_container.add_child(title_art)
	title_logo = _make_label("DANMU", Vector2(120.0, 112.0), 56, Color(0.92, 0.98, 1.0), 360.0, HORIZONTAL_ALIGNMENT_CENTER)
	title_container.add_child(title_logo)
	title_subtitle = _make_label("Boundary Fantasy · Procedural Bullet Opera", Vector2(114.0, 176.0), 20, Color(0.68, 0.9, 1.0), 370.0, HORIZONTAL_ALIGNMENT_CENTER)
	title_container.add_child(title_subtitle)
	title_best = _make_label("", Vector2(124.0, 222.0), 18, Color(1.0, 0.92, 0.72), 350.0, HORIZONTAL_ALIGNMENT_CENTER)
	title_container.add_child(title_best)
	var difficulty_header := _make_label("Select Difficulty", Vector2(150.0, 286.0), 22, Color(0.88, 0.96, 1.0), 300.0, HORIZONTAL_ALIGNMENT_CENTER)
	title_container.add_child(difficulty_header)
	for index in range(4):
		var row := _make_label("", Vector2(294.0, 326.0 + float(index) * 34.0), 24, Color(0.72, 0.84, 1.0), 140.0, HORIZONTAL_ALIGNMENT_LEFT)
		difficulty_labels.append(row)
		title_container.add_child(row)
	title_hint = _make_label("↑↓ / ←→ 选择难度 · Z 开始", Vector2(118.0, 480.0), 20, Color(0.84, 0.94, 1.0), 360.0, HORIZONTAL_ALIGNMENT_CENTER)
	title_container.add_child(title_hint)

	boss_label = _make_label("", Vector2(playfield_rect.position.x, 8.0), 22, Color(1.0, 0.9, 0.62), playfield_rect.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	root.add_child(boss_label)
	boss_label.visible = false

	boss_bar = ProgressBar.new()
	boss_bar.position = Vector2(playfield_rect.position.x + 24.0, 42.0)
	boss_bar.size = Vector2(playfield_rect.size.x - 48.0, 18.0)
	boss_bar.show_percentage = false
	boss_bar.visible = false
	root.add_child(boss_bar)

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
	panel.size = Vector2(624.0, 340.0)
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
	dialogue_name = _make_label("", Vector2(84.0, 694.0), 24, Color(1.0, 0.92, 0.72), 220.0)
	dialogue_container.add_child(dialogue_name)
	dialogue_text = _make_label("", Vector2(84.0, 738.0), 22, Color(0.92, 0.96, 1.0), 458.0)
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.size.y = 118.0
	dialogue_container.add_child(dialogue_text)
	dialogue_hint = _make_label("Z / Space 继续", Vector2(388.0, 858.0), 18, Color(0.62, 0.88, 1.0), 154.0, HORIZONTAL_ALIGNMENT_RIGHT)
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
	spotlight_container.size = Vector2(270.0, 310.0)
	spotlight_container.visible = false
	root.add_child(spotlight_container)
	var spot_back := ColorRect.new()
	spot_back.position = Vector2.ZERO
	spot_back.size = Vector2(270.0, 310.0)
	spot_back.color = Color(0.05, 0.06, 0.12, 0.84)
	spotlight_container.add_child(spot_back)
	spotlight_portrait = PortraitViewScript.new()
	spotlight_portrait.position = Vector2(12.0, 34.0)
	spotlight_portrait.size = Vector2(246.0, 212.0)
	spotlight_container.add_child(spotlight_portrait)
	spotlight_title = _make_label("", Vector2(16.0, 246.0), 22, Color(1.0, 0.92, 0.72), 238.0, HORIZONTAL_ALIGNMENT_CENTER)
	spotlight_container.add_child(spotlight_title)
	spotlight_subtitle = _make_label("", Vector2(16.0, 276.0), 16, Color(0.72, 0.92, 1.0), 238.0, HORIZONTAL_ALIGNMENT_CENTER)
	spotlight_container.add_child(spotlight_subtitle)

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
	power_value.text = "%d / 100" % int(status.get("power", 0))
	graze_value.text = "%d" % int(status.get("graze", 0))
	stage_value.text = str(status.get("stage_text", ""))
	state_value.text = str(status.get("state_text", ""))
	difficulty_value.text = str(status.get("difficulty_text", ""))

func set_boss_state(visible: bool, current_hp: float, max_hp_value: float, phase_name: String) -> void:
	boss_label.visible = visible
	boss_bar.visible = visible
	if not visible:
		return
	boss_label.text = phase_name
	boss_bar.max_value = max(1.0, max_hp_value)
	boss_bar.value = clamp(current_hp, 0.0, max_hp_value)

func flash(color: Color, alpha := 0.6, duration := 0.25) -> void:
	flash_rect.color = ColorFx.alpha(color, alpha)
	flash_peak_alpha = alpha
	flash_duration = duration
	flash_timer = duration
	flash_rect.visible = true

func show_title(best_score: int, difficulty_names := [], selected_index := 1) -> void:
	overlay.visible = false
	dialogue_container.visible = false
	title_container.visible = true
	title_best.text = "Best Score  %09d" % best_score
	if difficulty_names.is_empty():
		difficulty_names = ["Easy", "Normal", "Hard", "Lunatic"]
	_update_title_difficulties(difficulty_names, selected_index)

func update_title_difficulty(difficulty_names: Array, selected_index: int) -> void:
	_update_title_difficulties(difficulty_names, selected_index)

func _update_title_difficulties(difficulty_names: Array, selected_index: int) -> void:
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
	title_hint.text = "↑↓ / ←→ 选择难度 · Z 开始  · 当前：%s" % difficulty_names[selected_index]
	title_container.set_meta("selected_index", selected_index)

func _current_title_selection_index() -> int:
	return int(title_container.get_meta("selected_index", 0))

func hide_title() -> void:
	title_container.visible = false

func show_pause() -> void:
	set_overlay("Paused", "战斗已暂停。\n继续观察弹幕节奏，再选择回到战场。", "按 Esc / Z 继续 · 按 X 回标题")

func show_stage_transition(stage_number: int, title: String, subtitle: String) -> void:
	set_overlay("Stage %d" % stage_number, "%s\n\n%s" % [title, subtitle], "短暂整备后自动进入下一关")

func hide_overlay() -> void:
	overlay.visible = false

func show_result(victory: bool, score: int, best_score: int) -> void:
	var title := "Game Over"
	if victory:
		title = "All Clear"
	var body := "最终得分：%09d\n最高分：%09d" % [score, best_score]
	if victory:
		body += "\n\n你成功突破了两道边界与双 Boss 压制。"
	else:
		body += "\n\n再试一次，把 Bomb 和擦弹利用得更极致。"
	set_overlay(title, body, "按 Z 重新挑战 · 按 Esc 回标题")

func set_overlay(header: String, body: String, footer: String) -> void:
	overlay.visible = true
	overlay_header.text = header
	overlay_body.text = body
	overlay_footer.text = footer
	dialogue_container.visible = false

func show_banner(title: String, subtitle: String) -> void:
	banner_title.text = title
	banner_subtitle.text = subtitle
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
	dialogue_hint.text = "Z / Space 继续"
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
	spotlight_container.visible = true
	spotlight_container.modulate.a = 0.0
	spotlight_duration = duration
	spotlight_timer = duration
	spotlight_title.text = str(config.get("name", "Boss"))
	spotlight_subtitle.text = str(config.get("subtitle", ""))
	spotlight_portrait.configure({
		"accent_color": config.get("accent_color", Color(1.0, 0.72, 0.5)),
		"secondary_color": config.get("secondary_color", Color(0.56, 0.92, 1.0)),
		"side": config.get("portrait_side", "right"),
		"mood": config.get("mood", "calm"),
		"motif": config.get("motif", "ribbon")
	})
