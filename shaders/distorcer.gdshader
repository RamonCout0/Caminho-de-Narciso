shader_type canvas_item;
render_mode unshaded; 

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

// Controles do Croma e Distorção
uniform float distortion_strength : hint_range(0.0, 0.1) = 0.015;
uniform float chroma_offset : hint_range(0.0, 0.05) = 0.005;
uniform float speed : hint_range(0.0, 10.0) = 3.0;

// ⭐ NOVO: Controle do Granulado (Estática)
uniform float grain_amount : hint_range(0.0, 1.0) = 0.08;

void fragment() {
    // 1. Máscara (Formato da luz)
    float mask = texture(TEXTURE, UV).a;

    // 2. Distorção
    vec2 distortion = vec2(
        sin(UV.y * 20.0 + TIME * speed), 
        cos(UV.x * 20.0 + TIME * speed)
    ) * distortion_strength * mask;

    vec2 distorted_screen_uv = SCREEN_UV + distortion;

    // 3. Aberração Cromática
    float r = texture(screen_texture, distorted_screen_uv + vec2(chroma_offset * mask, 0.0)).r;
    float g = texture(screen_texture, distorted_screen_uv).g;
    float b = texture(screen_texture, distorted_screen_uv - vec2(chroma_offset * mask, 0.0)).b;

    // ⭐ 4. O GRANULADO (Film Grain)
    // Uma função matemática clássica que gera números "aleatórios" para criar ruído
    float noise = fract(sin(dot(SCREEN_UV + (TIME * speed), vec2(12.9898, 78.233))) * 43758.5453);
    
    // Subtraímos um pouco de luz baseado no ruído e na força que você escolheu no Inspector
    vec3 cor_final = vec3(r, g, b) - (noise * grain_amount);

    // 5. Resultado Final
    COLOR = vec4(cor_final, mask);
}