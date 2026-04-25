extends Area2D

var direction := Vector2.ZERO
var speed := 600.0 
var is_deflected := false

func _ready():
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	global_position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("player") and not is_deflected:
		if body.has_shield:
			# Player consome o escudo
			body.consume_shield()
			
			# --- NOVA LÓGICA DE MIRA NO HATMAN ---
			# Procura o inimigo na cena
			var inimigo = get_tree().get_first_node_in_group("enemy")
			
			if inimigo:
				# Se achou o Hatman, calcula a direção exata para ele
				direction = (inimigo.global_position - global_position).normalized()
				# Opcional: faz a bala girar visualmente para apontar pro chefe
				rotation = direction.angle()
			else:
				# Se o chefe morreu ou sumiu por algum motivo, só volta pra trás
				direction *= -1 
			# -------------------------------------
			
			speed *= 2.0
			is_deflected = true
			
			# Troca as máscaras
			set_collision_mask_value(1, false) # Ignora layer 1 (Player)
			set_collision_mask_value(2, true)  # Foca layer 2 (Inimigo)
		else:
			body.levar_dano(1) # Chama a função do player
			queue_free()
			
	elif body.is_in_group("enemy") and is_deflected:
		if body.has_method("tomar_dano"):
			body.tomar_dano()
		queue_free()
