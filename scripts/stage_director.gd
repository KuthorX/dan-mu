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
			game.offer_wave_reward(event.get("title", "波次奖励"), event.get("subtitle", ""))

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
	stage_title = "第一关 · 星光边界"
	stage_subtitle = "穿过霓虹星海的试炼"
	accent_color = Color(0.54, 0.92, 1.0)
	boss_config = {
		"name": "边界守望者 · 星界秘主",
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
	_push_banner(13.0, "中段压制", "弹幕密度开始上升")
	_push_reward(12.1, "波次奖励", "开场波次已突破——选择一项加护。")
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
	_push_banner(31.2, "压制升级", "交错波次与环形弹同步出现")
	_push_reward(30.4, "波次奖励", "星轨战线已稳住——挑选你的下一项成长。")
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
	_push_reward(41.0, "波次奖励", "高压波次已清空——领取一项强化。")
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
	_push_banner(46.4, "首领逼近", boss_config["name"])
	_push_boss(48.6, boss_config)

func _build_stage_two() -> void:
	stage_title = "第二关 · 极光熔炉"
	stage_subtitle = "穿行熔色极光与磁暴回廊"
	accent_color = Color(1.0, 0.68, 0.42)
	boss_config = {
		"name": "熔炉守卫 · 炼狱魔王",
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
	_push_banner(13.5, "极光织幕", "曲线弹与纵向幕墙开始叠加")
	_push_reward(12.9, "波次奖励", "极光遭遇战已结束——选择一项强化。")
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
	_push_banner(33.5, "压制激增", "磁暴幕墙开始与旋转花瓣交错")
	_push_reward(32.8, "波次奖励", "熔炉战线已击穿——选择你的下一项优势。")
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
	_push_reward(41.5, "波次奖励", "风暴格阵已粉碎——收下一项奖励。")
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
	_push_banner(46.2, "首领逼近", boss_config["name"])
	_push_boss(48.8, boss_config)

func _build_stage_three() -> void:
	stage_title = "第三关 · 残垣之巅"
	stage_subtitle = "穿过崩塌要塞的边缘，攀上残垣之巅。"
	accent_color = Color(0.72, 0.66, 1.0)
	boss_config = {
		"name": "要塞裁定者 · 夜垣向量",
		"subtitle": "破碎边界王冠的看守者。",
		"radius": 40.0,
		"accent_color": Color(0.92, 0.62, 1.0),
		"secondary_color": Color(0.52, 0.96, 1.0),
		"portrait_side": "right",
		"mood": "angry",
		"motif": "crown",
		"phases": [
			{"name": "非符 · 磁花绽放", "hp": 760.0, "color": Color(1.0, 0.66, 0.48), "bonus": 100000, "pattern": &"magnetic_bloom", "subtitle": "废墟核心绽开，螺旋花瓣层层展开。", "mood": "angry", "motif": "gear", "quote": "你的道路，止于王冠开始之处。"},
			{"name": "符卡 · 极光格阵", "hp": 980.0, "color": Color(0.52, 0.94, 1.0), "bonus": 150000, "pattern": &"aurora_lattice", "subtitle": "冻结的线条封锁整片天空。", "mood": "calm", "motif": "halo", "quote": "你绘出的每一道回避轨迹，都已落在我的格阵之中。"},
			{"name": "符卡 · 彗星炼炉", "hp": 1240.0, "color": Color(0.86, 0.58, 1.0), "bonus": 210000, "pattern": &"comet_refinery", "subtitle": "要塞碎片如同锻造群星般倾泻而下。", "mood": "angry", "motif": "gear", "quote": "那就让这片废墟来锤炼你的勇气吧。"},
			{"name": "终符 · 边界崩塌", "hp": 1540.0, "color": Color(1.0, 0.88, 0.56), "bonus": 320000, "pattern": &"boundary_collapse", "subtitle": "整座堡垒折叠成最后一道压制之墙。", "mood": "angry", "motif": "crown", "quote": "现在，亲眼看着整条边界一同坠落吧。"}
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
	_push_reward(9.2, "波次奖励", "外环已突破——选择新的锋芒。")
	_push_banner(10.0, "废墟轨道", "交叉火力与回旋哨戒开始收束战场。")
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
	_push_reward(18.8, "波次奖励", "轨道战线已稳住——领取新的强化。")
	_push_banner(19.6, "要塞封锁", "重装守卫将层层环阵刻入通道。")
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
	_push_reward(30.4, "波次奖励", "要塞封锁已破——选择下一项优势。")
	_push_banner(31.2, "崩流压境", "两翼风暴交错收缩，整条通道被挤压闭合。")
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
	_push_reward(41.6, "波次奖励", "最终通道已打通——在 Boss 前收下最后一项加护。")
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
			{"speaker": "自机", "side": "left", "speaker_color": Color(1.0, 0.88, 0.72), "portrait_update": {"mood": "angry", "motif": "ribbon"}, "text": "原来这就是边界的顶端……难怪下面的一切都想拦住我。"},
			{"speaker": "夜垣向量", "side": "right", "speaker_color": boss_config["accent_color"], "portrait_update": {"mood": "angry", "motif": "crown"}, "text": "所有断裂的轨迹，最终都会回归王冠。把你的也展示给我看。"},
			{"speaker": "自机", "side": "left", "speaker_color": Color(1.0, 0.88, 0.72), "portrait_update": {"mood": "soft", "motif": "ribbon"}, "text": "那我就亲手在整片废墟中劈出一条新路。"}
		]
	})
	_push_banner(47.6, "首领逼近", boss_config["name"])
	_push_boss(50.0, boss_config)

func _build_stage_four() -> void:
	stage_title = "第四关 · 蚀冕终庭"
	stage_subtitle = "攀上边界最终崩塌的王座。"
	accent_color = Color(1.0, 0.64, 0.58)
	boss_config = {
		"name": "蚀冕君主 · 星终阿斯特拉",
		"subtitle": "破碎边界背后的最终意志。",
		"radius": 42.0,
		"accent_color": Color(1.0, 0.7, 0.56),
		"secondary_color": Color(0.64, 0.9, 1.0),
		"portrait_side": "right",
		"mood": "angry",
		"motif": "crown",
		"phases": [
			{"name": "非符 · 棱镜螺旋", "hp": 980.0, "color": Color(1.0, 0.64, 0.56), "bonus": 140000, "pattern": &"scarlet_spiral", "subtitle": "高速镜像环阵覆盖整个中场。", "mood": "angry", "motif": "gear", "quote": "别再向上了，王冠早已选好了属于它的天空。"},
			{"name": "符卡 · 坠格封天", "hp": 1260.0, "color": Color(0.62, 0.94, 1.0), "bonus": 220000, "pattern": &"aurora_lattice", "subtitle": "幕墙与格线一同封死所有通路。", "mood": "calm", "motif": "halo", "quote": "我会把你以为安全的每条路线全部折断。"},
			{"name": "符卡 · 冕炉炼星", "hp": 1540.0, "color": Color(0.92, 0.58, 1.0), "bonus": 300000, "pattern": &"comet_refinery", "subtitle": "锻造之星穿过收拢幕面，成排坠落。", "mood": "angry", "motif": "gear", "quote": "那就让你的勇气，在彻底的压迫里被炼成吧。"},
			{"name": "终符 · 终境崩灭", "hp": 1880.0, "color": Color(1.0, 0.9, 0.58), "bonus": 420000, "pattern": &"boundary_collapse", "subtitle": "王座本身会化作最后一道弹幕之墙轰然坠下。", "mood": "angry", "motif": "crown", "quote": "见证整条边界在最后一次爆发中终结吧。"}
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
	_push_reward(8.8, "波次奖励", "外环冕线已碎——选择新的锋芒。")
	_push_banner(9.6, "镜翼坠阵", "镜像与哨戒一同向内折叠通道。")
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
	_push_reward(19.4, "波次奖励", "中层冕路已经打开——挑一项更稀有的强化。")
	_push_banner(20.2, "收割合唱", "分层弧幕与延迟爆发一同压缩屏幕空间。")
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
	_push_reward(31.0, "波次奖励", "内环冕面已裂——不妨刷新寻找更强的机会。")
	_push_banner(31.8, "王座激流", "沉重的侧翼风暴与镜像雷阵同时逼近。")
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
	_push_reward(43.0, "波次奖励", "王座长廊已开——在终局前收下最后一手强化。")
	_push_dialogue(47.2, {
		"cast": {
			"left": {"accent_color": Color(0.82, 0.3, 0.42), "secondary_color": Color(1.0, 0.92, 0.72), "side": "left", "mood": "angry", "motif": "ribbon"},
			"right": {"accent_color": boss_config["accent_color"], "secondary_color": boss_config["secondary_color"], "side": "right", "mood": boss_config["mood"], "motif": boss_config["motif"]}
		},
		"lines": [
			{"speaker": "自机", "side": "left", "speaker_color": Color(1.0, 0.88, 0.72), "portrait_update": {"mood": "angry", "motif": "ribbon"}, "text": "原来这里就是王冠真正的中心。"},
			{"speaker": "星终阿斯特拉", "side": "right", "speaker_color": boss_config["accent_color"], "portrait_update": {"mood": "angry", "motif": "crown"}, "text": "你侥幸穿过的每一道轨迹，都只是通向我的走廊。"},
			{"speaker": "自机", "side": "left", "speaker_color": Color(1.0, 0.88, 0.72), "portrait_update": {"mood": "soft", "motif": "ribbon"}, "text": "那我就用最后一条轨迹，把整座王座一并击碎。"}
		]
	})
	_push_banner(47.8, "首领逼近", boss_config["name"])
	_push_boss(50.2, boss_config)

func _build_stage_five() -> void:
	stage_title = "第五关 · 终界天穹"
	stage_subtitle = "踏入边界尽头，迎战一切轨迹的终点。"
	accent_color = Color(0.96, 0.58, 0.74)
	boss_config = {
		"name": "终界裁决者 · 星穹终钥",
		"subtitle": "守在一切弹道尽头的最终门扉。",
		"radius": 44.0,
		"accent_color": Color(1.0, 0.68, 0.62),
		"secondary_color": Color(0.66, 0.94, 1.0),
		"portrait_side": "right",
		"mood": "angry",
		"motif": "crown",
		"phases": [
			{"name": "非符 · 蚀界格轮", "hp": 1260.0, "color": Color(1.0, 0.66, 0.58), "bonus": 180000, "pattern": &"eclipse_lattice", "subtitle": "全屏格轮与边角压线同步推进。", "mood": "angry", "motif": "gear", "quote": "终界之前，任何路线都只会变成囚笼。"},
			{"name": "符卡 · 王冠裁断", "hp": 1560.0, "color": Color(0.66, 0.96, 1.0), "bonus": 260000, "pattern": &"crown_judgment", "subtitle": "追身收束与高压坠幕同时审判。", "mood": "angry", "motif": "crown", "quote": "你所躲开的，不过是我尚未落下的判决。"},
			{"name": "符卡 · 边界坍核", "hp": 1880.0, "color": Color(0.92, 0.58, 1.0), "bonus": 360000, "pattern": &"boundary_collapse", "subtitle": "整片场地开始被层层坍缩挤压。", "mood": "angry", "motif": "gear", "quote": "当边界开始收缩，连喘息都会成为奢望。"},
			{"name": "终符 · 终钥裁天", "hp": 2260.0, "color": Color(1.0, 0.92, 0.62), "bonus": 520000, "pattern": &"crown_judgment", "subtitle": "最终审判覆盖整个天穹，所有空隙尽数闭合。", "mood": "angry", "motif": "crown", "quote": "来吧，在终点前证明你的最后一条轨迹。"}
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
	_push_reward(8.6, "波次奖励", "终界前哨已破——先稳住你的节奏。")
	_push_banner(9.4, "终界交叉", "高压扇面与延迟雷阵开始联锁。")
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
	_push_reward(19.2, "波次奖励", "交叉压制已被撕开——拿一项更狠的强化。")
	_push_banner(20.0, "终钥回廊", "纵列坠幕与追身扇形开始封死中路。")
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
	_push_reward(31.0, "波次奖励", "终钥回廊已穿透——如果不满意，记得刷新。")
	_push_banner(31.8, "终界坍潮", "双侧崩流开始把整片场地推向中心。")
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
	_push_reward(43.2, "波次奖励", "终界门扉已开——在最终 Boss 前做最后整备。")
	_push_dialogue(47.0, {
		"cast": {
			"left": {"accent_color": Color(0.82, 0.3, 0.42), "secondary_color": Color(1.0, 0.92, 0.72), "side": "left", "mood": "angry", "motif": "ribbon"},
			"right": {"accent_color": boss_config["accent_color"], "secondary_color": boss_config["secondary_color"], "side": "right", "mood": boss_config["mood"], "motif": boss_config["motif"]}
		},
		"lines": [
			{"speaker": "自机", "side": "left", "speaker_color": Color(1.0, 0.88, 0.72), "portrait_update": {"mood": "angry", "motif": "ribbon"}, "text": "原来边界尽头，连天空都会像门一样合上。"},
			{"speaker": "星穹终钥", "side": "right", "speaker_color": boss_config["accent_color"], "portrait_update": {"mood": "angry", "motif": "crown"}, "text": "你走到这里，便该明白——所有轨迹最终都归我裁决。"},
			{"speaker": "自机", "side": "left", "speaker_color": Color(1.0, 0.88, 0.72), "portrait_update": {"mood": "soft", "motif": "ribbon"}, "text": "那我就用最后一次闪避，把你的终点也一起改写。"}
		]
	})
	_push_banner(47.8, "首领逼近", boss_config["name"])
	_push_boss(50.4, boss_config)
