extends CharacterBody2D

@export var speed: int = 300
@export var inv:Inv

func _physics_process(delta):
	# Pega o vetor de direção do Input (ex: (1, 0) para a direita).
	var input_direction = Input.get_vector("mv_left", "mv_right", "mv_up", "mv_down")
	
	# Define a velocidade multiplicando a direção pela rapidez.
	velocity = input_direction * speed
	
	# Move o corpo e trata colisões.
	move_and_slide()
