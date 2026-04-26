extends Area2D

@export var open_door_sprite: Texture2D 
@export_file("*.tscn") var next_scene_path: String 
@export var target_spawn: String = "" 

var is_opening: bool = false 

@onready var sprite: Sprite2D = $Sprite2D
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_opening:
		# A RESTRIÇÃO AQUI: Acessamos a variável que criamos no player
		if "pode_se_mover" in body:
			body.pode_se_mover = false
			print("[DEBUG] Movimento do Player bloqueado pela porta.")
		
		open_door_and_transition()

func open_door_and_transition() -> void:
	is_opening = true 
	
	if open_door_sprite:
		sprite.texture = open_door_sprite
	
	audio_player.play()
	
	# Pequeno delay para o jogador ver a porta abrindo antes do fade
	await get_tree().create_timer(0.2).timeout
	
	if next_scene_path != "":
		GameManager.target_spawn_point = target_spawn 
		GameManager.change_scene_with_fade(next_scene_path)
