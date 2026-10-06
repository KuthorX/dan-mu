shader_type canvas_item;

// Dry-brush (飞白) for the title calligraphy: long thin streaks of bare paper
// run through the strokes, as when a half-dry brush skips across the sheet.

uniform float streak_scale = 0.09;
uniform float streak_length = 0.006;
uniform float coverage = 0.26;

varying vec2 local_pos;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	// streaks follow a slightly rising stroke direction
	vec2 p = vec2(local_pos.x + local_pos.y * 0.3, local_pos.y - local_pos.x * 0.12);
	float streaks = value_noise(vec2(p.x * streak_length, p.y * streak_scale * 4.0));
	streaks = streaks * 0.7 + value_noise(vec2(p.x * streak_length * 3.0, p.y * streak_scale * 9.0)) * 0.3;
	float keep = smoothstep(coverage - 0.08, coverage + 0.08, streaks);
	COLOR.a *= mix(0.3, 1.0, keep);
}
