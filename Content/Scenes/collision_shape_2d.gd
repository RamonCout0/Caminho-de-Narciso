extends CollisionShape2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
@export_file("*.tscn") var proxima_cena: String

var player_na_area = false

func _on_body_entered(body):
	# Verifica se quem entrou na área é o jogador
	if body.is_in_group("Player"):
		player_na_area = true
		print("Pressione 'E' para entrar")

func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_na_area = false

func _process(_delta):
	# Se estiver na área e apertar a tecla de interação
	if player_na_area and Input.is_action_just_pressed("interagir"):
		fazer_teleporte()

func fazer_teleporte():
	if proxima_cena == "":
		return

#Muda para a nova cena
	get_tree().change_scene_to_file("res://Content/Scenes/cenario_2.tscn")
