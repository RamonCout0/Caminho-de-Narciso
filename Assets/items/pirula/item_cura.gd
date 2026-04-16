extends Area2D

@export var cura_quantidade: int = 1

func _on_body_entered(body: Node2D) -> void:
	# Verifica se quem entrou foi o Player (pelo grupo ou tipo)
	if body.is_in_group("player") or body.has_method("receber_cura"):
		# Tenta curar o player
		body.receber_cura(cura_quantidade)
		
		# Some do mapa imediatamente!
		queue_free()
