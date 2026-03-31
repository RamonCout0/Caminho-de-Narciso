@export_file("*.tscn") var proxima_cena: String

var player_na_area = false

func _on_body_entered(body):
# Verifica se quem entrou na área é o jogador
	if body.is_in_group("player"):
		player_na_area = true
		print("Pressione 'E' para entrar")

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_na_area = false

func _process(_delta):
	# Se estiver na área e apertar a tecla de interação
	if player_na_area and Input.is_action_just_pressed("interagir"):
		fazer_teleporte()

func fazer_teleporte():
	if proxima_cena == "":
		print("Erro: Nenhuma cena selecionada!")
		return
get_tree().change_scene_to_file(proxima_cena)
