extends Area2D

@export var cura_quantidade: int = 1
@export var cura_sanidade: bool = true  ## Se verdadeiro, também restaura a sanidade para 100

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.has_method("receber_cura"):
			body.receber_cura(cura_quantidade)
		if cura_sanidade:
			GameManager.tomar_remedio()
		queue_free()
