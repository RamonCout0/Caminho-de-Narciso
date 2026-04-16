extends ColorRect

@onready var sprite = $"../AnimatedSprite2D" # Caminho baseado na sua imagem 42f902
@onready var batimento = $"../SomBatimento"

func _ready():
	GameManager.sanity_changed.connect(_on_sanity_updated)
	_on_sanity_updated(GameManager.current_sanity)

func _on_sanity_updated(valor: float):
	# 1. ATUALIZA O SHADER (80 para baixo)
	var intensity_val: float = 0.0
	if valor <= 80.0:
		intensity_val = (80.0 - valor) / 80.0
	
	material.set_shader_parameter("intensity", intensity_val)

	# 2. TROCA OS 4 ESTÁGIOS (Baseado nas suas animações)
	if valor > 80.0:
		sprite.play("estagio0") # Inteiro
		self.visible = false
	elif valor > 55.0:
		sprite.play("estagio1") # Rachando
		self.visible = true
		if !batimento.playing:
			batimento.play()
	elif valor > 25.0:
		sprite.play("estagio2") # Quebrado
		self.visible = true
		batimento.pitch_scale = 1.2
	
		
		
	else:
		sprite.play("estagio3") # Vermelho/Crítico
		batimento.pitch_scale = 1.6
		self.visible = true
