extends RefCounted

var stage_index := 1
var stage_title := ""
var stage_subtitle := ""
var accent_color := Color(0.56, 0.92, 1.0)
var boss_config := {}
var difficulty_key := "normal"
var events: Array = []
var index := 0
var elapsed := 0.0

func setup(new_stage_index: int, new_difficulty_key := "normal"):
	stage_index = new_stage_index
	difficulty_key = new_difficulty_key
	reset()
	_build_events()
	return self

func reset() -> void:
	index = 0
	elapsed = 0.0

func update(game, delta: float) -> void:
	elapsed += delta
	while index < events.size() and elapsed >= events[index]["time"]:
		_trigger_event(game, events[index])
		index += 1
		if not game.is_gameplay_active():
			break

func get_stage_info() -> Dictionary:
	return {
		"stage": stage_index,
		"title": stage_title,
		"subtitle": stage_subtitle,
		"accent_color": accent_color,
		"boss_config": boss_config,
		"difficulty": difficulty_key
	}

func _trigger_event(game, event: Dictionary) -> void:
	match event.get("type", ""):
		"banner":
			game.show_banner(event.get("title", ""), event.get("subtitle", ""))
		"enemy":
			game.spawn_enemy(event.get("config", {}))
		"boss":
			game.spawn_boss(event.get("config", boss_config))
		"dialogue":
			game.start_dialogue(event.get("scene", {}))
		"reward":
			game.offer_wave_reward(event.get("title", tr("REWARD_WAVE")), event.get("subtitle", ""))

func _push_banner(time: float, title: String, subtitle := "") -> void:
	events.append({"time": time, "type": "banner", "title": title, "subtitle": subtitle})

func _push_enemy(time: float, config: Dictionary) -> void:
	events.append({"time": time, "type": "enemy", "config": config})

func _push_boss(time: float, config := {}) -> void:
	events.append({"time": time, "type": "boss", "config": config})

func _push_dialogue(time: float, scene: Dictionary) -> void:
	events.append({"time": time, "type": "dialogue", "scene": scene})

func _push_reward(time: float, title: String, subtitle := "") -> void:
	events.append({"time": time, "type": "reward", "title": title, "subtitle": subtitle})

func _sort_events_by_time(a: Dictionary, b: Dictionary) -> bool:
	return float(a.get("time", 0.0)) < float(b.get("time", 0.0))

func _build_events() -> void:
	events.clear()
	if stage_index == 5:
		_build_stage_five()
	elif stage_index == 4:
		_build_stage_four()
	elif stage_index == 3:
		_build_stage_three()
	elif stage_index == 2:
		_build_stage_two()
	else:
		_build_stage_one()
	events.sort_custom(Callable(self, "_sort_events_by_time"))

func _build_stage_one() -> void:
	stage_title = tr("S1_TITLE")
	stage_subtitle = tr("S1_SUBTITLE")
	accent_color = Color(0.54, 0.92, 1.0)
	boss_config = {
		"name": tr("S1_BOSS_NAME"),
		"subtitle": tr("S1_BOSS_SUB"),
		"radius": 34.0,
		"accent_color": Color(1.0, 0.84, 0.54),
		"secondary_color": Color(0.56, 0.92, 1.0),
		"portrait_side": "right",
		"mood": "calm",
		"motif": "halo",
		"phases": [
			{"name": tr("PHASE_SCARLET_SPIRAL"), "hp": 420.0, "color": Color(1.0, 0.45, 0.68), "bonus": 40000, "pattern": &"scarlet_spiral", "subtitle": tr("S1_P1_SUB"), "mood": "calm", "motif": "halo", "quote": tr("S1_P1_QUOTE")},
			{"name": tr("PHASE_MOON_PETAL_CAGE"), "hp": 560.0, "color": Color(0.58, 0.95, 1.0), "bonus": 70000, "pattern": &"moon_petals", "subtitle": tr("S1_P2_SUB"), "mood": "soft", "motif": "ribbon", "quote": tr("S1_P2_QUOTE")},
			{"name": tr("PHASE_PRISM_CASCADE"), "hp": 700.0, "color": Color(0.76, 0.62, 1.0), "bonus": 100000, "pattern": &"prism_cascade", "subtitle": tr("S1_P3_SUB"), "mood": "soft", "motif": "crown", "quote": tr("S1_P3_QUOTE")},
			{"name": tr("PHASE_FALLING_STAR_BORDER"), "hp": 860.0, "color": Color(1.0, 0.88, 0.46), "bonus": 150000, "pattern": &"falling_star", "subtitle": tr("S1_P4_SUB"), "mood": "angry", "motif": "crown", "quote": tr("S1_P4_QUOTE")}
		]
	}
	_push_banner(0.3, stage_title, stage_subtitle)
	for index_opening in range(5):
		var opening_time: float = 1.4 + float(index_opening) * 0.48
		_push_enemy(opening_time, {
			"name": "veilwing",
			"spawn": Vector2(90.0, -40.0 - float(index_opening) * 18.0),
			"motion": &"sine_down",
			"velocity": Vector2(0.0, 175.0),
			"sine_amplitude": 58.0,
			"sine_frequency": 2.8,
			"sine_phase": 0.0,
			"shoot_pattern": &"aimed_single",
			"shoot_interval": 0.9,
			"bullet_speed": 185.0,
			"bullet_shape": &"orb",
			"bullet_color": Color(1.0, 0.55, 0.78),
			"score": 950,
			"point_drops": 1
		})
		_push_enemy(opening_time + 0.18, {
			"name": "veilwing",
			"spawn": Vector2(520.0, -32.0 - float(index_opening) * 16.0),
			"motion": &"sine_down",
			"velocity": Vector2(0.0, 175.0),
			"sine_amplitude": 58.0,
			"sine_frequency": 2.8,
			"sine_phase": PI,
			"shoot_pattern": &"aimed_single",
			"shoot_interval": 0.95,
			"bullet_speed": 185.0,
			"bullet_shape": &"orb",
			"bullet_color": Color(0.55, 0.95, 1.0),
			"score": 950,
			"point_drops": 1
		})
	for side in range(2):
		var x_spawn: float = -36.0
		var x_velocity: float = 145.0
		var curve_strength: float = 36.0
		if side == 1:
			x_spawn = 644.0
			x_velocity = -145.0
			curve_strength = -36.0
		for sweep_index in range(4):
			_push_enemy(7.4 + float(side) * 0.25 + float(sweep_index) * 0.55, {
				"name": "sweeper",
				"spawn": Vector2(x_spawn, 90.0 + float(sweep_index) * 28.0),
				"motion": &"curve",
				"velocity": Vector2(x_velocity, 92.0),
				"curve_strength": curve_strength,
				"hp": 30.0,
				"radius": 17.0,
				"shoot_pattern": &"aimed_fan",
				"shoot_interval": 0.9 + float(sweep_index) * 0.05,
				"bullet_speed": 205.0,
				"shot_count": 5,
				"spread_deg": 48.0,
				"bullet_shape": &"needle",
				"bullet_color": Color(0.54, 0.92, 1.0),
				"score": 1350,
				"point_drops": 2
			})
	_push_banner(13.0, tr("S1_BANNER_1"), tr("S1_BANNER_1_SUB"))
	_push_reward(12.1, tr("REWARD_WAVE"), tr("S1_REWARD_1"))
	for spinner_index in range(3):
		var center_x: float = 160.0 + float(spinner_index) * 110.0
		_push_enemy(14.2 + float(spinner_index) * 1.1, {
			"name": "bloomer",
			"spawn": Vector2(center_x, -70.0),
			"motion": &"approach_hold",
			"destination": Vector2(center_x, 170.0 + float(spinner_index) * 24.0),
			"hold_time": 2.1,
			"retreat_velocity": Vector2(0.0, 95.0),
			"approach_speed": 2.1,
			"hp": 55.0,
			"radius": 19.0,
			"shoot_pattern": &"ring",
			"shoot_interval": 1.1,
			"bullet_speed": 155.0,
			"ring_count": 14,
			"bullet_shape": &"diamond",
			"bullet_color": Color(1.0, 0.86, 0.42),
			"rotation_step": 0.42,
			"score": 2400,
			"point_drops": 3,
			"power_drops": 1
		})
	for caster_index in range(3):
		var caster_time: float = 18.2 + float(caster_index) * 0.92
		var caster_x: float = 120.0 + float(caster_index) * 160.0
		_push_enemy(caster_time, {
			"name": "caster",
			"spawn": Vector2(caster_x, -58.0),
			"motion": &"approach_hold",
			"destination": Vector2(caster_x, 148.0 + float(caster_index % 2) * 26.0),
			"hold_time": 1.75,
			"retreat_velocity": Vector2(0.0, 122.0),
			"approach_speed": 2.0,
			"hp": 54.0,
			"radius": 20.0,
			"shoot_pattern": &"cross_fan",
			"shoot_interval": 0.72,
			"bullet_speed": 186.0,
			"shot_count": 5,
			"spread_deg": 58.0,
			"bullet_shape": &"petal",
			"bullet_color": Color(0.96, 0.66, 1.0),
			"rotation_step": 0.42,
			"score": 2600,
			"point_drops": 2,
			"power_drops": 1
		})
	for cross_index in range(6):
		var cross_time: float = 20.2 + float(cross_index) * 0.42
		_push_enemy(cross_time, {
			"name": "fairy",
			"spawn": Vector2(120.0 + float(cross_index) * 64.0, -38.0),
			"motion": &"straight",
			"velocity": Vector2(0.0, 200.0),
			"hp": 24.0,
			"shoot_pattern": &"aimed_fan",
			"shoot_interval": 0.75,
			"bullet_speed": 220.0,
			"shot_count": 3,
			"spread_deg": 30.0,
			"bullet_shape": &"orb",
			"bullet_color": Color(1.0, 0.42, 0.66),
			"score": 1100,
			"point_drops": 1
		})
	for carrier_index in range(4):
		var carrier_time: float = 25.2 + float(carrier_index) * 1.4
		var carrier_x: float = 120.0
		if carrier_index % 2 != 0:
			carrier_x = 486.0
		_push_enemy(carrier_time, {
			"name": "carrier",
			"spawn": Vector2(carrier_x, -60.0),
			"motion": &"straight",
			"velocity": Vector2(0.0, 118.0),
			"hp": 82.0,
			"radius": 22.0,
			"shoot_pattern": &"aimed_fan",
			"shoot_interval": 1.0,
			"bullet_speed": 195.0,
			"shot_count": 7,
			"spread_deg": 58.0,
			"bullet_shape": &"petal",
			"bullet_color": Color(0.88, 0.58, 1.0),
			"score": 4200,
			"point_drops": 3,
			"power_drops": 2
		})
	_push_banner(31.2, tr("S1_BANNER_2"), tr("S1_BANNER_2_SUB"))
	_push_reward(30.4, tr("REWARD_WAVE"), tr("S1_REWARD_2"))
	for dense_index in range(5):
		var dense_time: float = 32.0 + float(dense_index) * 0.55
		_push_enemy(dense_time, {
			"name": "sweeper",
			"spawn": Vector2(-34.0, 110.0 + float(dense_index) * 24.0),
			"motion": &"curve",
			"velocity": Vector2(175.0, 110.0),
			"curve_strength": 40.0,
			"hp": 34.0,
			"shoot_pattern": &"spiral",
			"shoot_interval": 0.14,
			"bullet_speed": 175.0,
			"bullet_shape": &"diamond",
			"bullet_color": Color(0.52, 0.94, 1.0),
			"rotation_step": 0.26,
			"score": 1700,
			"point_drops": 2
		})
		_push_enemy(dense_time + 0.18, {
			"name": "sweeper",
			"spawn": Vector2(642.0, 130.0 + float(dense_index) * 24.0),
			"motion": &"curve",
			"velocity": Vector2(-175.0, 110.0),
			"curve_strength": -40.0,
			"hp": 34.0,
			"shoot_pattern": &"spiral",
			"shoot_interval": 0.14,
			"bullet_speed": 175.0,
			"bullet_shape": &"diamond",
			"bullet_color": Color(1.0, 0.55, 0.76),
			"rotation_step": -0.26,
			"score": 1700,
			"point_drops": 2
		})
	_push_reward(41.0, tr("REWARD_WAVE"), tr("S1_REWARD_3"))
	for preboss_index in range(2):
		_push_enemy(39.2 + float(preboss_index) * 1.3, {
			"name": "spinner",
			"spawn": Vector2(180.0 + float(preboss_index) * 190.0, -84.0),
			"motion": &"approach_hold",
			"destination": Vector2(180.0 + float(preboss_index) * 190.0, 170.0),
			"hold_time": 2.4,
			"retreat_velocity": Vector2(0.0, 120.0),
			"approach_speed": 1.8,
			"hp": 80.0,
			"radius": 22.0,
			"shoot_pattern": &"ring",
			"shoot_interval": 0.85,
			"bullet_speed": 165.0,
			"ring_count": 18,
			"bullet_shape": &"petal",
			"bullet_color": Color(1.0, 0.84, 0.44),
			"rotation_step": 0.55 if preboss_index == 0 else -0.55,
			"score": 3200,
			"point_drops": 3,
			"power_drops": 1
		})
	for final_fairy in range(6):
		_push_enemy(42.8 + float(final_fairy) * 0.28, {
			"name": "fairy",
			"spawn": Vector2(90.0 + float(final_fairy) * 78.0, -32.0),
			"motion": &"straight",
			"velocity": Vector2(0.0, 220.0),
			"hp": 22.0,
			"shoot_pattern": &"aimed_single",
			"shoot_interval": 0.65,
			"bullet_speed": 215.0,
			"bullet_shape": &"needle",
			"bullet_color": Color(0.92, 0.92, 1.0),
			"score": 1000,
			"point_drops": 1
		})
	_push_dialogue(46.0, {
		"cast": {
			"left": {"accent_color": Color(0.82, 0.3, 0.42), "secondary_color": Color(1.0, 0.92, 0.72), "side": "left", "mood": "calm", "motif": "ribbon"},
			"right": {"accent_color": boss_config["accent_color"], "secondary_color": boss_config["secondary_color"], "side": "right", "mood": boss_config["mood"], "motif": boss_config["motif"]}
		},
		"lines": [
			{"speaker": tr("SPEAKER_LUO_TIANYI"), "side": "left", "speaker_color": Color(1.0, 0.88, 0.72), "portrait_update": {"mood": "calm", "motif": "ribbon"}, "text": tr("S1_LINE_1")},
			{"speaker": tr("S1_SPEAKER_BOSS"), "side": "right", "speaker_color": boss_config["accent_color"], "portrait_update": {"mood": "soft", "motif": "halo"}, "text": tr("S1_LINE_2")},
			{"speaker": tr("SPEAKER_LUO_TIANYI"), "side": "left", "speaker_color": Color(1.0, 0.88, 0.72), "portrait_update": {"mood": "angry", "motif": "ribbon"}, "text": tr("S1_LINE_3")}
		]
	})
	_push_banner(46.4, tr("BANNER_BOSS_APPROACH"), boss_config["name"])
	_push_boss(48.6, boss_config)

func _build_stage_two() -> void:
	stage_title = tr("S2_TITLE")
	stage_subtitle = tr("S2_SUBTITLE")
	accent_color = Color(1.0, 0.68, 0.42)
	boss_config = {
		"name": tr("S2_BOSS_NAME"),
		"subtitle": tr("S2_BOSS_SUB"),
		"radius": 38.0,
		"accent_color": Color(1.0, 0.74, 0.42),
		"secondary_color": Color(0.58, 0.96, 1.0),
		"portrait_side": "right",
		"mood": "angry",
		"motif": "gear",
		"phases": [
			{"name": tr("PHASE_MAGNETIC_BLOOM"), "hp": 540.0, "color": Color(1.0, 0.64, 0.42), "bonus": 70000, "pattern": &"magnetic_bloom", "subtitle": tr("S2_P1_SUB"), "mood": "angry", "motif": "gear", "quote": tr("S2_P1_QUOTE")},
			{"name": tr("PHASE_AURORA_LATTICE"), "hp": 720.0, "color": Color(0.48, 0.94, 1.0), "bonus": 110000, "pattern": &"aurora_lattice", "subtitle": tr("S2_P2_SUB"), "mood": "calm", "motif": "halo", "quote": tr("S2_P2_QUOTE")},
			{"name": tr("PHASE_COMET_REFINERY"), "hp": 880.0, "color": Color(0.86, 0.56, 1.0), "bonus": 150000, "pattern": &"comet_refinery", "subtitle": tr("S2_P3_SUB"), "mood": "angry", "motif": "gear", "quote": tr("S2_P3_QUOTE")},
			{"name": tr("PHASE_COLLAPSE_FURNACE"), "hp": 1080.0, "color": Color(1.0, 0.88, 0.52), "bonus": 220000, "pattern": &"boundary_collapse", "subtitle": tr("S2_P4_SUB"), "mood": "angry", "motif": "crown", "quote": tr("S2_P4_QUOTE")}
		]
	}
	_push_banner(0.3, stage_title, stage_subtitle)
	for wave_index in range(6):
		var wave_time: float = 1.2 + float(wave_index) * 0.42
		_push_enemy(wave_time, {
			"name": "lancer",
			"spawn": Vector2(-34.0, 90.0 + float(wave_index) * 28.0),
			"motion": &"curve",
			"velocity": Vector2(185.0, 126.0),
			"curve_strength": 42.0,
			"hp": 30.0,
			"radius": 18.0,
			"shoot_pattern": &"aimed_fan",
			"shoot_interval": 0.8,
			"bullet_speed": 220.0,
			"shot_count": 5,
			"spread_deg": 44.0,
			"bullet_shape": &"needle",
			"bullet_color": Color(1.0, 0.68, 0.42),
			"score": 1500,
			"point_drops": 1
		})
		_push_enemy(wave_time + 0.16, {
			"name": "lancer",
			"spawn": Vector2(642.0, 110.0 + float(wave_index) * 28.0),
			"motion": &"curve",
			"velocity": Vector2(-185.0, 126.0),
			"curve_strength": -42.0,
			"hp": 30.0,
			"radius": 18.0,
			"shoot_pattern": &"aimed_fan",
			"shoot_interval": 0.8,
			"bullet_speed": 220.0,
			"shot_count": 5,
			"spread_deg": 44.0,
			"bullet_shape": &"needle",
			"bullet_color": Color(0.46, 0.94, 1.0),
			"score": 1500,
			"point_drops": 1
		})
	for drop_index in range(5):
		_push_enemy(7.8 + float(drop_index) * 0.6, {
			"name": "weaver",
			"spawn": Vector2(96.0 + float(drop_index) * 88.0, -60.0),
			"motion": &"straight",
			"velocity": Vector2(0.0, 138.0),
			"hp": 42.0,
			"radius": 18.0,
			"shoot_pattern": &"wall",
			"shoot_interval": 0.7,
			"bullet_speed": 175.0,
			"shot_count": 9,
			"spread_deg": 74.0,
			"bullet_shape": &"petal",
			"bullet_color": Color(0.62, 1.0, 0.9),
			"score": 1800,
			"point_drops": 2
		})
	_push_banner(13.5, tr("S2_BANNER_1"), tr("S2_BANNER_1_SUB"))
	_push_reward(12.9, tr("REWARD_WAVE"), tr("S2_REWARD_1"))
	for guardian_index in range(3):
		var guardian_x: float = 132.0 + float(guardian_index) * 148.0
		_push_enemy(14.8 + float(guardian_index) * 1.3, {
			"name": "guardian",
			"spawn": Vector2(guardian_x, -84.0),
			"motion": &"approach_hold",
			"destination": Vector2(guardian_x, 176.0),
			"hold_time": 2.6,
			"retreat_velocity": Vector2(0.0, 108.0),
			"approach_speed": 1.9,
			"hp": 96.0,
			"radius": 24.0,
			"shoot_pattern": &"burst_ring",
			"shoot_interval": 0.9,
			"bullet_speed": 186.0,
			"ring_count": 12,
			"bullet_shape": &"diamond",
			"bullet_color": Color(0.72, 0.8, 1.0),
			"rotation_step": 0.48,
			"score": 4200,
			"point_drops": 3,
			"power_drops": 1
		})
	for lattice_index in range(6):
		var lattice_time: float = 22.4 + float(lattice_index) * 0.4
		_push_enemy(lattice_time, {
			"name": "lancer",
			"spawn": Vector2(72.0 + float(lattice_index) * 78.0, -36.0),
			"motion": &"straight",
			"velocity": Vector2(0.0, 214.0),
			"hp": 28.0,
			"shoot_pattern": &"arc_burst",
			"shoot_interval": 0.7,
			"bullet_speed": 208.0,
			"shot_count": 5,
			"spread_deg": 46.0,
			"ring_count": 8,
			"bullet_shape": &"needle",
			"bullet_color": Color(1.0, 0.74, 0.46),
			"score": 1600,
			"point_drops": 1
		})
	for carrier_index in range(4):
		var carrier_time: float = 27.2 + float(carrier_index) * 1.1
		var carrier_x: float = 118.0 if carrier_index % 2 == 0 else 490.0
		var rotation: float = 0.38 if carrier_index % 2 == 0 else -0.38
		_push_enemy(carrier_time, {
			"name": "guardian",
			"spawn": Vector2(carrier_x, -70.0),
			"motion": &"approach_hold",
			"destination": Vector2(carrier_x, 150.0 + float(carrier_index) * 20.0),
			"hold_time": 2.4,
			"retreat_velocity": Vector2(0.0, 118.0),
			"approach_speed": 1.7,
			"hp": 118.0,
			"radius": 24.0,
			"shoot_pattern": &"ring",
			"shoot_interval": 0.82,
			"bullet_speed": 180.0,
			"ring_count": 16,
			"bullet_shape": &"petal",
			"bullet_color": Color(0.92, 0.58, 1.0),
			"rotation_step": rotation,
			"score": 4600,
			"point_drops": 3,
			"power_drops": 2
		})
	_push_banner(33.5, tr("S2_BANNER_2"), tr("S2_BANNER_2_SUB"))
	_push_reward(32.8, tr("REWARD_WAVE"), tr("S2_REWARD_2"))
	for sentinel_index in range(4):
		var sentinel_time: float = 33.9 + float(sentinel_index) * 0.52
		var sentinel_x: float = 88.0 + float(sentinel_index) * 132.0
		_push_enemy(sentinel_time, {
			"name": "sentinel",
			"spawn": Vector2(sentinel_x, -54.0),
			"motion": &"straight",
			"velocity": Vector2(0.0, 154.0),
			"hp": 44.0,
			"radius": 19.0,
			"shoot_pattern": &"pinwheel",
			"shoot_interval": 0.2,
			"bullet_speed": 188.0,
			"bullet_shape": &"needle",
			"bullet_color": Color(1.0, 0.78, 0.54),
			"rotation_step": 0.34 if sentinel_index % 2 == 0 else -0.34,
			"score": 2200,
			"point_drops": 2,
			"power_drops": 1
		})
	for storm_index in range(6):
		var storm_time: float = 34.4 + float(storm_index) * 0.48
		_push_enemy(storm_time, {
			"name": "weaver",
			"spawn": Vector2(-30.0, 116.0 + float(storm_index) * 22.0),
			"motion": &"curve",
			"velocity": Vector2(180.0, 116.0),
			"curve_strength": 38.0,
			"hp": 36.0,
			"shoot_pattern": &"spiral",
			"shoot_interval": 0.13,
			"bullet_speed": 178.0,
			"bullet_shape": &"diamond",
			"bullet_color": Color(0.54, 0.96, 1.0),
			"rotation_step": 0.28,
			"score": 1900,
			"point_drops": 2
		})
		_push_enemy(storm_time + 0.18, {
			"name": "weaver",
			"spawn": Vector2(646.0, 138.0 + float(storm_index) * 22.0),
			"motion": &"curve",
			"velocity": Vector2(-180.0, 116.0),
			"curve_strength": -38.0,
			"hp": 36.0,
			"shoot_pattern": &"spiral",
			"shoot_interval": 0.13,
			"bullet_speed": 178.0,
			"bullet_shape": &"diamond",
			"bullet_color": Color(1.0, 0.66, 0.46),
			"rotation_step": -0.28,
			"score": 1900,
			"point_drops": 2
		})
	_push_reward(41.5, tr("REWARD_WAVE"), tr("S2_REWARD_3"))
	for preboss in range(3):
		_push_enemy(41.6 + float(preboss) * 1.0, {
			"name": "guardian",
			"spawn": Vector2(130.0 + float(preboss) * 150.0, -86.0),
			"motion": &"approach_hold",
			"destination": Vector2(130.0 + float(preboss) * 150.0, 164.0),
			"hold_time": 2.3,
			"retreat_velocity": Vector2(0.0, 130.0),
			"approach_speed": 1.6,
			"hp": 132.0,
			"radius": 26.0,
			"shoot_pattern": &"burst_ring",
			"shoot_interval": 0.82,
			"bullet_speed": 190.0,
			"ring_count": 14,
			"bullet_shape": &"diamond",
			"bullet_color": Color(1.0, 0.78, 0.46),
			"rotation_step": 0.5,
			"score": 5200,
			"point_drops": 3,
			"power_drops": 1
		})
	_push_dialogue(45.8, {
		"cast": {
			"left": {"accent_color": Color(0.82, 0.3, 0.42), "secondary_color": Color(1.0, 0.92, 0.72), "side": "left", "mood": "soft", "motif": "ribbon"},
			"right": {"accent_color": boss_config["accent_color"], "secondary_color": boss_config["secondary_color"], "side": "right", "mood": boss_config["mood"], "motif": boss_config["motif"]}
		},
		"lines": [
			{"speaker": tr("SPEAKER_LUO_TIANYI"), "side": "left", "speaker_color": Color(1.0, 0.88, 0.72), "portrait_update": {"mood": "soft", "motif": "ribbon"}, "text": tr("S2_LINE_1")},
			{"speaker": tr("S2_SPEAKER_BOSS"), "side": "right", "speaker_color": boss_config["accent_color"], "portrait_update": {"mood": "angry", "motif": "gear"}, "text": tr("S2_LINE_2")},
			{"speaker": tr("SPEAKER_LUO_TIANYI"), "side": "left", "speaker_color": Color(1.0, 0.88, 0.72), "portrait_update": {"mood": "angry", "motif": "ribbon"}, "text": tr("S2_LINE_3")}
		]
	})
	_push_banner(46.2, tr("BANNER_BOSS_APPROACH"), boss_config["name"])
	_push_boss(48.8, boss_config)

func _build_stage_three() -> void:
	stage_title = tr("S3_TITLE")
	stage_subtitle = tr("S3_SUBTITLE")
	accent_color = Color(0.72, 0.66, 1.0)
	boss_config = {
		"name": tr("S3_BOSS_NAME"),
		"subtitle": tr("S3_BOSS_SUB"),
		"radius": 40.0,
		"accent_color": Color(0.92, 0.62, 1.0),
		"secondary_color": Color(0.52, 0.96, 1.0),
		"portrait_side": "right",
		"mood": "angry",
		"motif": "crown",
		"phases": [
			{"name": tr("PHASE_MAGNETIC_BLOOM"), "hp": 760.0, "color": Color(1.0, 0.66, 0.48), "bonus": 100000, "pattern": &"magnetic_bloom", "subtitle": tr("S3_P1_SUB"), "mood": "angry", "motif": "gear", "quote": tr("S3_P1_QUOTE")},
			{"name": tr("PHASE_AURORA_LATTICE"), "hp": 980.0, "color": Color(0.52, 0.94, 1.0), "bonus": 150000, "pattern": &"aurora_lattice", "subtitle": tr("S3_P2_SUB"), "mood": "calm", "motif": "halo", "quote": tr("S3_P2_QUOTE")},
			{"name": tr("PHASE_COMET_REFINERY"), "hp": 1240.0, "color": Color(0.86, 0.58, 1.0), "bonus": 210000, "pattern": &"comet_refinery", "subtitle": tr("S3_P3_SUB"), "mood": "angry", "motif": "gear", "quote": tr("S3_P3_QUOTE")},
			{"name": tr("PHASE_BORDER_COLLAPSE"), "hp": 1540.0, "color": Color(1.0, 0.88, 0.56), "bonus": 320000, "pattern": &"boundary_collapse", "subtitle": tr("S3_P4_SUB"), "mood": "angry", "motif": "crown", "quote": tr("S3_P4_QUOTE")}
		]
	}
	_push_banner(0.3, stage_title, stage_subtitle)
	for opening_index in range(7):
		var opening_time: float = 1.0 + float(opening_index) * 0.34
		_push_enemy(opening_time, {
			"name": "lancer",
			"spawn": Vector2(-40.0, 82.0 + float(opening_index) * 24.0),
			"motion": &"curve",
			"velocity": Vector2(205.0, 124.0),
			"curve_strength": 48.0,
			"hp": 36.0,
			"radius": 18.0,
			"shoot_pattern": &"aimed_fan",
			"shoot_interval": 0.76,
			"bullet_speed": 232.0,
			"shot_count": 5,
			"spread_deg": 44.0,
			"bullet_shape": &"needle",
			"bullet_color": Color(1.0, 0.74, 0.48),
			"score": 1700,
			"point_drops": 1
		})
		_push_enemy(opening_time + 0.14, {
			"name": "lancer",
			"spawn": Vector2(646.0, 106.0 + float(opening_index) * 24.0),
			"motion": &"curve",
			"velocity": Vector2(-205.0, 124.0),
			"curve_strength": -48.0,
			"hp": 36.0,
			"radius": 18.0,
			"shoot_pattern": &"aimed_fan",
			"shoot_interval": 0.76,
			"bullet_speed": 232.0,
			"shot_count": 5,
			"spread_deg": 44.0,
			"bullet_shape": &"needle",
			"bullet_color": Color(0.56, 0.96, 1.0),
			"score": 1700,
			"point_drops": 1
		})
	for drop_index in range(5):
		_push_enemy(4.4 + float(drop_index) * 0.56, {
			"name": "fairy",
			"spawn": Vector2(92.0 + float(drop_index) * 92.0, -42.0),
			"motion": &"straight",
			"velocity": Vector2(0.0, 194.0),
			"hp": 28.0,
			"shoot_pattern": &"aimed_single",
			"shoot_interval": 0.62,
			"bullet_speed": 226.0,
			"bullet_shape": &"orb",
			"bullet_color": Color(0.98, 0.56, 0.78),
			"score": 1250,
			"point_drops": 1
		})
	_push_reward(9.2, tr("REWARD_WAVE"), tr("S3_REWARD_1"))
	_push_banner(10.0, tr("S3_BANNER_1"), tr("S3_BANNER_1_SUB"))
	for caster_index in range(4):
		var caster_time: float = 10.8 + float(caster_index) * 0.86
		var caster_x: float = 112.0 + float(caster_index) * 120.0
		_push_enemy(caster_time, {
			"name": "anchor",
			"spawn": Vector2(caster_x, -62.0),
			"motion": &"approach_hold",
			"destination": Vector2(caster_x, 146.0 + float(caster_index % 2) * 28.0),
			"hold_time": 2.0,
			"retreat_velocity": Vector2(0.0, 118.0),
			"approach_speed": 2.1,
			"hp": 64.0,
			"radius": 20.0,
			"shoot_pattern": &"split_fan",
			"shoot_interval": 0.66,
			"bullet_speed": 194.0,
			"shot_count": 5,
			"spread_deg": 60.0,
			"bullet_shape": &"petal",
			"bullet_color": Color(0.94, 0.68, 1.0),
			"rotation_step": 0.48,
			"score": 2800,
			"point_drops": 2,
			"power_drops": 1
		})
	for sentinel_index in range(5):
		var sentinel_time: float = 13.2 + float(sentinel_index) * 0.48
		var sentinel_x: float = 82.0 + float(sentinel_index) * 104.0
		_push_enemy(sentinel_time, {
			"name": "shade",
			"spawn": Vector2(sentinel_x, -56.0),
			"motion": &"straight",
			"velocity": Vector2(0.0, 166.0),
			"hp": 48.0,
			"radius": 19.0,
			"shoot_pattern": &"mine_burst",
			"shoot_interval": 0.92,
			"bullet_speed": 196.0,
			"bullet_shape": &"needle",
			"bullet_color": Color(1.0, 0.82, 0.56),
			"rotation_step": 0.36 if sentinel_index % 2 == 0 else -0.36,
			"score": 2300,
			"point_drops": 2,
			"power_drops": 1
		})
	_push_reward(18.8, tr("REWARD_WAVE"), tr("S3_REWARD_2"))
	_push_banner(19.6, tr("S3_BANNER_2"), tr("S3_BANNER_2_SUB"))
	for guardian_index in range(4):
		var guardian_time: float = 20.2 + float(guardian_index) * 1.08
		var guardian_x: float = 104.0 + float(guardian_index) * 118.0
		_push_enemy(guardian_time, {
			"name": "guardian",
			"spawn": Vector2(guardian_x, -88.0),
			"motion": &"approach_hold",
			"destination": Vector2(guardian_x, 166.0),
			"hold_time": 2.4,
			"retreat_velocity": Vector2(0.0, 132.0),
			"approach_speed": 1.8,
			"hp": 128.0,
			"radius": 25.0,
			"shoot_pattern": &"burst_ring",
			"shoot_interval": 0.82,
			"bullet_speed": 194.0,
			"ring_count": 14,
			"bullet_shape": &"diamond",
			"bullet_color": Color(0.76, 0.84, 1.0),
			"rotation_step": 0.46 if guardian_index % 2 == 0 else -0.46,
			"score": 5000,
			"point_drops": 3,
			"power_drops": 1
		})
	for lattice_index in range(6):
		var lattice_time: float = 24.9 + float(lattice_index) * 0.36
		_push_enemy(lattice_time, {
			"name": "weaver",
			"spawn": Vector2(88.0 + float(lattice_index) * 84.0, -44.0),
			"motion": &"straight",
			"velocity": Vector2(0.0, 164.0),
			"hp": 40.0,
			"radius": 18.0,
			"shoot_pattern": &"wall",
			"shoot_interval": 0.58,
			"bullet_speed": 188.0,
			"shot_count": 9,
			"spread_deg": 82.0,
			"bullet_shape": &"petal",
			"bullet_color": Color(0.62, 1.0, 0.92),
			"score": 2100,
			"point_drops": 2
		})
	_push_reward(30.4, tr("REWARD_WAVE"), tr("S3_REWARD_3"))
	_push_banner(31.2, tr("S3_BANNER_3"), tr("S3_BANNER_3_SUB"))
	for storm_index in range(7):
		var storm_time: float = 31.8 + float(storm_index) * 0.42
		_push_enemy(storm_time, {
			"name": "weaver",
			"spawn": Vector2(-36.0, 106.0 + float(storm_index) * 22.0),
			"motion": &"curve",
			"velocity": Vector2(194.0, 122.0),
			"curve_strength": 42.0,
			"hp": 38.0,
			"shoot_pattern": &"spiral",
			"shoot_interval": 0.12,
			"bullet_speed": 186.0,
			"bullet_shape": &"diamond",
			"bullet_color": Color(0.56, 0.96, 1.0),
			"rotation_step": 0.28,
			"score": 2000,
			"point_drops": 2
		})
		_push_enemy(storm_time + 0.18, {
			"name": "weaver",
			"spawn": Vector2(646.0, 126.0 + float(storm_index) * 22.0),
			"motion": &"curve",
			"velocity": Vector2(-194.0, 122.0),
			"curve_strength": -42.0,
			"hp": 38.0,
			"shoot_pattern": &"spiral",
			"shoot_interval": 0.12,
			"bullet_speed": 186.0,
			"bullet_shape": &"diamond",
			"bullet_color": Color(1.0, 0.62, 0.48),
			"rotation_step": -0.28,
			"score": 2000,
			"point_drops": 2
		})
	for carrier_index in range(3):
		var carrier_time: float = 36.6 + float(carrier_index) * 1.12
		var carrier_x: float = 126.0 + float(carrier_index) * 150.0
		_push_enemy(carrier_time, {
			"name": "carrier",
			"spawn": Vector2(carrier_x, -72.0),
			"motion": &"approach_hold",
			"destination": Vector2(carrier_x, 154.0),
			"hold_time": 2.0,
			"retreat_velocity": Vector2(0.0, 124.0),
			"approach_speed": 1.75,
			"hp": 138.0,
			"radius": 24.0,
			"shoot_pattern": &"cross_fan",
			"shoot_interval": 0.72,
			"bullet_speed": 198.0,
			"shot_count": 7,
			"spread_deg": 72.0,
			"bullet_shape": &"petal",
			"bullet_color": Color(0.92, 0.56, 1.0),
			"rotation_step": 0.44,
			"score": 5600,
			"point_drops": 3,
			"power_drops": 2
		})
	_push_reward(41.6, tr("REWARD_WAVE"), tr("S3_REWARD_4"))
	for preboss in range(4):
		_push_enemy(42.2 + float(preboss) * 0.82, {
			"name": "guardian",
			"spawn": Vector2(94.0 + float(preboss) * 128.0, -88.0),
			"motion": &"approach_hold",
			"destination": Vector2(94.0 + float(preboss) * 128.0, 170.0),
			"hold_time": 1.8,
			"retreat_velocity": Vector2(0.0, 138.0),
			"approach_speed": 1.6,
			"hp": 142.0,
			"radius": 26.0,
			"shoot_pattern": &"burst_ring",
			"shoot_interval": 0.74,
			"bullet_speed": 202.0,
			"ring_count": 16,
			"bullet_shape": &"diamond",
			"bullet_color": Color(1.0, 0.82, 0.52),
			"rotation_step": 0.54,
			"score": 6200,
			"point_drops": 3,
			"power_drops": 1
		})
	_push_dialogue(47.0, {
		"cast": {
			"left": {"accent_color": Color(0.82, 0.3, 0.42), "secondary_color": Color(1.0, 0.92, 0.72), "side": "left", "mood": "angry", "motif": "ribbon"},
			"right": {"accent_color": boss_config["accent_color"], "secondary_color": boss_config["secondary_color"], "side": "right", "mood": boss_config["mood"], "motif": boss_config["motif"]}
		},
		"lines": [
			{"speaker": tr("SPEAKER_PILOT"), "side": "left", "speaker_color": Color(1.0, 0.88, 0.72), "portrait_update": {"mood": "angry", "motif": "ribbon"}, "text": tr("S3_LINE_1")},
			{"speaker": tr("S3_SPEAKER_BOSS"), "side": "right", "speaker_color": boss_config["accent_color"], "portrait_update": {"mood": "angry", "motif": "crown"}, "text": tr("S3_LINE_2")},
			{"speaker": tr("SPEAKER_PILOT"), "side": "left", "speaker_color": Color(1.0, 0.88, 0.72), "portrait_update": {"mood": "soft", "motif": "ribbon"}, "text": tr("S3_LINE_3")}
		]
	})
	_push_banner(47.6, tr("BANNER_BOSS_APPROACH"), boss_config["name"])
	_push_boss(50.0, boss_config)

func _build_stage_four() -> void:
	stage_title = tr("S4_TITLE")
	stage_subtitle = tr("S4_SUBTITLE")
	accent_color = Color(1.0, 0.64, 0.58)
	boss_config = {
		"name": tr("S4_BOSS_NAME"),
		"subtitle": tr("S4_BOSS_SUB"),
		"radius": 42.0,
		"accent_color": Color(1.0, 0.7, 0.56),
		"secondary_color": Color(0.64, 0.9, 1.0),
		"portrait_side": "right",
		"mood": "angry",
		"motif": "crown",
		"phases": [
			{"name": tr("PHASE_PRISM_SPIRAL"), "hp": 980.0, "color": Color(1.0, 0.64, 0.56), "bonus": 140000, "pattern": &"scarlet_spiral", "subtitle": tr("S4_P1_SUB"), "mood": "angry", "motif": "gear", "quote": tr("S4_P1_QUOTE")},
			{"name": tr("PHASE_FALLING_GRID"), "hp": 1260.0, "color": Color(0.62, 0.94, 1.0), "bonus": 220000, "pattern": &"aurora_lattice", "subtitle": tr("S4_P2_SUB"), "mood": "calm", "motif": "halo", "quote": tr("S4_P2_QUOTE")},
			{"name": tr("PHASE_CROWN_FORGE"), "hp": 1540.0, "color": Color(0.92, 0.58, 1.0), "bonus": 300000, "pattern": &"comet_refinery", "subtitle": tr("S4_P3_SUB"), "mood": "angry", "motif": "gear", "quote": tr("S4_P3_QUOTE")},
			{"name": tr("PHASE_ENDLAND_ANNIHILATION"), "hp": 1880.0, "color": Color(1.0, 0.9, 0.58), "bonus": 420000, "pattern": &"boundary_collapse", "subtitle": tr("S4_P4_SUB"), "mood": "angry", "motif": "crown", "quote": tr("S4_P4_QUOTE")}
		]
	}
	_push_banner(0.3, stage_title, stage_subtitle)
	for wing_index in range(8):
		var wing_time: float = 1.0 + float(wing_index) * 0.3
		_push_enemy(wing_time, {
			"name": "mirror",
			"spawn": Vector2(-42.0, 86.0 + float(wing_index) * 20.0),
			"motion": &"curve",
			"velocity": Vector2(218.0, 124.0),
			"curve_strength": 48.0,
			"hp": 42.0,
			"radius": 18.0,
			"shoot_pattern": &"split_fan",
			"shoot_interval": 0.76,
			"bullet_speed": 240.0,
			"shot_count": 5,
			"spread_deg": 46.0,
			"bullet_shape": &"needle",
			"bullet_color": Color(0.74, 0.98, 1.0),
			"score": 2000,
			"point_drops": 1
		})
		_push_enemy(wing_time + 0.12, {
			"name": "mirror",
			"spawn": Vector2(648.0, 108.0 + float(wing_index) * 20.0),
			"motion": &"curve",
			"velocity": Vector2(-218.0, 124.0),
			"curve_strength": -48.0,
			"hp": 42.0,
			"radius": 18.0,
			"shoot_pattern": &"split_fan",
			"shoot_interval": 0.76,
			"bullet_speed": 240.0,
			"shot_count": 5,
			"spread_deg": 46.0,
			"bullet_shape": &"needle",
			"bullet_color": Color(1.0, 0.78, 0.6),
			"score": 2000,
			"point_drops": 1
		})
	_push_reward(8.8, tr("REWARD_WAVE"), tr("S4_REWARD_1"))
	_push_banner(9.6, tr("S4_BANNER_1"), tr("S4_BANNER_1_SUB"))
	for mirror_index in range(5):
		var mirror_time: float = 10.4 + float(mirror_index) * 0.62
		var mirror_x: float = 96.0 + float(mirror_index) * 96.0
		_push_enemy(mirror_time, {
			"name": "mirror",
			"spawn": Vector2(mirror_x, -60.0),
			"motion": &"approach_hold",
			"destination": Vector2(mirror_x, 152.0),
			"hold_time": 1.8,
			"retreat_velocity": Vector2(0.0, 126.0),
			"approach_speed": 2.0,
			"hp": 68.0,
			"radius": 20.0,
			"shoot_pattern": &"cross_fan",
			"shoot_interval": 0.62,
			"bullet_speed": 202.0,
			"shot_count": 5,
			"spread_deg": 64.0,
			"bullet_shape": &"diamond",
			"bullet_color": Color(0.78, 1.0, 0.96),
			"rotation_step": 0.46,
			"score": 3000,
			"point_drops": 2,
			"power_drops": 1
		})
	for reaper_index in range(4):
		var reaper_time: float = 13.4 + float(reaper_index) * 0.8
		var reaper_x: float = 132.0 if reaper_index % 2 == 0 else 476.0
		_push_enemy(reaper_time, {
			"name": "reaper",
			"spawn": Vector2(reaper_x, -72.0),
			"motion": &"approach_hold",
			"destination": Vector2(reaper_x, 168.0 + float(reaper_index % 2) * 20.0),
			"hold_time": 2.0,
			"retreat_velocity": Vector2(0.0, 136.0),
			"approach_speed": 1.8,
			"hp": 92.0,
			"radius": 22.0,
			"shoot_pattern": &"mine_burst",
			"shoot_interval": 0.96,
			"bullet_speed": 198.0,
			"shot_count": 5,
			"spread_deg": 58.0,
			"ring_count": 10,
			"bullet_shape": &"orb",
			"bullet_color": Color(1.0, 0.66, 0.58),
			"rotation_step": 0.42 if reaper_index % 2 == 0 else -0.42,
			"score": 4200,
			"point_drops": 2,
			"power_drops": 1
		})
	_push_reward(19.4, tr("REWARD_WAVE"), tr("S4_REWARD_2"))
	_push_banner(20.2, tr("S4_BANNER_2"), tr("S4_BANNER_2_SUB"))
	for choir_index in range(6):
		var choir_time: float = 20.8 + float(choir_index) * 0.42
		_push_enemy(choir_time, {
			"name": "reaper",
			"spawn": Vector2(84.0 + float(choir_index) * 92.0, -44.0),
			"motion": &"straight",
			"velocity": Vector2(0.0, 174.0),
			"hp": 46.0,
			"radius": 19.0,
			"shoot_pattern": &"pinwheel",
			"shoot_interval": 0.18,
			"bullet_speed": 204.0,
			"bullet_shape": &"needle",
			"bullet_color": Color(1.0, 0.7, 0.6),
			"rotation_step": 0.34 if choir_index % 2 == 0 else -0.34,
			"score": 2400,
			"point_drops": 2,
			"power_drops": 1
		})
	for wall_index in range(4):
		var wall_time: float = 24.6 + float(wall_index) * 1.0
		_push_enemy(wall_time, {
			"name": "mirror",
			"spawn": Vector2(118.0 + float(wall_index) * 124.0, -76.0),
			"motion": &"approach_hold",
			"destination": Vector2(118.0 + float(wall_index) * 124.0, 160.0),
			"hold_time": 2.2,
			"retreat_velocity": Vector2(0.0, 130.0),
			"approach_speed": 1.75,
			"hp": 132.0,
			"radius": 24.0,
			"shoot_pattern": &"cross_fan",
			"shoot_interval": 0.68,
			"bullet_speed": 208.0,
			"shot_count": 7,
			"spread_deg": 84.0,
			"bullet_shape": &"petal",
			"bullet_color": Color(0.72, 1.0, 0.96),
			"rotation_step": 0.5,
			"score": 5600,
			"point_drops": 3,
			"power_drops": 1
		})
	_push_reward(31.0, tr("REWARD_WAVE"), tr("S4_REWARD_3"))
	_push_banner(31.8, tr("S4_BANNER_3"), tr("S4_BANNER_3_SUB"))
	for storm_index in range(7):
		var storm_time: float = 32.4 + float(storm_index) * 0.4
		_push_enemy(storm_time, {
			"name": "mirror",
			"spawn": Vector2(-36.0, 102.0 + float(storm_index) * 22.0),
			"motion": &"curve",
			"velocity": Vector2(204.0, 124.0),
			"curve_strength": 46.0,
			"hp": 40.0,
			"shoot_pattern": &"split_fan",
			"shoot_interval": 0.66,
			"bullet_speed": 198.0,
			"shot_count": 4,
			"spread_deg": 52.0,
			"bullet_shape": &"diamond",
			"bullet_color": Color(0.72, 0.98, 1.0),
			"score": 2200,
			"point_drops": 2
		})
		_push_enemy(storm_time + 0.18, {
			"name": "reaper",
			"spawn": Vector2(648.0, 124.0 + float(storm_index) * 22.0),
			"motion": &"curve",
			"velocity": Vector2(-204.0, 124.0),
			"curve_strength": -46.0,
			"hp": 40.0,
			"shoot_pattern": &"mine_burst",
			"shoot_interval": 0.96,
			"bullet_speed": 194.0,
			"shot_count": 4,
			"ring_count": 8,
			"spread_deg": 46.0,
			"bullet_shape": &"orb",
			"bullet_color": Color(1.0, 0.66, 0.58),
			"rotation_step": -0.3,
			"score": 2200,
			"point_drops": 2
		})
	for final_guard in range(4):
		_push_enemy(38.8 + float(final_guard) * 1.0, {
			"name": "reaper",
			"spawn": Vector2(102.0 + float(final_guard) * 126.0, -84.0),
			"motion": &"approach_hold",
			"destination": Vector2(102.0 + float(final_guard) * 126.0, 170.0),
			"hold_time": 1.9,
			"retreat_velocity": Vector2(0.0, 138.0),
			"approach_speed": 1.6,
			"hp": 156.0,
			"radius": 26.0,
			"shoot_pattern": &"burst_ring",
			"shoot_interval": 0.68,
			"bullet_speed": 210.0,
			"ring_count": 16,
			"bullet_shape": &"diamond",
			"bullet_color": Color(1.0, 0.8, 0.56),
			"rotation_step": 0.54,
			"score": 6400,
			"point_drops": 3,
			"power_drops": 1
		})
	_push_reward(43.0, tr("REWARD_WAVE"), tr("S4_REWARD_4"))
	_push_dialogue(47.2, {
		"cast": {
			"left": {"accent_color": Color(0.82, 0.3, 0.42), "secondary_color": Color(1.0, 0.92, 0.72), "side": "left", "mood": "angry", "motif": "ribbon"},
			"right": {"accent_color": boss_config["accent_color"], "secondary_color": boss_config["secondary_color"], "side": "right", "mood": boss_config["mood"], "motif": boss_config["motif"]}
		},
		"lines": [
			{"speaker": tr("SPEAKER_PILOT"), "side": "left", "speaker_color": Color(1.0, 0.88, 0.72), "portrait_update": {"mood": "angry", "motif": "ribbon"}, "text": tr("S4_LINE_1")},
			{"speaker": tr("S4_SPEAKER_BOSS"), "side": "right", "speaker_color": boss_config["accent_color"], "portrait_update": {"mood": "angry", "motif": "crown"}, "text": tr("S4_LINE_2")},
			{"speaker": tr("SPEAKER_PILOT"), "side": "left", "speaker_color": Color(1.0, 0.88, 0.72), "portrait_update": {"mood": "soft", "motif": "ribbon"}, "text": tr("S4_LINE_3")}
		]
	})
	_push_banner(47.8, tr("BANNER_BOSS_APPROACH"), boss_config["name"])
	_push_boss(50.2, boss_config)

func _build_stage_five() -> void:
	stage_title = tr("S5_TITLE")
	stage_subtitle = tr("S5_SUBTITLE")
	accent_color = Color(0.96, 0.58, 0.74)
	boss_config = {
		"name": tr("S5_BOSS_NAME"),
		"subtitle": tr("S5_BOSS_SUB"),
		"radius": 44.0,
		"accent_color": Color(1.0, 0.68, 0.62),
		"secondary_color": Color(0.66, 0.94, 1.0),
		"portrait_side": "right",
		"mood": "angry",
		"motif": "crown",
		"phases": [
			{"name": tr("PHASE_ECLIPSE_LATTICE_WHEEL"), "hp": 1260.0, "color": Color(1.0, 0.66, 0.58), "bonus": 180000, "pattern": &"eclipse_lattice", "subtitle": tr("S5_P1_SUB"), "mood": "angry", "motif": "gear", "quote": tr("S5_P1_QUOTE")},
			{"name": tr("PHASE_CROWN_JUDGMENT"), "hp": 1560.0, "color": Color(0.66, 0.96, 1.0), "bonus": 260000, "pattern": &"crown_judgment", "subtitle": tr("S5_P2_SUB"), "mood": "angry", "motif": "crown", "quote": tr("S5_P2_QUOTE")},
			{"name": tr("PHASE_BORDER_CORE_COLLAPSE"), "hp": 1880.0, "color": Color(0.92, 0.58, 1.0), "bonus": 360000, "pattern": &"boundary_collapse", "subtitle": tr("S5_P3_SUB"), "mood": "angry", "motif": "gear", "quote": tr("S5_P3_QUOTE")},
			{"name": tr("PHASE_KEYSTONE_SKYJUDGMENT"), "hp": 2260.0, "color": Color(1.0, 0.92, 0.62), "bonus": 520000, "pattern": &"crown_judgment", "subtitle": tr("S5_P4_SUB"), "mood": "angry", "motif": "crown", "quote": tr("S5_P4_QUOTE")}
		]
	}
	_push_banner(0.3, stage_title, stage_subtitle)
	for opener in range(8):
		var opener_time: float = 1.0 + float(opener) * 0.28
		_push_enemy(opener_time, {
			"name": "mirror",
			"spawn": Vector2(-44.0, 86.0 + float(opener) * 18.0),
			"motion": &"curve",
			"velocity": Vector2(228.0, 126.0),
			"curve_strength": 50.0,
			"hp": 46.0,
			"radius": 18.0,
			"shoot_pattern": &"split_fan",
			"shoot_interval": 0.7,
			"bullet_speed": 244.0,
			"shot_count": 5,
			"spread_deg": 46.0,
			"bullet_shape": &"needle",
			"bullet_color": Color(0.74, 0.98, 1.0),
			"score": 2200,
			"point_drops": 1
		})
		_push_enemy(opener_time + 0.12, {
			"name": "reaper",
			"spawn": Vector2(650.0, 110.0 + float(opener) * 18.0),
			"motion": &"curve",
			"velocity": Vector2(-228.0, 126.0),
			"curve_strength": -50.0,
			"hp": 46.0,
			"radius": 18.0,
			"shoot_pattern": &"mine_burst",
			"shoot_interval": 0.92,
			"bullet_speed": 206.0,
			"ring_count": 8,
			"shot_count": 4,
			"spread_deg": 44.0,
			"bullet_shape": &"orb",
			"bullet_color": Color(1.0, 0.68, 0.58),
			"score": 2200,
			"point_drops": 1
		})
	_push_reward(8.6, tr("REWARD_WAVE"), tr("S5_REWARD_1"))
	_push_banner(9.4, tr("S5_BANNER_1"), tr("S5_BANNER_1_SUB"))
	for core_index in range(5):
		var core_time: float = 10.0 + float(core_index) * 0.68
		var core_x: float = 98.0 + float(core_index) * 94.0
		_push_enemy(core_time, {
			"name": "anchor",
			"spawn": Vector2(core_x, -62.0),
			"motion": &"approach_hold",
			"destination": Vector2(core_x, 150.0 + float(core_index % 2) * 24.0),
			"hold_time": 1.9,
			"retreat_velocity": Vector2(0.0, 128.0),
			"approach_speed": 2.0,
			"hp": 80.0,
			"radius": 20.0,
			"shoot_pattern": &"split_fan",
			"shoot_interval": 0.6,
			"bullet_speed": 214.0,
			"shot_count": 5,
			"spread_deg": 66.0,
			"bullet_shape": &"diamond",
			"bullet_color": Color(0.78, 1.0, 0.96),
			"rotation_step": 0.48,
			"score": 3400,
			"point_drops": 2,
			"power_drops": 1
		})
	for burst_index in range(4):
		var burst_time: float = 13.6 + float(burst_index) * 0.96
		var burst_x: float = 136.0 if burst_index % 2 == 0 else 474.0
		_push_enemy(burst_time, {
			"name": "shade",
			"spawn": Vector2(burst_x, -72.0),
			"motion": &"approach_hold",
			"destination": Vector2(burst_x, 170.0 + float(burst_index % 2) * 18.0),
			"hold_time": 2.1,
			"retreat_velocity": Vector2(0.0, 138.0),
			"approach_speed": 1.8,
			"hp": 108.0,
			"radius": 22.0,
			"shoot_pattern": &"mine_burst",
			"shoot_interval": 0.88,
			"bullet_speed": 210.0,
			"ring_count": 10,
			"shot_count": 5,
			"spread_deg": 56.0,
			"bullet_shape": &"orb",
			"bullet_color": Color(1.0, 0.7, 0.6),
			"rotation_step": 0.42 if burst_index % 2 == 0 else -0.42,
			"score": 4600,
			"point_drops": 2,
			"power_drops": 1
		})
	_push_reward(19.2, tr("REWARD_WAVE"), tr("S5_REWARD_2"))
	_push_banner(20.0, tr("S5_BANNER_2"), tr("S5_BANNER_2_SUB"))
	for lane_index in range(7):
		var lane_time: float = 20.6 + float(lane_index) * 0.36
		_push_enemy(lane_time, {
			"name": "mirror",
			"spawn": Vector2(82.0 + float(lane_index) * 68.0, -46.0),
			"motion": &"straight",
			"velocity": Vector2(0.0, 182.0),
			"hp": 48.0,
			"radius": 18.0,
			"shoot_pattern": &"pinwheel",
			"shoot_interval": 0.16,
			"bullet_speed": 212.0,
			"bullet_shape": &"needle",
			"bullet_color": Color(0.74, 0.98, 1.0),
			"rotation_step": 0.36 if lane_index % 2 == 0 else -0.36,
			"score": 2500,
			"point_drops": 2
		})
		_push_enemy(lane_time + 0.18, {
			"name": "reaper",
			"spawn": Vector2(96.0 + float(lane_index) * 68.0, -60.0),
			"motion": &"straight",
			"velocity": Vector2(0.0, 168.0),
			"hp": 46.0,
			"radius": 18.0,
			"shoot_pattern": &"split_fan",
			"shoot_interval": 0.62,
			"bullet_speed": 224.0,
			"shot_count": 4,
			"spread_deg": 52.0,
			"bullet_shape": &"diamond",
			"bullet_color": Color(1.0, 0.68, 0.58),
			"score": 2500,
			"point_drops": 2
		})
	for guard_index in range(4):
		var guard_time: float = 24.8 + float(guard_index) * 1.04
		_push_enemy(guard_time, {
			"name": "guardian",
			"spawn": Vector2(104.0 + float(guard_index) * 120.0, -84.0),
			"motion": &"approach_hold",
			"destination": Vector2(104.0 + float(guard_index) * 120.0, 166.0),
			"hold_time": 2.0,
			"retreat_velocity": Vector2(0.0, 136.0),
			"approach_speed": 1.7,
			"hp": 146.0,
			"radius": 24.0,
			"shoot_pattern": &"cross_fan",
			"shoot_interval": 0.66,
			"bullet_speed": 220.0,
			"shot_count": 7,
			"spread_deg": 82.0,
			"bullet_shape": &"petal",
			"bullet_color": Color(0.88, 0.62, 1.0),
			"rotation_step": 0.52,
			"score": 6200,
			"point_drops": 3,
			"power_drops": 1
		})
	_push_reward(31.0, tr("REWARD_WAVE"), tr("S5_REWARD_3"))
	_push_banner(31.8, tr("S5_BANNER_3"), tr("S5_BANNER_3_SUB"))
	for storm_index in range(8):
		var storm_time: float = 32.2 + float(storm_index) * 0.36
		_push_enemy(storm_time, {
			"name": "anchor",
			"spawn": Vector2(-38.0, 98.0 + float(storm_index) * 20.0),
			"motion": &"curve",
			"velocity": Vector2(214.0, 126.0),
			"curve_strength": 48.0,
			"hp": 42.0,
			"shoot_pattern": &"split_fan",
			"shoot_interval": 0.58,
			"bullet_speed": 214.0,
			"shot_count": 4,
			"spread_deg": 48.0,
			"bullet_shape": &"diamond",
			"bullet_color": Color(0.72, 0.98, 1.0),
			"score": 2300,
			"point_drops": 2
		})
		_push_enemy(storm_time + 0.16, {
			"name": "shade",
			"spawn": Vector2(650.0, 120.0 + float(storm_index) * 20.0),
			"motion": &"curve",
			"velocity": Vector2(-214.0, 126.0),
			"curve_strength": -48.0,
			"hp": 42.0,
			"shoot_pattern": &"mine_burst",
			"shoot_interval": 0.84,
			"bullet_speed": 204.0,
			"ring_count": 8,
			"shot_count": 4,
			"spread_deg": 44.0,
			"bullet_shape": &"orb",
			"bullet_color": Color(1.0, 0.68, 0.58),
			"score": 2300,
			"point_drops": 2
		})
	for preboss in range(5):
		_push_enemy(39.2 + float(preboss) * 0.9, {
			"name": "reaper",
			"spawn": Vector2(90.0 + float(preboss) * 110.0, -86.0),
			"motion": &"approach_hold",
			"destination": Vector2(90.0 + float(preboss) * 110.0, 170.0),
			"hold_time": 1.8,
			"retreat_velocity": Vector2(0.0, 144.0),
			"approach_speed": 1.6,
			"hp": 172.0,
			"radius": 26.0,
			"shoot_pattern": &"burst_ring",
			"shoot_interval": 0.66,
			"bullet_speed": 218.0,
			"ring_count": 18,
			"bullet_shape": &"diamond",
			"bullet_color": Color(1.0, 0.82, 0.58),
			"rotation_step": 0.56,
			"score": 7000,
			"point_drops": 3,
			"power_drops": 1
		})
	_push_reward(43.2, tr("REWARD_WAVE"), tr("S5_REWARD_4"))
	_push_dialogue(47.0, {
		"cast": {
			"left": {"accent_color": Color(0.82, 0.3, 0.42), "secondary_color": Color(1.0, 0.92, 0.72), "side": "left", "mood": "angry", "motif": "ribbon"},
			"right": {"accent_color": boss_config["accent_color"], "secondary_color": boss_config["secondary_color"], "side": "right", "mood": boss_config["mood"], "motif": boss_config["motif"]}
		},
		"lines": [
			{"speaker": tr("SPEAKER_PILOT"), "side": "left", "speaker_color": Color(1.0, 0.88, 0.72), "portrait_update": {"mood": "angry", "motif": "ribbon"}, "text": tr("S5_LINE_1")},
			{"speaker": tr("S5_SPEAKER_BOSS"), "side": "right", "speaker_color": boss_config["accent_color"], "portrait_update": {"mood": "angry", "motif": "crown"}, "text": tr("S5_LINE_2")},
			{"speaker": tr("SPEAKER_PILOT"), "side": "left", "speaker_color": Color(1.0, 0.88, 0.72), "portrait_update": {"mood": "soft", "motif": "ribbon"}, "text": tr("S5_LINE_3")}
		]
	})
	_push_banner(47.8, tr("BANNER_BOSS_APPROACH"), boss_config["name"])
	_push_boss(50.4, boss_config)
