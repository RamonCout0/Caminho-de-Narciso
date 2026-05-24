extends Area2D

# Referência para o Maestro que criamos no passo anterior
@export var turn_manager: Node

# A posição inicial do player no grid quando ele pisar aqui (ajuste conforme seu mapa)
@export var start_grid_x: int = 3
@export var start_grid_y: int = 7

func _ready():
	# Conecta o sinal de colisão automaticamente
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		
		# Trava de segurança igual tínhamos no C#
		if not turn_manager:
			push_error("ERRO: O TurnManager não foi associado no Inspector do Trigger!")
			return
			
		print("Iniciando a partida de Xadrez!")

		# 1. Avisa o Player para travar a movimentação normal e entrar no grid
		if body.has_method("iniciar_modo_xadrez"):
			body.iniciar_modo_xadrez(turn_manager, start_grid_x, start_grid_y)

		# 2. Inicia o loop de turnos do Maestro
		if turn_manager.has_method("start_chess_encounter"):
			turn_manager.start_chess_encounter()

		# 3. Remove o gatilho da cena para não iniciar duas vezes
		queue_free()
