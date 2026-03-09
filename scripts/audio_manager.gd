extends Node

const SAMPLE_RATE := 16000

var bgm_player: AudioStreamPlayer
var jingle_player: AudioStreamPlayer
var sfx_players: Array = []
var sfx_index := 0
var bgm_streams := {}
var sfx_streams := {}
var clock := 0.0
var cooldowns := {}
var current_bgm_key := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_players()
	_build_streams()

func _process(delta: float) -> void:
	clock += delta

func play_title_theme() -> void:
	_play_bgm("title")

func play_stage_theme(stage_number: int) -> void:
	var key := "stage_%d" % stage_number
	if not bgm_streams.has(key):
		key = "stage_2"
	_play_bgm(key)

func play_boss_theme(stage_number: int) -> void:
	var key := "boss_%d" % stage_number
	if not bgm_streams.has(key):
		key = "boss_2"
	_play_bgm(key)

func stop_bgm() -> void:
	current_bgm_key = ""
	if bgm_player:
		bgm_player.stop()

func play_confirm() -> void:
	_play_sfx("confirm", 0.03, -9.0)

func play_pause() -> void:
	_play_sfx("pause", 0.05, -10.0)

func play_player_shot(focus_ratio: float) -> void:
	if focus_ratio > 0.55:
		_play_sfx("shot_focus", 0.04, -16.5)
	else:
		_play_sfx("shot", 0.04, -16.5)

func play_enemy_fire(pattern: StringName) -> void:
	match pattern:
		&"spiral", &"burst_ring":
			_play_sfx("enemy_spiral", 0.12, -15.0)
		&"ring", &"wall":
			_play_sfx("enemy_ring", 0.18, -15.5)
		_:
			_play_sfx("enemy_fire", 0.1, -16.0)

func play_graze() -> void:
	_play_sfx("graze", 0.03, -11.0)

func play_pickup(power_item: bool) -> void:
	_play_sfx("pickup_power" if power_item else "pickup", 0.04, -10.0)

func play_enemy_down() -> void:
	_play_sfx("enemy_down", 0.02, -11.0)

func play_player_hit() -> void:
	_play_sfx("player_hit", 0.08, -9.0)

func play_bomb() -> void:
	_play_sfx("bomb", 0.12, -6.5)

func play_phase_break() -> void:
	_play_sfx("phase_break", 0.18, -7.5)

func play_stage_transition() -> void:
	_play_jingle("transition")

func play_stage_clear() -> void:
	_play_jingle("stage_clear")

func play_game_clear() -> void:
	_play_jingle("game_clear")

func _build_players() -> void:
	bgm_player = AudioStreamPlayer.new()
	bgm_player.volume_db = -18.0
	add_child(bgm_player)
	jingle_player = AudioStreamPlayer.new()
	jingle_player.volume_db = -10.0
	add_child(jingle_player)
	for _index in range(8):
		var player := AudioStreamPlayer.new()
		player.volume_db = -10.0
		add_child(player)
		sfx_players.append(player)

func _play_bgm(key: String) -> void:
	if current_bgm_key == key and bgm_player.playing:
		return
	current_bgm_key = key
	if bgm_streams.has(key):
		bgm_player.stream = bgm_streams[key]
		bgm_player.play()

func _play_jingle(key: String) -> void:
	if sfx_streams.has(key):
		jingle_player.stream = sfx_streams[key]
		jingle_player.play()

func _play_sfx(key: String, cooldown: float, volume_db: float) -> void:
	var next_allowed: float = cooldowns.get(key, -100.0)
	if clock < next_allowed:
		return
	cooldowns[key] = clock + cooldown
	if not sfx_streams.has(key):
		return
	var player: AudioStreamPlayer = sfx_players[sfx_index]
	sfx_index = (sfx_index + 1) % max(1, sfx_players.size())
	player.stream = sfx_streams[key]
	player.volume_db = volume_db
	player.play()

func _build_streams() -> void:
	bgm_streams["title"] = _build_song_stream(_song_title())
	bgm_streams["stage_1"] = _build_song_stream(_song_stage_one())
	bgm_streams["boss_1"] = _build_song_stream(_song_boss_one())
	bgm_streams["stage_2"] = _build_song_stream(_song_stage_two())
	bgm_streams["boss_2"] = _build_song_stream(_song_boss_two())
	bgm_streams["stage_5"] = _build_song_stream(_song_endless_stage())
	bgm_streams["boss_5"] = _build_song_stream(_song_endless_boss())
	sfx_streams["confirm"] = _build_confirm_stream()
	sfx_streams["pause"] = _build_pause_stream()
	sfx_streams["shot"] = _build_shot_stream(false)
	sfx_streams["shot_focus"] = _build_shot_stream(true)
	sfx_streams["enemy_fire"] = _build_enemy_fire_stream(false)
	sfx_streams["enemy_ring"] = _build_enemy_fire_stream(true)
	sfx_streams["enemy_spiral"] = _build_enemy_spiral_stream()
	sfx_streams["graze"] = _build_graze_stream()
	sfx_streams["pickup"] = _build_pickup_stream(false)
	sfx_streams["pickup_power"] = _build_pickup_stream(true)
	sfx_streams["enemy_down"] = _build_enemy_down_stream()
	sfx_streams["player_hit"] = _build_player_hit_stream()
	sfx_streams["bomb"] = _build_bomb_stream()
	sfx_streams["phase_break"] = _build_phase_break_stream()
	sfx_streams["transition"] = _build_transition_stream()
	sfx_streams["stage_clear"] = _build_stage_clear_stream()
	sfx_streams["game_clear"] = _build_game_clear_stream()

func _song_title() -> Dictionary:
	var lead_a: Array = [76, -1, 79, -1, 83, -1, 84, -1, 83, -1, 79, -1, 76, -1, 74, -1]
	var lead_b: Array = [76, -1, 79, -1, 83, -1, 86, -1, 84, -1, 83, -1, 79, -1, 76, -1]
	var arp_a: Array = [64, 71, 76, 71, 67, 71, 79, 71, 69, 72, 76, 72, 67, 71, 76, 71]
	var arp_b: Array = [64, 71, 76, 71, 67, 71, 79, 71, 71, 74, 79, 74, 67, 71, 76, 71]
	var bass_a: Array = [40, -1, -1, -1, 40, -1, -1, -1, 43, -1, -1, -1, 43, -1, -1, -1]
	var bass_b: Array = [45, -1, -1, -1, 45, -1, -1, -1, 43, -1, -1, -1, 43, -1, -1, -1]
	return {
		"bpm": 132.0,
		"lead": _cat([lead_a, lead_b, lead_a, lead_b]),
		"counter": _cat([arp_a, arp_b, arp_a, arp_b]),
		"bass": _cat([bass_a, bass_a, bass_b, bass_b]),
		"kick": _cat([_four_on_floor(), _four_on_floor(), _four_on_floor(), _four_on_floor()]),
		"snare": _cat([_backbeat(), _backbeat(), _backbeat(), _backbeat()]),
		"hat": _repeat_hits(64, 2)
	}

func _song_stage_one() -> Dictionary:
	var lead_a: Array = [79, -1, 81, -1, 83, -1, 86, -1, 83, -1, 81, -1, 79, -1, 76, -1]
	var lead_b: Array = [79, -1, 81, 83, 84, -1, 86, -1, 88, -1, 86, -1, 84, -1, 83, -1]
	var lead_c: Array = [88, -1, 86, -1, 84, -1, 83, -1, 81, -1, 79, -1, 78, -1, 76, -1]
	var arp_a: Array = [67, 74, 79, 74, 69, 76, 81, 76, 71, 78, 83, 78, 74, 81, 86, 81]
	var arp_b: Array = [67, 74, 79, 74, 71, 78, 83, 78, 72, 79, 84, 79, 74, 81, 86, 81]
	var bass_a: Array = [43, -1, -1, -1, 43, -1, -1, -1, 45, -1, -1, -1, 45, -1, -1, -1]
	var bass_b: Array = [47, -1, -1, -1, 47, -1, -1, -1, 48, -1, -1, -1, 48, -1, -1, -1]
	return {
		"bpm": 142.0,
		"lead": _cat([lead_a, lead_b, lead_a, lead_c]),
		"counter": _cat([arp_a, arp_b, arp_a, arp_b]),
		"bass": _cat([bass_a, bass_a, bass_b, bass_b]),
		"kick": _cat([_four_on_floor(), _four_on_floor(), _four_on_floor(), _four_on_floor()]),
		"snare": _cat([_backbeat(), _backbeat(), _backbeat(), _backbeat()]),
		"hat": _repeat_hits(64, 1)
	}

func _song_boss_one() -> Dictionary:
	var lead_a: Array = [84, -1, 83, -1, 81, 79, 81, -1, 84, -1, 88, -1, 86, -1, 84, -1]
	var lead_b: Array = [84, -1, 83, -1, 81, 79, 78, -1, 79, -1, 81, -1, 83, 84, 86, -1]
	var arp_a: Array = [69, 76, 81, 76, 68, 75, 80, 75, 66, 73, 78, 73, 68, 75, 80, 75]
	var arp_b: Array = [69, 76, 81, 76, 71, 78, 83, 78, 73, 80, 85, 80, 71, 78, 83, 78]
	var bass_a: Array = [45, -1, 45, -1, 44, -1, 44, -1, 42, -1, 42, -1, 44, -1, 44, -1]
	var bass_b: Array = [45, -1, 45, -1, 47, -1, 47, -1, 49, -1, 49, -1, 47, -1, 47, -1]
	return {
		"bpm": 154.0,
		"lead": _cat([lead_a, lead_b, lead_a, lead_b]),
		"counter": _cat([arp_a, arp_b, arp_a, arp_b]),
		"bass": _cat([bass_a, bass_a, bass_b, bass_b]),
		"kick": _cat([_dense_kick(), _dense_kick(), _dense_kick(), _dense_kick()]),
		"snare": _cat([_backbeat(), _backbeat(), _backbeat(), _backbeat()]),
		"hat": _repeat_hits(64, 1)
	}

func _song_stage_two() -> Dictionary:
	var lead_a: Array = [81, -1, 84, -1, 88, -1, 89, -1, 88, -1, 84, -1, 81, -1, 79, -1]
	var lead_b: Array = [81, 84, 86, -1, 88, -1, 91, -1, 89, -1, 88, -1, 86, -1, 84, -1]
	var lead_c: Array = [93, -1, 91, -1, 89, -1, 88, -1, 86, -1, 84, -1, 83, -1, 81, -1]
	var arp_a: Array = [69, 76, 81, 88, 71, 78, 83, 90, 72, 79, 84, 91, 74, 81, 86, 93]
	var arp_b: Array = [71, 78, 83, 90, 72, 79, 84, 91, 74, 81, 86, 93, 76, 83, 88, 95]
	var bass_a: Array = [45, -1, -1, -1, 45, -1, -1, -1, 47, -1, -1, -1, 47, -1, -1, -1]
	var bass_b: Array = [50, -1, -1, -1, 50, -1, -1, -1, 52, -1, -1, -1, 52, -1, -1, -1]
	return {
		"bpm": 150.0,
		"lead": _cat([lead_a, lead_b, lead_a, lead_c]),
		"counter": _cat([arp_a, arp_b, arp_a, arp_b]),
		"bass": _cat([bass_a, bass_a, bass_b, bass_b]),
		"kick": _cat([_dense_kick(), _dense_kick(), _dense_kick(), _dense_kick()]),
		"snare": _cat([_backbeat(), _backbeat(), _backbeat(), _backbeat()]),
		"hat": _repeat_hits(64, 1)
	}

func _song_boss_two() -> Dictionary:
	var lead_a: Array = [88, -1, 86, -1, 84, -1, 83, -1, 84, -1, 86, -1, 88, 91, 93, -1]
	var lead_b: Array = [95, -1, 93, -1, 91, -1, 89, -1, 88, -1, 86, -1, 84, 86, 88, -1]
	var arp_a: Array = [72, 79, 84, 91, 74, 81, 86, 93, 71, 78, 83, 90, 69, 76, 81, 88]
	var arp_b: Array = [74, 81, 86, 93, 76, 83, 88, 95, 72, 79, 84, 91, 71, 78, 83, 90]
	var bass_a: Array = [48, -1, 48, -1, 47, -1, 47, -1, 45, -1, 45, -1, 43, -1, 43, -1]
	var bass_b: Array = [50, -1, 50, -1, 52, -1, 52, -1, 53, -1, 53, -1, 52, -1, 52, -1]
	return {
		"bpm": 162.0,
		"lead": _cat([lead_a, lead_b, lead_a, lead_b]),
		"counter": _cat([arp_a, arp_b, arp_a, arp_b]),
		"bass": _cat([bass_a, bass_a, bass_b, bass_b]),
		"kick": _cat([_dense_kick(), _dense_kick(), _dense_kick(), _dense_kick()]),
		"snare": _cat([_dense_snare(), _dense_snare(), _dense_snare(), _dense_snare()]),
		"hat": _repeat_hits(64, 1)
	}

func _song_endless_stage() -> Dictionary:
	var lead_a: Array = [84, -1, 88, -1, 91, -1, 93, -1, 91, -1, 88, -1, 84, -1, 81, -1]
	var lead_b: Array = [86, -1, 89, -1, 93, -1, 96, -1, 93, -1, 89, -1, 86, -1, 84, -1]
	var arp_a: Array = [72, 79, 84, 88, 74, 81, 86, 89, 76, 83, 88, 91, 77, 84, 89, 93]
	var arp_b: Array = [74, 81, 86, 89, 76, 83, 88, 91, 77, 84, 89, 93, 79, 86, 91, 96]
	var bass_a: Array = [45, -1, -1, -1, 45, -1, -1, -1, 48, -1, -1, -1, 48, -1, -1, -1]
	var bass_b: Array = [50, -1, -1, -1, 50, -1, -1, -1, 53, -1, -1, -1, 53, -1, -1, -1]
	return {
		"bpm": 156.0,
		"lead": _cat([lead_a, lead_b, lead_a, lead_b]),
		"counter": _cat([arp_a, arp_b, arp_a, arp_b]),
		"bass": _cat([bass_a, bass_a, bass_b, bass_b]),
		"kick": _cat([_dense_kick(), _dense_kick(), _dense_kick(), _dense_kick()]),
		"snare": _cat([_backbeat(), _backbeat(), _backbeat(), _backbeat()]),
		"hat": _repeat_hits(64, 1)
	}

func _song_endless_boss() -> Dictionary:
	var lead_a: Array = [95, -1, 93, -1, 91, -1, 89, -1, 88, -1, 86, -1, 84, -1, 83, -1]
	var lead_b: Array = [96, -1, 95, -1, 93, -1, 91, -1, 89, -1, 88, -1, 86, -1, 84, -1]
	var arp_a: Array = [79, 86, 91, 95, 77, 84, 89, 93, 76, 83, 88, 91, 74, 81, 86, 89]
	var arp_b: Array = [81, 88, 93, 96, 79, 86, 91, 95, 77, 84, 89, 93, 76, 83, 88, 91]
	var bass_a: Array = [43, -1, 43, -1, 45, -1, 45, -1, 48, -1, 48, -1, 50, -1, 50, -1]
	var bass_b: Array = [41, -1, 41, -1, 43, -1, 43, -1, 46, -1, 46, -1, 48, -1, 48, -1]
	return {
		"bpm": 170.0,
		"lead": _cat([lead_a, lead_b, lead_a, lead_b]),
		"counter": _cat([arp_a, arp_b, arp_a, arp_b]),
		"bass": _cat([bass_a, bass_a, bass_b, bass_b]),
		"kick": _cat([_dense_kick(), _dense_kick(), _dense_kick(), _dense_kick()]),
		"snare": _cat([_dense_snare(), _dense_snare(), _dense_snare(), _dense_snare()]),
		"hat": _repeat_hits(64, 1)
	}

func _build_song_stream(song: Dictionary) -> AudioStreamWAV:
	var bpm: float = float(song.get("bpm", 140.0))
	var step_duration: float = 60.0 / bpm / 4.0
	var lead: Array = song.get("lead", [])
	var total_steps: int = lead.size()
	var total_samples: int = int(float(total_steps) * step_duration * float(SAMPLE_RATE))
	var samples := PackedFloat32Array()
	samples.resize(total_samples)
	_add_note_track(samples, lead, step_duration, &"pulse", 0.26, 0.84, 0.44, 0.006)
	_add_note_track(samples, song.get("counter", []), step_duration, &"triangle", 0.16, 0.92, 0.50, 0.0)
	_add_note_track(samples, song.get("bass", []), step_duration, &"saw", 0.20, 0.98, 0.50, 0.0)
	_add_drum_track(samples, song.get("kick", []), step_duration, &"kick", 0.42)
	_add_drum_track(samples, song.get("snare", []), step_duration, &"snare", 0.32)
	_add_drum_track(samples, song.get("hat", []), step_duration, &"hat", 0.16)
	_normalize(samples, 0.82)
	return _samples_to_stream(samples, true)

func _add_note_track(samples: PackedFloat32Array, pattern: Array, step_duration: float, waveform: StringName, volume: float, gate: float, duty: float, vibrato: float) -> void:
	for step_index in range(pattern.size()):
		var note_value: int = int(pattern[step_index])
		if note_value < 0:
			continue
		var start_sample: int = int(float(step_index) * step_duration * float(SAMPLE_RATE))
		var end_sample: int = int((float(step_index) + gate) * step_duration * float(SAMPLE_RATE))
		var capped_end: int = min(end_sample, samples.size())
		var segment_length: float = max(0.001, float(capped_end - start_sample) / float(SAMPLE_RATE))
		var frequency: float = _midi_to_hz(note_value)
		for sample_index in range(start_sample, capped_end):
			var local_t: float = float(sample_index - start_sample) / float(SAMPLE_RATE)
			var env: float = _envelope(local_t, segment_length, 0.008, 0.05, 0.74, 0.08)
			var pitch: float = frequency * (1.0 + sin(local_t * TAU * 5.0) * vibrato)
			samples[sample_index] += _osc(waveform, pitch, local_t, duty) * env * volume

func _add_drum_track(samples: PackedFloat32Array, pattern: Array, step_duration: float, drum: StringName, volume: float) -> void:
	for step_index in range(pattern.size()):
		if int(pattern[step_index]) == 0:
			continue
		var start_sample: int = int(float(step_index) * step_duration * float(SAMPLE_RATE))
		var duration: float = 0.22
		if drum == &"snare":
			duration = 0.16
		elif drum == &"hat":
			duration = 0.07
		var capped_end: int = min(samples.size(), start_sample + int(duration * float(SAMPLE_RATE)))
		for sample_index in range(start_sample, capped_end):
			var local_t: float = float(sample_index - start_sample) / float(SAMPLE_RATE)
			var t_ratio: float = clamp(local_t / duration, 0.0, 1.0)
			var env: float = pow(1.0 - t_ratio, 2.2)
			var value := 0.0
			match drum:
				&"kick":
					var freq: float = 120.0 - 70.0 * t_ratio
					value = sin(TAU * freq * local_t) * env + sin(TAU * (freq * 0.5) * local_t) * env * 0.35
				&"snare":
					value = (_osc(&"noise", 0.0, local_t, 0.5) * 0.78 + _osc(&"triangle", 240.0, local_t, 0.5) * 0.22) * env
				&"hat":
					value = _osc(&"noise", 0.0, local_t * 4.0, 0.5) * env
			samples[sample_index] += value * volume

func _osc(waveform: StringName, frequency: float, time: float, duty: float) -> float:
	var phase: float = fposmod(time * frequency, 1.0)
	match waveform:
		&"sine":
			return sin(TAU * phase)
		&"triangle":
			return 1.0 - 4.0 * abs(phase - 0.5)
		&"saw":
			return phase * 2.0 - 1.0
		&"noise":
			return sin((time + 0.17) * 983.0) * 0.65 + sin((time + 1.37) * 1703.0) * 0.35
		_:
			return 1.0 if phase < duty else -1.0

func _envelope(time: float, duration: float, attack: float, decay: float, sustain: float, release: float) -> float:
	if time < attack:
		return time / max(attack, 0.0001)
	if time < attack + decay:
		var decay_ratio: float = (time - attack) / max(decay, 0.0001)
		return lerpf(1.0, sustain, decay_ratio)
	if time < max(duration - release, attack + decay):
		return sustain
	var release_ratio: float = (time - max(duration - release, 0.0)) / max(release, 0.0001)
	return sustain * (1.0 - clamp(release_ratio, 0.0, 1.0))

func _normalize(samples: PackedFloat32Array, target_peak: float) -> void:
	var peak := 0.001
	for sample in samples:
		peak = max(peak, abs(float(sample)))
	var scale: float = target_peak / peak
	for sample_index in range(samples.size()):
		samples[sample_index] *= scale

func _samples_to_stream(samples: PackedFloat32Array, looping: bool) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for sample_index in range(samples.size()):
		var sample_value: float = clamp(float(samples[sample_index]), -1.0, 1.0)
		var encoded: int = int(round(sample_value * 32767.0))
		if encoded < 0:
			encoded += 65536
		bytes[sample_index * 2] = encoded & 255
		bytes[sample_index * 2 + 1] = (encoded >> 8) & 255
	var stream := AudioStreamWAV.new()
	stream.mix_rate = SAMPLE_RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.stereo = false
	stream.data = bytes
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = samples.size()
	return stream

func _build_confirm_stream() -> AudioStreamWAV:
	return _build_sweep_sfx(0.08, 880.0, 1260.0, &"pulse", 0.35)

func _build_pause_stream() -> AudioStreamWAV:
	return _build_sweep_sfx(0.1, 980.0, 520.0, &"triangle", 0.32)

func _build_shot_stream(focused: bool) -> AudioStreamWAV:
	var duration: float = 0.08 if focused else 0.06
	var start_pitch: float = 1450.0 if focused else 1200.0
	var end_pitch: float = 520.0 if focused else 640.0
	return _build_sweep_sfx(duration, start_pitch, end_pitch, &"pulse", 0.28)

func _build_enemy_fire_stream(ring_type: bool) -> AudioStreamWAV:
	var duration: float = 0.14 if ring_type else 0.1
	var start_pitch: float = 620.0 if ring_type else 760.0
	var end_pitch: float = 340.0 if ring_type else 430.0
	return _build_sweep_sfx(duration, start_pitch, end_pitch, &"triangle", 0.32)

func _build_enemy_spiral_stream() -> AudioStreamWAV:
	return _build_sweep_sfx(0.16, 720.0, 240.0, &"saw", 0.3)

func _build_graze_stream() -> AudioStreamWAV:
	return _build_sweep_sfx(0.08, 1100.0, 1600.0, &"sine", 0.24)

func _build_pickup_stream(power_item: bool) -> AudioStreamWAV:
	var duration := 0.16
	var samples := PackedFloat32Array()
	samples.resize(int(duration * float(SAMPLE_RATE)))
	for sample_index in range(samples.size()):
		var local_t: float = float(sample_index) / float(SAMPLE_RATE)
		var env: float = pow(1.0 - clamp(local_t / duration, 0.0, 1.0), 1.7)
		var first_pitch: float = 920.0 if power_item else 760.0
		var second_pitch: float = 1380.0 if power_item else 1120.0
		var sample_value: float = 0.0
		sample_value += _osc(&"sine", first_pitch, local_t, 0.5) * env * 0.55
		sample_value += _osc(&"triangle", second_pitch, max(local_t - 0.04, 0.0), 0.5) * env * 0.32
		samples[sample_index] = sample_value
	_normalize(samples, 0.72)
	return _samples_to_stream(samples, false)

func _build_enemy_down_stream() -> AudioStreamWAV:
	var duration := 0.22
	var samples := PackedFloat32Array()
	samples.resize(int(duration * float(SAMPLE_RATE)))
	for sample_index in range(samples.size()):
		var local_t: float = float(sample_index) / float(SAMPLE_RATE)
		var ratio: float = clamp(local_t / duration, 0.0, 1.0)
		var env: float = pow(1.0 - ratio, 2.0)
		var sample_value: float = _osc(&"noise", 0.0, local_t * 3.0, 0.5) * env * 0.62
		sample_value += _osc(&"triangle", 200.0 - 80.0 * ratio, local_t, 0.5) * env * 0.28
		samples[sample_index] = sample_value
	_normalize(samples, 0.78)
	return _samples_to_stream(samples, false)

func _build_player_hit_stream() -> AudioStreamWAV:
	var duration := 0.28
	var samples := PackedFloat32Array()
	samples.resize(int(duration * float(SAMPLE_RATE)))
	for sample_index in range(samples.size()):
		var local_t: float = float(sample_index) / float(SAMPLE_RATE)
		var ratio: float = clamp(local_t / duration, 0.0, 1.0)
		var env: float = pow(1.0 - ratio, 1.8)
		var sample_value: float = _osc(&"saw", 280.0 - 120.0 * ratio, local_t, 0.5) * env * 0.45
		sample_value += _osc(&"noise", 0.0, local_t * 2.0, 0.5) * env * 0.42
		samples[sample_index] = sample_value
	_normalize(samples, 0.84)
	return _samples_to_stream(samples, false)

func _build_bomb_stream() -> AudioStreamWAV:
	var duration := 0.72
	var samples := PackedFloat32Array()
	samples.resize(int(duration * float(SAMPLE_RATE)))
	for sample_index in range(samples.size()):
		var local_t: float = float(sample_index) / float(SAMPLE_RATE)
		var ratio: float = clamp(local_t / duration, 0.0, 1.0)
		var env: float = pow(1.0 - ratio, 1.5)
		var low_pitch: float = 140.0 - 90.0 * ratio
		var sample_value: float = sin(TAU * low_pitch * local_t) * env * 0.44
		sample_value += sin(TAU * low_pitch * 0.5 * local_t) * env * 0.22
		sample_value += _osc(&"noise", 0.0, local_t * 1.6, 0.5) * env * 0.38
		samples[sample_index] = sample_value
	_normalize(samples, 0.86)
	return _samples_to_stream(samples, false)

func _build_phase_break_stream() -> AudioStreamWAV:
	return _build_chord_stab([72, 76, 79, 84], 0.34, 0.52)

func _build_transition_stream() -> AudioStreamWAV:
	return _build_chord_stab([76, 81, 84, 88], 0.42, 0.58)

func _build_stage_clear_stream() -> AudioStreamWAV:
	var duration := 0.64
	var notes: Array = [72, 76, 79, 84, 88, 91]
	return _build_arpeggio_chime(notes, duration, 0.6)

func _build_game_clear_stream() -> AudioStreamWAV:
	var duration := 0.88
	var notes: Array = [72, 76, 79, 84, 88, 91, 95, 100]
	return _build_arpeggio_chime(notes, duration, 0.72)

func _build_sweep_sfx(duration: float, start_pitch: float, end_pitch: float, waveform: StringName, volume: float) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	samples.resize(int(duration * float(SAMPLE_RATE)))
	for sample_index in range(samples.size()):
		var local_t: float = float(sample_index) / float(SAMPLE_RATE)
		var ratio: float = clamp(local_t / duration, 0.0, 1.0)
		var pitch: float = lerpf(start_pitch, end_pitch, ratio)
		var env: float = pow(1.0 - ratio, 2.1)
		samples[sample_index] = _osc(waveform, pitch, local_t, 0.42) * env * volume
	_normalize(samples, 0.8)
	return _samples_to_stream(samples, false)

func _build_chord_stab(notes: Array, duration: float, volume: float) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	samples.resize(int(duration * float(SAMPLE_RATE)))
	for note_value in notes:
		var frequency: float = _midi_to_hz(int(note_value))
		for sample_index in range(samples.size()):
			var local_t: float = float(sample_index) / float(SAMPLE_RATE)
			var env: float = _envelope(local_t, duration, 0.004, 0.06, 0.52, 0.16)
			samples[sample_index] += _osc(&"pulse", frequency, local_t, 0.4) * env * volume / float(max(1, notes.size()))
	_normalize(samples, 0.82)
	return _samples_to_stream(samples, false)

func _build_arpeggio_chime(notes: Array, duration: float, volume: float) -> AudioStreamWAV:
	var samples := PackedFloat32Array()
	samples.resize(int(duration * float(SAMPLE_RATE)))
	var note_span: float = duration / float(max(1, notes.size()))
	for note_index in range(notes.size()):
		var note_value: int = int(notes[note_index])
		var frequency: float = _midi_to_hz(note_value)
		var start_sample: int = int(float(note_index) * note_span * float(SAMPLE_RATE))
		var end_sample: int = min(samples.size(), start_sample + int(note_span * 1.6 * float(SAMPLE_RATE)))
		for sample_index in range(start_sample, end_sample):
			var local_t: float = float(sample_index - start_sample) / float(SAMPLE_RATE)
			var env: float = _envelope(local_t, note_span * 1.35, 0.004, 0.04, 0.62, 0.12)
			samples[sample_index] += _osc(&"sine", frequency, local_t, 0.5) * env * volume * 0.58
			samples[sample_index] += _osc(&"triangle", frequency * 2.0, local_t, 0.5) * env * volume * 0.22
	_normalize(samples, 0.85)
	return _samples_to_stream(samples, false)

func _midi_to_hz(note_value: int) -> float:
	return 440.0 * pow(2.0, (float(note_value) - 69.0) / 12.0)

func _cat(parts: Array) -> Array:
	var result: Array = []
	for part in parts:
		result.append_array(part)
	return result

func _four_on_floor() -> Array:
	return [1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0]

func _backbeat() -> Array:
	return [0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0]

func _dense_kick() -> Array:
	return [1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 1, 0]

func _dense_snare() -> Array:
	return [0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0]

func _repeat_hits(count: int, stride: int) -> Array:
	var result: Array = []
	for index in range(count):
		result.append(1 if index % stride == 0 else 0)
	return result
