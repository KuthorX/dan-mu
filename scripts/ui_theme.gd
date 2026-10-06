extends RefCounted

## "Night Shrine Ofuda" visual language shared by the HUD, menus and overlays.
## Ink on bone washi for anything on paper; paper-white with an ink keyline for
## anything floating over the playfield, so text never fights the bullets.

const BodyFont = preload("res://fonts/NotoSansCJKsc-Regular.otf")
const SerifFont = preload("res://fonts/NotoSerifSC-Bold-subset.ttf")
const BrushFont = preload("res://fonts/MaShanZheng-subset.ttf")

const INK := Color(0.11, 0.08, 0.08)
const INK_SOFT := Color(0.11, 0.08, 0.08, 0.62)
const INK_FAINT := Color(0.11, 0.08, 0.08, 0.28)
const PAPER := Color(0.93, 0.89, 0.80)
const PAPER_DIM := Color(0.93, 0.89, 0.80, 0.52)
const VERMILION := Color(0.85, 0.25, 0.17)
const OXBLOOD := Color(0.40, 0.05, 0.07)
const VERDIGRIS := Color(0.05, 0.86, 0.74)
const GOLD := Color(0.84, 0.68, 0.36)
const KEYLINE := Color(0.03, 0.02, 0.04, 0.92)

static var _fallback_ready := false

## Subset display fonts fall back to the full CJK body font for any missing glyph.
static func ensure_fallbacks() -> void:
	if _fallback_ready:
		return
	_fallback_ready = true
	for font in [SerifFont, BrushFont]:
		font.fallbacks = [BodyFont]

static func make_label(text: String, pos: Vector2, font: Font, font_size: int, color: Color, width := 200.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	ensure_fallbacks()
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = Vector2(width, float(font_size) * 1.6)
	label.horizontal_alignment = align
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

## Text that floats over the playfield gets an ink keyline so it reads on any bullet colour.
static func add_keyline(label: Label, outline_size := 6) -> Label:
	label.add_theme_color_override("font_outline_color", KEYLINE)
	label.add_theme_constant_override("outline_size", outline_size)
	return label

static func make_wrapped(label: Label, height: float) -> Label:
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size.y = height
	return label

static func paper_rect(texture: Texture2D, paper_rect: Rect2, margin := 8.0) -> TextureRect:
	var rect := TextureRect.new()
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.texture = texture
	rect.position = paper_rect.position - Vector2(margin, margin)
	rect.size = paper_rect.size + Vector2(margin, margin) * 2.0
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect

## Shrinks a single-line label until its (translated) text fits max_width.
static func fit_line(label: Label, base_size: int, min_size: int, max_width: float) -> void:
	var font: Font = label.get_theme_font("font")
	var text := label.tr(label.text)
	var font_size := base_size
	while font_size > min_size and font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > max_width:
		font_size -= 1
	label.add_theme_font_size_override("font_size", font_size)
	label.size = Vector2(max_width, label.size.y)

## Shrinks a wrapped label until all of its lines fit inside its box height.
static func fit_wrapped(label: Label, base_size: int, min_size: int) -> void:
	var font: Font = label.get_theme_font("font")
	var text := label.tr(label.text)
	var font_size := base_size
	while font_size > min_size and font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, label.size.x, font_size).y > label.size.y:
		font_size -= 1
	label.add_theme_font_size_override("font_size", font_size)
