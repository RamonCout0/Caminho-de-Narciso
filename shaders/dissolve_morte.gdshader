shader_type canvas_item;

uniform float dissolve_progress : hint_range(0.0, 1.0) = 0.0;
uniform float noise_scale : hint_range(1.0, 20.0) = 6.0;
uniform vec4 edge_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float edge_width : hint_range(0.0, 0.3) = 0.08;

float hash(vec2 p) {
	p = fract(p * vec2(443.897, 441.423));
	p += dot(p, p + 19.19);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(
		mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x),
		f.y
	);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float n = noise(UV * noise_scale);

	float alpha_original = tex.a;
	vec4 cor_final;

	if (n < dissolve_progress - edge_width) {
		cor_final = vec4(0.0);
	} else if (n < dissolve_progress) {
		float t = 1.0 - (dissolve_progress - n) / edge_width;
		cor_final = vec4(mix(edge_color.rgb, tex.rgb, t), alpha_original * t);
	} else {
		cor_final = tex;
	}

	// Preserva pixels transparentes do sprite original
	COLOR = vec4(cor_final.rgb, cor_final.a * step(0.01, alpha_original));
}
