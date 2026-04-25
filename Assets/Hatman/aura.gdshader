shader_type canvas_item;

uniform vec4 cor_perigo : source_color = vec4(0.1, 0.0, 0.2, 0.4); // Roxo escuro translúcido
uniform float pulso_velocidade = 1.5;
uniform float raio_borda_suave = 0.45; // Quão esfumaçada é a borda

void fragment() {
    // Calcula a distância do centro (UV 0.5, 0.5)
    vec2 centro = vec2(0.5, 0.5);
    float distancia = distance(UV, centro);
    
    // Cria pulsação de Alpha (transparência)
    float pulso = (sin(TIME * pulso_velocidade) + 1.0) * 0.5; // Varia entre 0 e 1
    float final_alpha = cor_perigo.a + (pulso * 0.2); // Pulsa um pouco acima da cor base
    
    // Cria o formato circular com borda esfumaçada (softmask)
    // Se a distância for maior que 0.5 (borda do quadrado), alpha fica 0
    float mascara_circular = smoothstep(0.5, raio_borda_suave, distancia);
    
    COLOR = cor_perigo;
	// Aplica a pulsação e a máscara circular
    COLOR.a = mascara_circular * final_alpha;
}