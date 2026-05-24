extends Node
class_name ChessTurnManager

@export var fila_de_pecas: Array[Node2D]
@onready var musica = $MusicaXadrez # O nó AudioStreamPlayer que você criou

var index_atual: int = 0
var is_encounter_active: bool = false

signal player_turn_started

func start_chess_encounter():
	if is_encounter_active: return # Evita iniciar duas vezes
	
	is_encounter_active = true
	index_atual = 0 # Reseta a fila
	
	if musica:
		musica.play()
		print("🎵 Dança Húngara iniciada!")
		
	iniciar_turno_player()

func iniciar_turno_player():
	if not is_encounter_active: return
	print("[TurnManager] 🎮 Turno do PLAYER")
	player_turn_started.emit()

# O Player chama isso quando termina a animação de andar
func player_finished_move():
	if not is_encounter_active: return
	turno_da_bailarina()

func turno_da_bailarina():
	if fila_de_pecas.is_empty():
		iniciar_turno_player()
		return

	var bailarina = fila_de_pecas[index_atual]
	
	if is_instance_valid(bailarina) and bailarina.has_method("execute_turn"):
		print("[TurnManager] 🩰 Turno de: ", bailarina.name)
		await bailarina.execute_turn()
	
	index_atual += 1
	if index_atual >= fila_de_pecas.size():
		index_atual = 0
		
	iniciar_turno_player()

# Chamado pelo Player quando ele ganha o jogo (chega na linha 0)
func finalizar_encontro():
	is_encounter_active = false
	if musica:
		var tween = create_tween()
		tween.tween_property(musica, "volume_db", -80, 1.5)
		await tween.finished
		musica.stop()
		musica.volume_db = 0
	print("🏁 Encontro finalizado!")
