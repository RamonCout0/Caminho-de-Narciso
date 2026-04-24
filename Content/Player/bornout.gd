extends ColorRect

@onready var sprite = $"../AnimatedSprite2D" # Caminho baseado na sua imagem 42f902
@onready var batimento = $"../SomBatimento"

func _ready():
	GameManager.sanity_changed.connect(_on_sanity_updated)
	call_deferred("_on_sanity_updated", GameManager.current_sanity)

func _on_sanity_updated(valor: float):
	# Garante que o nó está na árvore antes de tentar reproduzir áudio
	if not is_inside_tree():
		return
	# 1. ATUALIZA O SHADER
	var intensity_val: float = 0.0
	if valor <= 80.0:
		intensity_val = (80.0 - valor) / 80.0
	
	material.set_shader_parameter("intensity", intensity_val)

	# 2. TROCA OS ESTÁGIOS E CONTROLA O SOM
	if valor > 80.0:
		sprite.play("estagio0")
		self.visible = false
		
		# --- CORREÇÃO AQUI ---
		if batimento.playing:
			batimento.stop() # Para o som quando a sanidade está alta
		# ---------------------

	elif valor > 55.0:
		sprite.play("estagio1")
		self.visible = true
		batimento.pitch_scale = 1.0 # Reseta o pitch para o normal
		if !batimento.playing:
			batimento.play()

	elif valor > 25.0:
		sprite.play("estagio2")
		self.visible = true
		batimento.pitch_scale = 1.2 # Acelera um pouco
		if !batimento.playing: # Garante que está tocando caso ele cure de 0 a 30 direto
			batimento.play()

	else:
		sprite.play("estagio3")
		self.visible = true
		batimento.pitch_scale = 1.6 # Batimento cardíaco desesperado
		if !batimento.playing:
			batimento.play()
