shader_type canvas_item;
uniform float intensity : hint_range(0.0, 5.0) = 0.0; // 0 = desligado, >1 = brilha
uniform vec4 glow_color : source_color = vec4(1.0, 0.2, 0.0, 1.0);

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    vec4 glow = glow_color * intensity;
    COLOR = vec4(mix(tex.rgb, glow.rgb, 0.6), tex.a);
    COLOR.rgb *= max(1.0, intensity); // Adiciona o bloom
}