extends Area2D

enum State { TRACKING, CHARGING, DASHING, DROPPED }
var state = State.TRACKING

var player : Node2D
var side : int = 1
var tempo_flutuacao: float = randf() * 10.0

@onready var sprite = $AnimatedSprite2D

func _ready():
	area_entered.connect(_on_area_entered)
	sprite.material.set_shader_parameter("intensity", 0.0) # Começa sem brilho
	await get_tree().create_timer(3.0).timeout
	iniciar_carga()

func _physics_process(delta):
	tempo_flutuacao += delta
	var bobbing = sin(tempo_flutuacao * 3.0) * 5.0

	if state == State.TRACKING:
		var target_y = player.global_position.y
		global_position.y = lerp(global_position.y, target_y, delta * 5.0)
		sprite.position.y = bobbing
		
	elif state == State.DASHING:
		global_position.x -= 600.0 * side * delta
		sprite.position.y = bobbing

func iniciar_carga():
	state = State.CHARGING
	var tween = create_tween()
	tween.tween_method(set_shader_glow, 0.0, 3.0, 1.0) # Aumenta a intensidade do brilho
	await tween.finished
	state = State.DASHING

func set_shader_glow(val: float):
	sprite.material.set_shader_parameter("intensity", val)

func _on_area_entered(area):
	# Isso vai cuspir no console o nome e os grupos de QUALQUER coisa que o escudo tocar
	print("O escudo bateu em: ", area.name, " | Grupos que ele tem: ", area.get_groups())
	
	if state == State.DASHING and area.is_in_group("shield"):
		print("SUCESSO! Bateu em outro escudo! Iniciando queda...")
		cair_no_chao()
		if area.has_method("cair_no_chao"):
			area.cair_no_chao()

func cair_no_chao():
	state = State.DROPPED
	set_shader_glow(0.0)
	remove_from_group("shield")
	add_to_group("pickup_shield")
	# Desce para o chão (ajuste o valor de Y conforme o seu cenário)
	var tween = create_tween()
	tween.tween_property(self, "global_position:y", global_position.y + 50, 0.3)
	
	
