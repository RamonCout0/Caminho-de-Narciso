extends Area2D

# Configurações via Inspector
@export_file("*.tscn") var next_scene_path: String 
@export var target_spawn: String = "" 

var is_triggered: bool = false 

func _on_body_entered(body: Node2D) -> void:
	# Verifica se é o jogador e se ainda não foi ativado
	if body.is_in_group("player") and not is_triggered:
		is_triggered = true
		
		# Bloqueia o movimento do jogador (usando a trava que criamos antes)
		if "pode_se_mover" in body:
			body.pode_se_mover = false
		
		print("[DEBUG TRIGGER] Ativado! Indo para: ", next_scene_path)
		
		# Envia os dados para o seu GameManager global
		GameManager.target_spawn_point = target_spawn 
		GameManager.change_scene_with_fade(next_scene_path)
