extends CharacterBody2D

# --- NÓS E RECURSOS ---
@onready var animated_sprite = $AnimatedSprite2D

# --- CONFIGURAÇÕES EXPORTADAS (Podem ser ajustadas no Inspetor) ---
@export var max_speed: int = 150   # Renomeado para clareza (velocidade máxima)
@export var acceleration: int = 1500 # Quão rápido ele atinge a velocidade máxima
@export var friction: int = 1200     # Quão rápido ele desacelera até parar


@export var inv: Inv

# --- VARIÁVEIS INTERNAS ---
var current_direction = "down"

func _physics_process(delta):
	# 1. PEGAR O INPUT
	var input_direction = Input.get_vector("mv_left", "mv_right", "mv_up", "mv_down")
	
	# 2. CALCULAR VELOCIDADE ALVO (Para onde queremos ir)
	# Se input for zero, o alvo é zero (parar). Se tiver input, o alvo é a direção * velocidade máxima.
	var target_velocity = input_direction * max_speed
	
	# 3. APLICAR MOVIMENTO FLUIDO (Inércia)
	if input_direction.length() > 0:
		# Se há input: Acelerar em direção ao alvo
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
	else:
		# Se não há input: Desacelerar (atrito) em direção a Vector2.ZERO (parar)
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	
	# 4. MOVER E LIDAR COM COLISÕES
	# move_and_slide usa a variável interna 'velocity' que acabamos de ajustar.
	move_and_slide()
	
	# 5. GERENCIAR ANIMAÇÕES (Mesma lógica anterior, mas baseada no input)
	# Usamos input_direction para animação para que o sprite mude instantaneamente 
	# quando você muda de direção, mesmo que a velocidade física ainda esteja se ajustando.
	handle_animations(input_direction)

# Esta função permanece quase idêntica à anterior
func handle_animations(input_direction: Vector2):
	if input_direction.length() > 0:
		# Determinar direção dominante
		if abs(input_direction.x) > abs(input_direction.y):
			current_direction = "side"
			animated_sprite.play("walk_side")
			
			# Inverter para DIREITA
			if input_direction.x > 0:
				animated_sprite.flip_h = true
			else:
				animated_sprite.flip_h = false
		else:
			# Movimento vertical dominante
			if input_direction.y > 0:
				current_direction = "down"
				animated_sprite.play("walk_down")
			else:
				current_direction = "up"
				animated_sprite.play("walk_up")
			animated_sprite.flip_h = false
			
	else:
		# SE O JOGADOR ESTÁ TOTALMENTE PARADO (Lógica física) OU SEM INPUT
		# Usamos o input aqui para decidir quando entrar no estado IDLE. 
		# Como a física agora tem inércia, se usássemos velocity.length() > 0 
		# aqui, ele continuaria "andando" enquanto desliza até parar. 
		# É melhor o sprite ficar em IDLE assim que soltar a tecla.
		match current_direction:
			"down": animated_sprite.play("idle_down")
			"up": animated_sprite.play("idle_up")
			"side": animated_sprite.play("idle_side")
