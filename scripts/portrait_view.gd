extends Control

## Ink-silhouette portrait: a hand-drawn SVG figure tinted by the speaker's colour,
## a rim-light pass behind it, glowing eyes for the mood, and a motif prop.

const UiTheme = preload("res://scripts/ui_theme.gd")
const FIGURES := {
	"maiden": preload("res://art/portraits/maiden.svg"),
	"sovereign": preload("res://art/portraits/sovereign.svg"),
}
## Eye centres and head centre in the SVG's 300x380 canvas.
const EYE_LEFT := Vector2(134.0, 136.0)
const EYE_RIGHT := Vector2(166.0, 136.0)
const HEAD_CENTER := Vector2(150.0, 120.0)
const RIM_OFFSET := Vector2(4.0, -3.0)
const RIM_GAIN := 4.2

var accent_color := Color(0.88, 0.52, 0.78)
var secondary_color := Color(0.56, 0.92, 1.0)
var side: String = "right"
var mood: String = "calm"
var motif: String = "ribbon"
var figure: String = "sovereign"
var figure_alpha := 1.0
var time_passed := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func configure(data: Dictionary) -> void:
	accent_color = data.get("accent_color", accent_color)
	secondary_color = data.get("secondary_color", secondary_color)
	side = str(data.get("side", side))
	mood = str(data.get("mood", mood))
	motif = str(data.get("motif", motif))
	figure = str(data.get("figure", figure))
	queue_redraw()

func _process(delta: float) -> void:
	time_passed += delta
	if visible:
		queue_redraw()

func _draw() -> void:
	var texture: Texture2D = FIGURES.get(figure, FIGURES["sovereign"])
	var tex_size: Vector2 = texture.get_size()
	var scale_factor: float = min(size.x / tex_size.x, size.y / tex_size.y)
	var origin := Vector2((size.x - tex_size.x * scale_factor) * 0.5, size.y - tex_size.y * scale_factor)
	var mirror := -1.0 if side == "right" else 1.0
	# draw in the SVG's own coordinates, mirrored so figures face into the field
	draw_set_transform(origin + Vector2(tex_size.x * scale_factor if mirror < 0.0 else 0.0, 0.0), 0.0, Vector2(scale_factor * mirror, scale_factor))
	if motif == "halo" or motif == "gear":
		_draw_back_motif()
	var rim := Color(accent_color.r * RIM_GAIN, accent_color.g * RIM_GAIN, accent_color.b * RIM_GAIN, figure_alpha)
	draw_texture(texture, RIM_OFFSET, rim)
	draw_texture(texture, Vector2.ZERO, Color(accent_color.lerp(Color.WHITE, 0.25), figure_alpha))
	_draw_eyes()
	if motif == "crown":
		_draw_crown()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw_eyes() -> void:
	var glow := Color(secondary_color.r, secondary_color.g, secondary_color.b, figure_alpha)
	if mood == "angry":
		glow = Color(1.0, 0.55, 0.32, figure_alpha)
	var blink: float = 1.0 if fposmod(time_passed, 4.2) > 0.12 else 0.2
	for eye in [EYE_LEFT, EYE_RIGHT]:
		var inward: float = 1.0 if eye.x < HEAD_CENTER.x else -1.0
		match mood:
			"soft":
				draw_arc(eye + Vector2(0.0, -2.0), 6.0, 0.25, PI - 0.25, 8, glow, 2.0, true)
			"angry":
				draw_line(eye + Vector2(-7.0 * inward, -4.0), eye + Vector2(6.0 * inward, 1.0), glow, 3.0 * blink, true)
			_:
				draw_line(eye + Vector2(-7.0, 0.0), eye + Vector2(7.0, 0.0), glow, 3.0 * blink, true)

func _draw_back_motif() -> void:
	var color := Color(UiTheme.GOLD.r, UiTheme.GOLD.g, UiTheme.GOLD.b, 0.75 * figure_alpha)
	if motif == "halo":
		draw_arc(HEAD_CENTER + Vector2(0.0, -6.0), 78.0, 0.0, TAU, 48, color, 3.0, true)
		draw_arc(HEAD_CENTER + Vector2(0.0, -6.0), 70.0, 0.0, TAU, 48, Color(color, color.a * 0.4), 1.5, true)
		return
	var spin: float = time_passed * 0.2
	draw_arc(HEAD_CENTER, 84.0, 0.0, TAU, 48, color, 3.0, true)
	for tooth in range(12):
		var angle: float = spin + TAU * float(tooth) / 12.0
		var inner: Vector2 = HEAD_CENTER + Vector2.RIGHT.rotated(angle) * 84.0
		draw_line(inner, inner + Vector2.RIGHT.rotated(angle) * 12.0, color, 6.0)

func _draw_crown() -> void:
	var color := Color(UiTheme.GOLD.r, UiTheme.GOLD.g, UiTheme.GOLD.b, figure_alpha)
	var base_y := 64.0
	var crown := PackedVector2Array([
		Vector2(112.0, base_y), Vector2(118.0, base_y - 30.0), Vector2(134.0, base_y - 12.0),
		Vector2(150.0, base_y - 40.0), Vector2(166.0, base_y - 12.0), Vector2(182.0, base_y - 30.0),
		Vector2(188.0, base_y)
	])
	draw_colored_polygon(crown, color)
