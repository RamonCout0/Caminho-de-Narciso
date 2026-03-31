shader_type canvas_item;

// Variáveis uniformes que você pode ajustar no Inspetor
uniform float raio : hint_range(0.0, 1.0) = 0.5;      // Tamanho do círculo (0.5 é o máximo no quadrado)
uniform float suavidade : hint_range(0.0, 1.0) = 0.1; // O quão "esfumaçada" é a borda
uniform float opacidade_maxima : hint_range(0.0, 1.0) = 0.5; // Transparência da sombra

void fragment() {
    // 1. Pegar as coordenadas UV (vão de 0.0 a 1.0 no ColorRect)
    // E centralizá-las para que o meio do ColorRect seja (0.0, 0.0)
    vec2 uv_centralizada = UV - vec2(0.5, 0.5);

    // 2. Calcular a distância do pixel atual até o centro
    float distancia_ao_centro = length(uv_centralizada);

    // 3. Criar o círculo usando smoothstep para suavizar a borda
    // smoothstep(valor_min, valor_max, valor_atual)
    // Retorna 0.0 se for menor que min, 1.0 se for maior que max, e interpola no meio.
    // Invertemos o resultado (1.0 - ...) para que o centro seja 1 (opaco) e a borda 0 (transparente).
    float mascara_circulo = 1.0 - smoothstep(raio - suavidade, raio, distancia_ao_centro);

    // 4. Aplicar a opacidade máxima definida
    float alfa_final = mascara_circulo * opacidade_maxima;

    // 5. Definir a cor final do pixel. Mantemos a cor original do ColorRect (preto)
    // e apenas alteramos o canal Alfa (transparência).
    COLOR = vec4(COLOR.rgb, alfa_final);
}