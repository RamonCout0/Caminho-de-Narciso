extends CharacterBody2D

@export var weapon_scene : PackedScene
@export var shield_scene : PackedScene

@onready var sprite = $Sprite2D
@onready var aura_trevas = $Aura_Trevas

var player : Node2D
var hp: int = 3

func _ready():
	player = get_tree().get_first_node_in_group("player")
	aura_trevas.body_entered.connect(_on_aura_entered)
	aura_trevas.body_exited.connect(_on_aura_exited)
	iniciar_combate()

func iniciar_combate():
	# 1. Surgimento do chão (apenas uma vez)
	var tween = create_tween()
	tween.tween_method(set_shader_progress, 0.0, 1.0, 2.0)
	await tween.finished
	
	# 2. Entra no ciclo infinito de ataque
	loop_de_ataque()

func loop_de_ataque():
	# Enquanto o player existir e o inimigo estiver vivo
	while is_instance_valid(player) and hp > 0:
		spawn_arma_perto_do_player()
		
		# Espera a arma atirar
		await get_tree().create_timer(3.0).timeout
		
		# Spawna os escudos
		spawn_shield(-1) # Esquerda
		await get_tree().create_timer(1.0).timeout
		spawn_shield(1)  # Direita
		
		# Tempo de "respiro" pro jogador antes de começar tudo de novo
		await get_tree().create_timer(4.0).timeout

func set_shader_progress(val: float):
	sprite.material.set_shader_parameter("progress", val)

func spawn_arma_perto_do_player():
	var arma = weapon_scene.instantiate()
	arma.player = player
	var angulo = randf() * TAU
	var distancia = randf_range(150.0, 250.0)
	var offset = Vector2(cos(angulo), sin(angulo)) * distancia
	
	arma.global_position = player.global_position + offset
	get_parent().add_child(arma)

func spawn_shield(side: int):
	var shield = shield_scene.instantiate()
	shield.side = side
	shield.player = player
	# Spawna nos cantos (ex: 400 pixels de distância)
	shield.global_position = Vector2(global_position.x + (400 * side), global_position.y)
	get_parent().add_child(shield)

# --- Sanidade e Dano ---
func _on_aura_entered(body: Node2D):
	if body.is_in_group("player"):
		GameManager.registrar_ameaca("boss_simples", 25.0)

func _on_aura_exited(body: Node2D):
	if body.is_in_group("player"):
		GameManager.remover_ameaca("boss_simples")

func tomar_dano():
	hp -= 1
	if hp <= 0:
		GameManager.remover_ameaca("boss_simples")
		queue_free()
