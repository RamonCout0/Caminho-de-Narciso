extends CharacterBody2D

# --- NÓS E RECURSOS ---
@onready var animated_sprite = $AnimatedSprite2D
@onready var footstep_sound = $FootstepSound
@onready var lanterna = $Lanterna
@onready var som_lanterna = $SomLanterna
@onready var som_dano = $SomDano
@onready var som_cura = $SomCura

# --- CONFIGURAÇÕES ---
@export var max_speed: int = 150
@export var acceleration: int = 1500
@export var friction: int = 1200

var current_direction = "down"

func _ready():
	# <-- NOVA LINHA: Garante que a lanterna comece ligada
	if lanterna:
		lanterna.enabled = true

func _physics_process(delta):
	# --- TRAVA DE DIÁLOGO ---
	# Procura a caixa de diálogo na cena atual
	var ui_dialogo = get_tree().current_scene.find_child("DialogueBox", true, false)
	
	# Se a caixa existir e estiver visível, o player congela
	if ui_dialogo and ui_dialogo.visible:
		velocity = Vector2.ZERO
		move_and_slide()
		footstep_sound.stop() # Garante que o som de passos pare
		handle_animations(Vector2.ZERO) # Força a animação de Idle
		return # Interrompe o restante do código de movimento
	# ------------------------

	var input_direction = Input.get_vector("mv_left", "mv_right", "mv_up", "mv_down")
	var target_velocity = input_direction * max_speed
	
	if input_direction.length() > 0:
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
		if !footstep_sound.playing:
			footstep_sound.pitch_scale = randf_range(0.8, 1.2)
			footstep_sound.play()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		footstep_sound.stop()
	
	move_and_slide()
	handle_animations(input_direction)

# --- NOVA FUNÇÃO: _process RODA A CADA FRAME PARA O MOUSE E BOTÕES ---
func _process(_delta):
	if lanterna:
		# 1. Faz APENAS a lanterna girar para o mouse
		lanterna.look_at(get_global_mouse_position())
		
		# 2. O botão de Ligar/Desligar
		if Input.is_action_just_pressed("toggle_lanterna"):
			lanterna.enabled = !lanterna.enabled
			som_lanterna.play()

func handle_animations(input_direction: Vector2):
	if input_direction.length() > 0:
		if abs(input_direction.x) > abs(input_direction.y):
			current_direction = "side"
			animated_sprite.play("walk_side")
			animated_sprite.flip_h = (input_direction.x > 0)
		else:
			if input_direction.y > 0:
				current_direction = "down"
				animated_sprite.play("walk_down")
			else:
				current_direction = "up"
				animated_sprite.play("walk_up")
			animated_sprite.flip_h = false
	else:
		match current_direction:
			"down": animated_sprite.play("idle_down")
			"up": animated_sprite.play("idle_up")
			"side": animated_sprite.play("idle_side")
			
#FUNÇÃO DE HP(CHAMANDO O GAMELOADER)===========================================
func levar_dano(quantidade: int):
	#chamando o autoload
	GameManager.take_damage(quantidade)
	if som_dano:
		som_dano.pitch_scale = randf_range(0.9, 1.1)
		som_dano.play()
	
	#feedback visual
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(animated_sprite, "modulate",Color.WHITE, 0.1)
	
	

func receber_cura(quantidade: int):
	if som_cura:
		som_cura.pitch_scale = randf_range(1.0, 1.2) # Um tom um pouco mais agudo soa mais "alegre"
		som_cura.play()
	# Se já estiver com vida cheia, talvez você não queira gastar o item?
	# Se quiser gastar mesmo assim, apenas chame o GameManager:
	GameManager.heal(quantidade)
	
	# Feedback Visual (Flash Verde)
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color.GREEN, 0.1)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)


func _on_item_cura_body_entered(_body: Node2D) -> void:
	pass # Replace with function body.
