shader_type canvas_item;

uniform float blink_interval : hint_range(0.1, 30.0) = 4.0;   // pausa entre grupos
uniform float blink_count    : hint_range(1.0, 10.0) = 2.0;   // piscadas por grupo
uniform float blink_speed    : hint_range(0.05, 2.0)  = 0.18; // duração de 1 piscada
uniform float close_ratio    : hint_range(0.1, 0.9)   = 0.35; // % fechando vs abrindo
uniform float edge_softness  : hint_range(0.001, 0.1) = 0.04; // suavidade da borda
uniform vec4  blink_color    : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    float burst_duration = blink_count * blink_speed;
    float cycle = mod(TIME, burst_duration + blink_interval);

    float openness = 1.0;
    if (cycle < burst_duration) {
        float local = mod(cycle, blink_speed) / blink_speed;
        if (local < close_ratio) {
            openness = 1.0 - smoothstep(0.0, close_ratio, local);
        } else {
            openness = smoothstep(close_ratio, 1.0, local);
        }
    }

    // Elipse centrada no UV: raio X = 0.6 (passa da tela), raio Y = openness
    // Quando openness=1 → elipse enorme → tudo dentro → tudo transparente
    // Quando openness=0 → elipse vira linha → tudo fora → tudo preto
    vec2 c = UV - vec2(0.5);
    float a = 0.6;
    float b = max(openness, 0.001);

    float ellipse = (c.x / a) * (c.x / a) + (c.y / b) * (c.y / b);

    // Fora da elipse = preto, dentro = transparente
    float covered = smoothstep(1.0 - edge_softness, 1.0 + edge_softness, ellipse);

    COLOR = vec4(blink_color.rgb, covered * blink_color.a);
}