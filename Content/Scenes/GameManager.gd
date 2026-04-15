extends Node


# Armazena a cor global da iluminação
var cor_da_luz: Color = Color.WHITE

# Dentro do GameManager.gd
func atualizar_luz_da_cena_atual():
	# Pega a cena que está rodando agora
	var cena_atual = get_tree().current_scene
	var luz = cena_atual.find_child("CanvasModulate", true, false)
	
	if luz:
		luz.color = cor_da_luz
