shader_type canvas_item;
// Вода без повторяющегося узора: плавный шум в мировых координатах, квантованный в 5 тонов палитры.
uniform vec4 c_deep : source_color = vec4(0.141, 0.314, 0.549, 1.0);
uniform vec4 c_mid : source_color = vec4(0.18, 0.416, 0.659, 1.0);
uniform vec4 c_light : source_color = vec4(0.29, 0.549, 0.769, 1.0);
uniform vec4 c_foam : source_color = vec4(0.549, 0.769, 0.91, 1.0);
varying vec2 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void fragment() {
	vec2 p = floor(wpos);
	float t = TIME * 0.5;
	float n = noise(p * vec2(0.06, 0.12) + vec2(t * 0.5, t * 0.2)) * 0.6 + noise(p * vec2(0.13, 0.22) - vec2(t * 0.35, -t * 0.25)) * 0.4;
	float s = noise(p * vec2(0.35, 0.7) + vec2(t * 1.6, t * 0.3));
	vec4 col = c_mid;
	if (n < 0.33) col = c_deep;
	if (n > 0.64) col = c_light;
	if (n > 0.6 && s > 0.86) col = c_foam;
	COLOR = col;
}
