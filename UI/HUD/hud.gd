extends Control

# Arraste suas texturas para cá no Inspector
@export var textura_cheio: Texture2D
@export var textura_oco: Texture2D

@onready var lista_coracoes = $CanvasLayer/HBoxContainer.get_children()

func _ready():
	# Se conecta ao Autoload
	GameManager.hp_changed.connect(_atualizar_vida)
	# Garante que começa com a vida certa
	_atualizar_vida(GameManager.current_hp)

func _atualizar_vida(vida_atual: int):
	for i in range(lista_coracoes.size()):
		if i < vida_atual:
			lista_coracoes[i].texture = textura_cheio
		else:
			lista_coracoes[i].texture = textura_oco
