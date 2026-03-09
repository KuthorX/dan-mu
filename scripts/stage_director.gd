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

func _push_banner(time: float, title: String, subtitle := "") -> void:
	events.append({"time": time, "type": "banner", "title": title, "subtitle": subtitle})

func _push_enemy(time: float, config: Dictionary) -> void:
	events.append({"time": time, "type": "enemy", "config": config})

func _push_boss(time: float, config := {}) -> void:
	events.append({"time": time, "type": "boss", "config": config})

func _push_dialogue(time: float, scene: Dictionary) -> void:
	events.append({"time": time, "type": "dialogue", "scene": scene})

func _build_events() -> void:
	events.clear()
	if stage_index == 2:
		_build_stage_two()
	else:
		_build_stage_one()

func _build_stage_one() -> void:
	stage_title = "Stage 1 · Starlit Boundary"
	stage_subtitle = "穿过霓虹星海的试炼"
	accent_color = Color(0.54, 0.92, 1.0)
	boss_config = {
		"name": "Boundary Watcher · 星界秘主",
		"subtitle": "星界边缘的守望者",
		"radius": 34.0,
		"accent_color": Color(1.0, 0.84, 0.54),
		"secondary_color": Color(0.56, 0.92, 1.0),
		"portrait_side": "right",
		"mood": "calm",
		"motif": "halo",
		"phases": [
			{"name": "Nonspell · Scarlet Spiral", "hp": 420.0, "color": Color(1.0, 0.45, 0.68), "bonus": 40000, "pattern": &"scarlet_spiral", "subtitle": "试探性的星屑螺旋", "mood": "calm", "motif": "halo", "quote": "先试着跟上我的星轨吧。"},
			{"name": "Spell · Moon Petal Cage", "hp": 560.0, "color": Color(0.58, 0.95, 1.0), "bonus": 70000, "pattern": &"moon_petals", "subtitle": "月瓣收束的包围阵", "mood": "soft", "motif": "ribbon", "quote": "月色会替我关上退路。"},
			{"name": "Spell · Prism Cascade", "hp": 700.0, "color": Color(0.76, 0.62, 1.0), "bonus": 100000, "pattern": &"prism_cascade", "subtitle": "折射层层堆叠的星雨", "mood": "soft", "motif": "crown", "quote": "每一道折光，都会成为新的边界。"},
			{"name": "Last Spell · Falling Star Border", "hp": 860.0, "color": Color(1.0, 0.88, 0.46), "bonus": 150000, "pattern": &"falling_star", "subtitle": "坠星边界的最终压制", "mood": "angry", "motif": "crown", "quote": "把你的退路与天穹一起压碎。"}
		]
	}
	_push_banner(0.3, stage_title, stage_subtitle)
	for index_opening in range(5):
		var opening_time: float = 1.4 + float(index_opening) * 0.48
		_push_enemy(opening_time, {
			"name": "fairy",
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
			"name": "fairy",
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
	_push_banner(13.0, "Mid Stage", "弹幕密度开始上升")
	for spinner_index in range(3):
		var center_x: float = 160.0 + float(spinner_index) * 110.0
		_push_enemy(14.2 + float(spinner_index) * 1.1, {
			"name": "spinner",
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
	_push_banner(31.2, "Pressure Up", "交错波次与环形弹同步出现")
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
			{"speaker": "洛天依", "side": "left", "speaker_color": Color(1.0, 0.88, 0.72), "portrait_update": {"mood": "calm", "motif": "ribbon"}, "text": "这片边界的星光有点太吵了……你就是在操纵这场弹幕的人？"},
			{"speaker": "星界秘主", "side": "right", "speaker_color": boss_config["accent_color"], "portrait_update": {"mood": "soft", "motif": "halo"}, "text": "访客啊，若想穿过星界边缘，就用你的轨迹证明自己。"},
			{"speaker": "洛天依", "side": "left", "speaker_color": Color(1.0, 0.88, 0.72), "portrait_update": {"mood": "angry", "motif": "ribbon"}, "text": "那我就不客气了。先把你的符卡拆开，再去下一层。"}
		]
	})
	_push_banner(46.4, "Boss Approaching", boss_config["name"])
	_push_boss(48.6, boss_config)

func _build_stage_two() -> void:
	stage_title = "Stage 2 · Aurora Furnace"
	stage_subtitle = "穿行熔色极光与磁暴回廊"
	accent_color = Color(1.0, 0.68, 0.42)
	boss_config = {
		"name": "Forge Warden · 炼狱魔王",
		"subtitle": "磁暴边界的熔炉守卫",
		"radius": 38.0,
		"accent_color": Color(1.0, 0.74, 0.42),
		"secondary_color": Color(0.58, 0.96, 1.0),
		"portrait_side": "right",
		"mood": "angry",
		"motif": "gear",
		"phases": [
			{"name": "Nonspell · Magnetic Bloom", "hp": 540.0, "color": Color(1.0, 0.64, 0.42), "bonus": 70000, "pattern": &"magnetic_bloom", "subtitle": "磁化花阵的压迫试探", "mood": "angry", "motif": "gear", "quote": "炉心才刚刚升温。"},
			{"name": "Spell · Aurora Lattice", "hp": 720.0, "color": Color(0.48, 0.94, 1.0), "bonus": 110000, "pattern": &"aurora_lattice", "subtitle": "极光格构封锁回廊", "mood": "calm", "motif": "halo", "quote": "极光会把你的每一步都记录下来。"},
			{"name": "Spell · Comet Refinery", "hp": 880.0, "color": Color(0.86, 0.56, 1.0), "bonus": 150000, "pattern": &"comet_refinery", "subtitle": "彗星熔炼的高速压线", "mood": "angry", "motif": "gear", "quote": "把星火压进熔炉，再让它们全部向你倾倒。"},
			{"name": "Last Spell · Boundary Collapse Furnace", "hp": 1080.0, "color": Color(1.0, 0.88, 0.52), "bonus": 220000, "pattern": &"boundary_collapse", "subtitle": "边界坍缩前的最终熔断", "mood": "angry", "motif": "crown", "quote": "边界一旦塌陷，就连回旋的余地也不会留下。"}
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
	_push_banner(13.5, "Aurora Weave", "曲线弹与纵向幕墙开始叠加")
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
	_push_banner(33.5, "Pressure Surge", "磁暴幕墙开始与旋转花瓣交错")
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
			{"speaker": "洛天依", "side": "left", "speaker_color": Color(1.0, 0.88, 0.72), "portrait_update": {"mood": "soft", "motif": "ribbon"}, "text": "极光后面居然是熔炉……难怪第二关的弹幕这么烫。"},
			{"speaker": "炼狱魔王", "side": "right", "speaker_color": boss_config["accent_color"], "portrait_update": {"mood": "angry", "motif": "gear"}, "text": "能走到这里，已经值得夸奖。但边界坍缩前，你一步也别想再往前。"},
			{"speaker": "洛天依", "side": "left", "speaker_color": Color(1.0, 0.88, 0.72), "portrait_update": {"mood": "angry", "motif": "ribbon"}, "text": "那就看看是你的炉火更凶，还是我的避弹线更稳。"}
		]
	})
	_push_banner(46.2, "Boss Approaching", boss_config["name"])
	_push_boss(48.8, boss_config)
