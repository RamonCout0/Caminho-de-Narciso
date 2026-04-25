shader_type canvas_item;
uniform float wave_speed = 3.0;
uniform float distortion_amp = 2.0;
uniform vec4 dark_aura : source_color = vec4(0.05, 0.02, 0.1, 1.0);

void vertex() {
    VERTEX.x += sin(TIME * wave_speed + VERTEX.y) * distortion_amp;
    VERTEX.y += cos(TIME * wave_speed + VERTEX.x) * distortion_amp;
}

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float pulse = (sin(TIME * 4.0) + 1.0) * 0.5;
    COLOR = mix(tex, dark_aura, 0.7 + (pulse * 0.2));
    COLOR.a *= tex.a;
}