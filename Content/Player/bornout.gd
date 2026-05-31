extends ColorRect

@onready var sprite = $"../AnimatedSprite2D"
@onready var batimento: AudioStreamPlayer2D = $"../SomBatimento" if has_node("../SomBatimento") else null

func _ready():
	GameManager.sanity_changed.connect(_on_sanity_updated)
	call_deferred("_on_sanity_updated", GameManager.current_sanity)

func _on_sanity_updated(valor: float):
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
		if batimento and batimento.playing:
			batimento.stop()

	elif valor > 55.0:
		sprite.play("estagio1")
		self.visible = true
		if batimento:
			batimento.pitch_scale = 1.0
			if not batimento.playing:
				batimento.play()

	elif valor > 25.0:
		sprite.play("estagio2")
		self.visible = true
		if batimento:
			batimento.pitch_scale = 1.2
			if not batimento.playing:
				batimento.play()

	else:
		sprite.play("estagio3")
		self.visible = true
		if batimento:
			batimento.pitch_scale = 1.6
			if not batimento.playing:
				batimento.play()
