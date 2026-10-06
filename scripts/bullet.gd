extends Node2D

const PLAYER_SHOT_ALPHA := 0.42
const SPRITES := {
	&"orb": preload("res://art/bullets/orb.png"),
	&"diamond": preload("res://art/bullets/diamond.png"),
	&"needle": preload("res://art/bullets/needle.png"),
	&"petal": preload("res://art/bullets/petal.png"),
	&"star": preload("res://art/bullets/star.png"),
}
## Half-extent of each sprite in bullet-radius units (matches BULLET_SHAPES in gen_art.py).
const SPRITE_EXTENTS := {&"orb": 1.3, &"diamond": 1.6, &"needle": 2.2, &"petal": 2.0, &"star": 1.7}
## Enemy fire is re-inked into four pigments of the shrine palette; patterns keep
## their identity through hue family and shape, the screen keeps one colour story.
const VERMILION := Color(0.93, 0.30, 0.20)
const IVORY := Color(0.96, 0.92, 0.82)
const VERDIGRIS := Color(0.30, 0.82, 0.72)
const GOLD := Color(0.95, 0.74, 0.30)

static func ink_palette(source: Color) -> Color:
	if source.s < 0.22:
		return IVORY
	var hue: float = source.h * 360.0
	if hue < 22.0 or hue >= 300.0:
		return VERMILION
	if hue < 70.0:
		return GOLD
	if hue < 250.0:
		return VERDIGRIS
	return IVORY

var game = null
var faction: StringName = &"enemy"
var shape: StringName = &"orb"
var color := Color.WHITE
var radius := 6.0
var damage := 1.0
var life_time := 8.5
var velocity := Vector2.ZERO
var speed := 0.0
var age := 0.0
var destroyed := false
var grazed := false
var visual_rotation := 0.0
var rotation_speed := 0.0
var visual_scale := 1.0
var wave_amplitude := 0.0
var wave_frequency := 0.0
var wave_phase := 0.0
var spawn_position := Vector2.ZERO
var travel_distance := 0.0
var base_direction := Vector2.UP
var accel_after := -1.0
var accel := 0.0
var turn_rate := 0.0

func setup(game_ref, spawn_pos: Vector2, velocity_vector: Vector2, bullet_faction: StringName, options := {}):
	game = game_ref
	global_position = spawn_pos
	spawn_position = spawn_pos
	velocity = velocity_vector
	speed = velocity.length()
	if speed > 0.001:
		base_direction = velocity.normalized()
	faction = bullet_faction
	shape = options.get("shape", &"orb")
	color = options.get("color", Color.WHITE)
	if faction == &"enemy":
		color = ink_palette(color)
	else:
		# player shots are washed toward paper so they never read as enemy pigment
		color = color.lerp(IVORY, 0.55)
	radius = options.get("radius", 6.0)
	damage = options.get("damage", 1.0)
	life_time = options.get("life_time", 8.5)
	rotation_speed = options.get("rotation_speed", 0.0)
	visual_scale = options.get("scale", 1.0)
	wave_amplitude = options.get("wave_amplitude", 0.0)
	wave_frequency = options.get("wave_frequency", 0.0)
	wave_phase = options.get("wave_phase", 0.0)
	accel_after = options.get("accel_after", -1.0)
	accel = options.get("accel", 0.0)
	turn_rate = options.get("turn_rate", 0.0)
	visual_rotation = velocity_vector.angle() + PI * 0.5
	rotation = visual_rotation
	scale = Vector2.ONE * visual_scale
	queue_redraw()
	return self

func _enter_tree() -> void:
	if game:
		game.register_bullet(self)

func _exit_tree() -> void:
	if game:
		game.unregister_bullet(self)

func _physics_process(delta: float) -> void:
	if destroyed or not game or not game.is_gameplay_active():
		return
	age += delta
	if age >= life_time:
		destroy(false)
		return
	if rotation_speed != 0.0:
		visual_rotation += rotation_speed * delta
	if wave_amplitude != 0.0 and speed > 0.0:
		if accel_after >= 0.0 and age >= accel_after:
			speed += accel * delta
		travel_distance += speed * delta
		var side := Vector2(-base_direction.y, base_direction.x)
		global_position = spawn_position + base_direction * travel_distance + side * sin(age * wave_frequency + wave_phase) * wave_amplitude
	else:
		if accel_after >= 0.0 and age >= accel_after and velocity.length_squared() > 0.001:
			velocity += velocity.normalized() * accel * delta
		if turn_rate != 0.0:
			velocity = velocity.rotated(turn_rate * delta)
		global_position += velocity * delta
		if velocity.length_squared() > 0.001:
			speed = velocity.length()
			base_direction = velocity.normalized()
			if turn_rate != 0.0:
				visual_rotation = base_direction.angle() + PI * 0.5
	rotation = visual_rotation
	if faction == &"enemy":
		_check_player_collision()
	else:
		if game.try_player_bullet_hit(self):
			destroy(true)
			return
	_update_visibility_and_bounds()

func _update_visibility_and_bounds() -> void:
	if faction == &"player":
		var left_bound: float = game.playfield_rect.position.x + 1.0
		var right_bound: float = game.playfield_rect.position.x + game.playfield_rect.size.x - 1.0
		var top_bound: float = game.playfield_rect.position.y - 24.0
		var bottom_bound: float = game.playfield_rect.position.y + game.playfield_rect.size.y + 10.0
		visible = global_position.x >= left_bound and global_position.x <= right_bound and global_position.y >= top_bound and global_position.y <= bottom_bound
		if global_position.y < game.playfield_rect.position.y - 40.0:
			destroy(false)
			return
		if global_position.x < game.playfield_rect.position.x - 14.0 or global_position.x > game.playfield_rect.position.x + game.playfield_rect.size.x + 14.0:
			destroy(false)
			return
	else:
		visible = true
		if not game.get_extended_playfield_rect(96.0).has_point(global_position):
			destroy(false)

func _check_player_collision() -> void:
	var player = game.player
	if not player or not player.is_targetable():
		return
	var hit_distance_sq: float = pow(radius + player.hitbox_radius, 2.0)
	var graze_distance_sq: float = pow(radius + player.graze_radius, 2.0)
	var distance_sq := global_position.distance_squared_to(player.global_position)
	if not grazed and distance_sq <= graze_distance_sq and distance_sq > hit_distance_sq:
		grazed = true
		game.on_player_graze(global_position)
	if player.can_be_hit() and distance_sq <= hit_distance_sq:
		game.on_player_hit()
		destroy(false)

func destroy(show_effect := true, cancelled := false) -> void:
	if destroyed:
		return
	destroyed = true
	if show_effect and game and not game.should_reduce_minor_fx():
		var burst_color := color.lightened(0.2)
		if cancelled:
			burst_color = Color(0.8, 0.96, 1.0)
		game.spawn_ring_effect(global_position, burst_color, radius * 0.2, radius * 1.9, 0.2, 2.0)
	queue_free()

## Enemy bullets are pigment drops painted by tools/art/gen_art.py: an ink keyline
## outside, pooled colour at the rim and a pale core, so each one reads on any
## background. Player shots stay translucent so they never hide enemy fire.
func _draw() -> void:
	if faction == &"player":
		_draw_player_shot()
		return
	var sprite: Texture2D = SPRITES.get(shape, SPRITES[&"orb"])
	var half: float = radius * float(SPRITE_EXTENTS.get(shape, 1.3))
	draw_texture_rect(sprite, Rect2(-half, -half, half * 2.0, half * 2.0), false, color)
	draw_circle(Vector2.ZERO, radius * 0.36, color.lerp(Color.WHITE, 0.8))

func _draw_player_shot() -> void:
	var tint := Color(color.r, color.g, color.b, PLAYER_SHOT_ALPHA)
	if shape == &"orb":
		draw_circle(Vector2.ZERO, radius * 0.8, tint)
	else:
		draw_colored_polygon(_shape_points(radius * 0.85), tint)

func _shape_points(size: float) -> PackedVector2Array:
	match shape:
		&"diamond":
			return PackedVector2Array([Vector2(0.0, -size * 1.3), Vector2(size * 0.9, 0.0), Vector2(0.0, size * 1.3), Vector2(-size * 0.9, 0.0)])
		&"needle":
			return PackedVector2Array([Vector2(0.0, -size * 1.9), Vector2(size * 0.5, -size * 0.15), Vector2(0.0, size * 1.7), Vector2(-size * 0.5, -size * 0.15)])
		&"petal":
			return PackedVector2Array([Vector2(0.0, -size * 1.7), Vector2(size * 0.7, -size * 0.6), Vector2(size * 0.55, size * 1.0), Vector2(0.0, size * 1.5), Vector2(-size * 0.55, size * 1.0), Vector2(-size * 0.7, -size * 0.6)])
		&"star":
			var star := PackedVector2Array()
			for index in range(10):
				var local_radius: float = size * (1.4 if index % 2 == 0 else 0.62)
				star.append(Vector2.RIGHT.rotated(-PI * 0.5 + TAU * float(index) / 10.0) * local_radius)
			return star
	var circle := PackedVector2Array()
	for index in range(12):
		circle.append(Vector2.RIGHT.rotated(TAU * float(index) / 12.0) * size)
	return circle
