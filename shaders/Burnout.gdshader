shader_type canvas_item;

// Acesso obrigatório à tela no Godot 4
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// --- CONTROLES UNIFORMES GERAIS (Use no GDScript de 0.0 a 1.0) ---
// Agora 'intensity' controla TODOS os novos efeitos de loucura.
uniform float intensity : hint_range(0.0, 1.0) = 0.0; 
uniform float pulse_speed : hint_range(0.0, 10.0) = 4.0; 

// --- CONTROLES VISUAIS GERAIS ---
// Cores: Uma para o borrão geral (Aura), outra para as veias (escura)
uniform vec4 pain_color : source_color = vec4(0.4, 0.0, 0.0, 1.0); // Vermelho base
uniform vec4 vein_color : source_color = vec4(0.1, 0.0, 0.0, 1.0); // Veias escuras
uniform float vein_thickness : hint_range(0.0, 1.0) = 0.5;

// --- CONTROLES MATEMÁTICOS DE DISTORÇÃO (Loucura) ---
// Quão forte as cores se separam (Aberração Cromática)
uniform float chromatic_split : hint_range(0.0, 0.1) = 0.03; 
// Quão forte as bordas se curvam (Distorção Geométrica)
uniform float geometry_warp : hint_range(0.0, 0.2) = 0.06; 
// Quão rápido a distorção se move
uniform float warp_speed : hint_range(0.0, 5.0) = 1.0;

// --- FUNÇÕES AUXILIARES ---
// Função de ruído (Corrigida: fract)
vec2 hash(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3)));
    return fract(sin(p) * 43758.5453);
}

// Voronoi (Gera as veias instáveis)
float get_psychosis_veins(vec2 uv, float pulse) {
    // Usamos pulse para fazer o ruído cintilar
    vec2 p = uv * (7.0 + pulse * 2.0); 
    vec2 n = floor(p);
    vec2 f = fract(p);
    float m_dist = 1.0;

    for (int j = -1; j <= 1; j++) {
        for (int i = -1; i <= 1; i++) {
            vec2 g = vec2(float(i), float(j));
            vec2 o = hash(n + g);
            // Pontos tremerem mais rápido com a pulsação
            o = 0.5 + 0.5 * sin(TIME * (0.5 + pulse * 2.0) + 6.2831 * o);
            vec2 r = g + o - f;
            float d = dot(r, r);
            if (d < m_dist) m_dist = d;
        }
    }
    return 1.0 - smoothstep(0.0, vein_thickness * 0.25, sqrt(m_dist));
}

void fragment() {
    // 1. Calcula a Pulsação da Loucura
    // sin() cria onda, exp() torna aguda (batimento cardíaco)
    float pulse = exp(sin(TIME * pulse_speed) * 0.4) * 0.5;
    
    // === NOVOS EFEITOS DE LOUCURA (Distorção Geometrica) ===
    
    // A. DISTORÇÃO GEOMÉTRICA (Warping)
    // Usamos sin() baseada na posição UV e no TIME para criar uma lente instável
    vec2 uv_offset = vec2(
        sin(SCREEN_UV.y * 30.0 + TIME * warp_speed * 2.0),
        cos(SCREEN_UV.x * 20.0 + TIME * warp_speed * 3.0)
    );
    
    // Distorção aumenta agressivamente com a intensidade e a pulsação
    float current_warp = geometry_warp * intensity * (1.0 + pulse * 0.5);
    vec2 warped_screen_uv = SCREEN_UV + uv_offset * current_warp;
    
    // B. ABERRAÇÃO CROMÁTICA (Splitting)
    // Separamos os UVs dos canais Vermelho, Verde e Azul
    // A distorção é radial (do centro para as bordas)
    vec2 center_dist = SCREEN_UV - vec2(0.5);
    // Escala o split baseado na intensidade e na distância do centro
    float current_split = chromatic_split * intensity * length(center_dist);
    
    vec2 uv_r = warped_screen_uv + center_dist * current_split;
    vec2 uv_g = warped_screen_uv;
    vec2 uv_b = warped_screen_uv - center_dist * current_split;
    
    // Lê a tela 3 vezes para criar o split de cor
    vec3 screen_r = texture(screen_texture, uv_r).rgb;
    vec3 screen_g = texture(screen_texture, uv_g).rgb;
    vec3 screen_b = texture(screen_texture, uv_b).rgb;
    
    vec3 final_screen_color = vec3(screen_r.r, screen_g.g, screen_b.b);
    
    // C. DESATURAÇÃO VARIÁVEL (Realidade fria)
    // Calcula a versão em tons de cinza da tela
    float gray = dot(final_screen_color, vec3(0.299, 0.587, 0.114));
    vec3 grayscale_screen = vec3(gray);
    // Mistura o cinza baseado na intensidade (máximo 70% desaturado)
    final_screen_color = mix(final_screen_color, grayscale_screen, intensity * 0.7);
    
    
    // === EFEITOS DE DOR ANTERIORES (Vinheta + Veias) ===
    
    // 2. Calcula a Vinheta (Eclipse)
    float dist = distance(UV, vec2(0.5));
    // Bordas vermelhas fortes com pulsação
    float vignette = smoothstep(0.1 + pulse * 0.1, 0.5 + pulse * 0.3, dist);
    
    // 3. Calcula as Veias Psicotrópicas (Agora instáveis e cintilantes)
    float veins = get_psychosis_veins(SCREEN_UV, pulse);
    
    // 4. MÁSCARA DAS VEIAS (Só aparecem nas bordas)
    float visible_veins = veins * vignette;
    
    // 5. MISTURA TUDO BASEADO NA INTENSIDADE GERAL
    
    // Fator total de visibilidade da dor nas bordas
    float pain_alpha = (vignette * (1.0 + pulse * 0.2) + visible_veins) * intensity;
    pain_alpha = clamp(pain_alpha, 0.0, 1.0);
    
    // Decide se o pixel de dor é a aura vermelha ou a veia escura
    vec3 pain_and_veins = mix(pain_color.rgb, vein_color.rgb, visible_veins);
    
    // === RESULTADO FINAL ===
    // Mistura a tela perturbada (Final Screen Color) com a dor nas bordas
    vec3 result_rgb = mix(final_screen_color, pain_and_veins, pain_alpha);
    
    // Drama extra: Escurece o fundo nas bordas e cantos
    result_rgb = mix(result_rgb, result_rgb * 0.25, visible_veins * intensity);
    result_rgb = mix(result_rgb, vec3(0.0), vignette * intensity * 0.35);
    
    COLOR = vec4(result_rgb, 1.0);
}