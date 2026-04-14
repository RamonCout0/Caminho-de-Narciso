extends CharacterBody2D

# --- NÓS E RECURSOS ---
@onready var animated_sprite = $AnimatedSprite2D
@onready var footstep_sound = $FootstepSound # Adicionado o nó de som

# --- CONFIGURAÇÕES ---
@export var max_speed: int = 150
@export var acceleration: int = 1500
@export var friction: int = 1200
@export var inv: Inv

var current_direction = "down"

func _physics_process(delta):
	var input_direction = Input.get_vector("mv_left", "mv_right", "mv_up", "mv_down")
	var target_velocity = input_direction * max_speed
	
	if input_direction.length() > 0:
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
		# Tocar som de passos se estiver se movendo e o som não estiver tocando
		if !footstep_sound.playing:
			footstep_sound.pitch_scale = randf_range(0.8, 1.2)
			footstep_sound.play()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		# Opcional: Parar o som imediatamente ao soltar a tecla
		footstep_sound.stop()
	
	move_and_slide()
	handle_animations(input_direction)

func handle_animations(input_direction: Vector2):
	# ... (Sua lógica de animação continua igual)
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
