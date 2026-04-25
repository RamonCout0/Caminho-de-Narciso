extends Area2D

var direction   := Vector2.ZERO
var speed       := 600.0
var is_deflected := false

@onready var sprite = $Sprite2D

func _ready() -> void:
	# IMPORTANTE: a bala não é um escudo.
	# O .tscn herdou o grupo "shield" por engano — removemos aqui.
	remove_from_group("shield")
	add_to_group("bullet")
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	# Auto-destrui se sair muito longe da origem (evita bala infinita)
	if global_position.distance_to(Vector2.ZERO) > 8000.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	# --- ACERTOU O PLAYER ---
	if body.is_in_group("player") and not is_deflected:
		if body.has_shield:
			_deflectir(body)
		else:
			body.levar_dano(1)
			queue_free()

	# --- ACERTOU O BOSS (bala deflectida) ---
	elif body.is_in_group("enemy") and is_deflected:
		if body.has_method("tomar_dano"):
			body.tomar_dano()
		queue_free()

func _deflectir(player_body: Node2D) -> void:
	player_body.consume_shield()

	# Mira no boss
	var boss = get_tree().get_first_node_in_group("enemy")
	if boss:
		direction = (boss.global_position - global_position).normalized()
		rotation  = direction.angle()
	else:
		direction *= -1

	speed        *= 2.0
	is_deflected  = true
	# Não alteramos as máscaras: o Hatman está na layer 1 (padrão) e a bala
	# já estava nessa layer. A lógica de alvo é feita por grupo em _on_body_entered.

	# Feedback visual: flash + cor azul na bala deflectida
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(0.3, 0.8, 2.0), 0.05)
	tween.tween_property(sprite, "scale",    Vector2(2.0, 2.0),    0.05)
	tween.tween_property(sprite, "scale",    Vector2(1.0, 1.0),    0.1)
	sprite.material.set_shader_parameter("glow_color", Color(0.0, 0.5, 1.0))
	sprite.material.set_shader_parameter("intensity",  5.0)
