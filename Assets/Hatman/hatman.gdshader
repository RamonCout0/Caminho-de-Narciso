shader_type canvas_item;

uniform sampler2D noise_tex;
uniform float progress : hint_range(0.0, 1.1) = 0.0;
uniform vec4 cor_base_trevas : source_color = vec4(0.05, 0.0, 0.1, 1.0); // Roxo escuro/profundo
uniform vec4 cor_chama_negra : source_color = vec4(0.0, 0.0, 0.0, 1.0);  // Preto absoluto

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    
    // Ruído base estático para manter a estrutura do surgimento
    float base_noise = texture(noise_tex, UV).r;
    
    // Ruído rolando para cima com o tempo para simular o fogo subindo
    vec2 scrolled_uv = UV + vec2(0.0, TIME * 0.8);
    float fire_noise = texture(noise_tex, scrolled_uv).r;
    
    // Limite da transição (de baixo para cima)
    float threshold = (1.0 - UV.y) + (base_noise * 0.3);
    
    if (threshold > progress * 1.3) {
        // Ainda não surgiu
        COLOR.a = 0.0;
    } else {
        // A espessura da área de "fogo" varia com o ruído em movimento
        float edge_width = 0.1 + (fire_noise * 0.2); 
        float edge = smoothstep(progress * 1.3 - edge_width, progress * 1.3, threshold);
        
        // Mistura as duas cores para criar a textura da chama
        vec4 textura_chama = mix(cor_base_trevas, cor_chama_negra, fire_noise);
        
        // Aplica a chama apenas na borda da transição
        COLOR = mix(tex, textura_chama, edge);
        COLOR.a *= tex.a;
        
        // Desgasta e esfumaça as pontas das chamas para não ficar um corte seco
        if (edge > 0.01 && fire_noise > 0.6 && threshold > progress * 1.3 - (edge_width * 0.5)) {
            COLOR.a *= (1.0 - fire_noise); 
        }
    }
}