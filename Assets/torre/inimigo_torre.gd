extends CharacterBody2D

@export var velocidade: float = 150.0

var indo_para_frente: bool = true
var em_movimento: bool = false
var player_na_area: bool = false

@onready var trilho = get_parent() as PathFollow2D 
@onready var sprite = $AnimatedSprite2D
@onready var anim_player = $AnimationPlayer
@onready var audio_move = $AudioStreamPlayer2D

func _ready():
	sprite.play("idle")
	anim_player.play("idle")
	trilho.rotates = false 

func _physics_process(delta):
	if em_movimento:
		if indo_para_frente:
			trilho.progress += velocidade * delta
			if trilho.progress_ratio >= 1.0:
				indo_para_frente = false 
				verificar_parada()
		else:
			trilho.progress -= velocidade * delta
			if trilho.progress_ratio <= 0.0:
				indo_para_frente = true 
				verificar_parada()

func verificar_parada():
	if trilho.progress_ratio <= 0.0 and not player_na_area:
		parar_torre()

func iniciar_torre():
	if not em_movimento:
		em_movimento = true
		sprite.play("move")
		anim_player.play("move")
		if not audio_move.playing:
			audio_move.play()

func parar_torre():
	em_movimento = false
	sprite.play("idle")
	anim_player.play("idle")
	audio_move.stop()

# ================= SINAIS (Conecte pelo painel "Nó -> Sinais") =================

func _on_area_deteccao_body_entered(body):
	if body.is_in_group("player"):
		player_na_area = true
		iniciar_torre()

func _on_area_deteccao_body_exited(body):
	if body.is_in_group("player"):
		player_na_area = false

func _on_area_dano_body_entered(body):
	if body.is_in_group("player"):
		body.levar_dano(5)
		print("VOCÊ MORREU!")


func _on_area_dano_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
