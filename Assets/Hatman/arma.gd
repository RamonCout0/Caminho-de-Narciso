extends Node2D

@export var bullet_scene : PackedScene
var player : Node2D
@onready var sprite = $Sprite2D
@onready var marker_tiro = $Marker2D

var esta_carregando: bool = false

func _ready():
	# Surge invisível
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)
	
	# Tempo flutuando e mirando
	await get_tree().create_timer(1.5).timeout
	iniciar_carga()

func _physics_process(delta):
	# Se o player existir e a arma não estiver travada carregando o tiro, mira.
	if is_instance_valid(player) and not esta_carregando:
		# Calcula o ângulo para o player
		var direcao = player.global_position - global_position
		var angulo_alvo = direcao.angle()
		
		# Gira suavemente a arma para mirar no player (evita guinadas bruscas)
		rotation = lerp_angle(rotation, angulo_alvo, 5.0 * delta)
		
		# Opcional: Flip do sprite se passar da vertical para a arma não ficar de ponta cabeça
		if abs(rotation_degrees) > 90:
			sprite.flip_v = true
		else:
			sprite.flip_v = false

func iniciar_carga():
	esta_carregando = true # Trava a mira
	# Aqui você pode ativar o Shader 3 de brilho se tiver configurado
	await get_tree().create_timer(0.5).timeout
	atacar()

func atacar():
	if not is_instance_valid(player): 
		queue_free()
		return

	var bala = bullet_scene.instantiate()
	bala.global_position = marker_tiro.global_position
	
	# Agora a bala vai na direção que a arma está apontando (rotation)
	bala.direction = Vector2.RIGHT.rotated(rotation)
	
	# Ativa o brilho da bala
	bala.get_node("Sprite2D").material.set_shader_parameter("intensity", 3.0) 
	get_parent().add_child(bala)
	
	# Desaparece
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	queue_free()
