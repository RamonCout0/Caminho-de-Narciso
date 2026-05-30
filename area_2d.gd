extends Area2D

# Variável interna para o checkpoint saber se já foi usado (evita re-salvar à toa)
var ativado: bool = false

func _on_body_entered(body: Node) -> void:
	# Verifica se quem entrou na área é o jogador e se o checkpoint já não está ativo
	if body.is_in_group("player") and not ativado:
		ativado = true
		
		# Pega o caminho do arquivo da cena atual que este checkpoint está posicionado
		var cena_atual_path = get_tree().current_scene.scene_file_path
		
		# Salva a cena e a posição global deste objeto no mapa
		GameManager.salvar_checkpoint(cena_atual_path, global_position)
		
		# 💡 Feedback Visual/Sonoro: 
		# Você pode mudar a animação do seu sprite aqui para indicar que ativou!
		# $AnimatedSprite2D.play("ativado")
