extends Area2D

# ID único deste checkpoint. Deixe vazio para gerar automaticamente a partir
# da cena + nome do nó. Cada checkpoint salva apenas UMA vez.
@export var checkpoint_id: String = ""

func _on_body_entered(body: Node) -> void:
	# Verifica se quem entrou na área é o jogador
	if body.is_in_group("player"):
		var cena_atual_path = get_tree().current_scene.scene_file_path

		# Gera um ID estável caso nenhum tenha sido definido no Inspector
		var id := checkpoint_id
		if id == "":
			id = "%s::%s" % [cena_atual_path, name]

		# Salva a cena e a posição global deste objeto no mapa.
		# O GameManager garante que cada ID seja salvo só uma vez.
		GameManager.salvar_checkpoint(id, cena_atual_path, global_position)

		# 💡 Feedback Visual/Sonoro:
		# Você pode mudar a animação do seu sprite aqui para indicar que ativou!
		# $AnimatedSprite2D.play("ativado")
