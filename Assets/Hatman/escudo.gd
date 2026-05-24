extends Area2D

# ================================================================
# ESCUDO — Comportamento:
# 1. Surge na borda da câmera (posição definida pelo Hatman)
# 2. Fica 3s flutuando/rastreando o Y do player (TRACKING)
# 3. Carrega por 1s com glow (CHARGING)
# 4. Arranca horizontalmente em direção ao centro (DASHING)
# 5. Ao colidir com o outro escudo:
#    — Este (o que detectou primeiro) cai no chão como pickup
#    — O outro desaparece
# ================================================================

enum State { TRACKING, CHARGING, DASHING, DROPPED }
var state = State.TRACKING

var player  : Node2D
var hatman  : Node    = null  # Referência ao boss (para notificar ao cair)
var side    : int     = 1     # -1 = esquerda, 1 = direita
var tempo_flutuacao : float = randf() * 10.0
var _ja_caiu        : bool  = false   # Garante que só 1 dos 2 escudos cai
var _pos_inicial_x  : float = 0.0    # Para auto-destruição se sair muito da tela

@onready var sprite = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("shield")  # Necessário para o outro escudo detectar colisão
	area_entered.connect(_on_area_entered)
	sprite.play("default")
	sprite.material.set_shader_parameter("intensity", 0.0)
	_pos_inicial_x = global_position.x
	await get_tree().create_timer(3.0).timeout
	if not _ja_caiu and state == State.TRACKING:
		iniciar_carga()

func _physics_process(delta: float) -> void:
	tempo_flutuacao += delta
	var bobbing := sin(tempo_flutuacao * 3.0) * 5.0

	if state == State.TRACKING:
		if is_instance_valid(player):
			global_position.y = lerp(global_position.y, player.global_position.y, delta * 5.0)
		sprite.position.y = bobbing

	elif state == State.DASHING:
		global_position.x -= 600.0 * side * delta
		sprite.position.y = bobbing
		# Auto-destruói se percorreu mais de 900px sem colidir (evita ficar fora da tela)
		if abs(global_position.x - _pos_inicial_x) > 900.0:
			queue_free()

func iniciar_carga() -> void:
	state = State.CHARGING
	var tween = create_tween()
	tween.tween_method(set_shader_glow, 0.0, 3.0, 1.0)
	await tween.finished
	if not _ja_caiu:
		state = State.DASHING

func set_shader_glow(val: float) -> void:
	sprite.material.set_shader_parameter("intensity", val)

func _on_area_entered(area: Area2D) -> void:
	# Ignora tudo que não seja outro escudo em dash
	if state != State.DASHING or _ja_caiu:
		return
	if not area.is_in_group("shield"):
		return

	# --- SÓ 1 CAI ---
	# Este escudo (que detectou) cai; o outro desaparece.
	_ja_caiu = true
	cair_no_chao()
	if area.has_method("desaparecer"):
		area.desaparecer()

## Chamado pelo escudo que caiu: este some sem deixar pickup.
func desaparecer() -> void:
	if _ja_caiu:
		return
	_ja_caiu = true
	state = State.DROPPED
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	await tween.finished
	queue_free()

func cair_no_chao() -> void:
	state = State.DROPPED
	set_shader_glow(0.0)
	remove_from_group("shield")
	add_to_group("pickup_shield")

	# Solta um pequeno pulo antes de cair (feedback visual)
	var tween = create_tween()
	tween.tween_property(self, "global_position:y", global_position.y - 20.0, 0.1)
	tween.tween_property(self, "global_position:y", global_position.y + 60.0, 0.3)
	await tween.finished

	# Pulsa suavemente para indicar que é colecionavel
	var pulso = create_tween().set_loops()
	pulso.tween_method(set_shader_glow, 0.0, 1.5, 0.6)
	pulso.tween_method(set_shader_glow, 1.5, 0.0, 0.6)
