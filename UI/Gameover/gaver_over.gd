extends Control

## Cena padrão caso o jogador morra SEM ter pego nenhum checkpoint ainda
@export_file("*.tscn") var cena_inicial_padrao: String = "res://Mundo.tscn" 

@onready var timer = $Timer

var pode_reiniciar: bool = false

func _ready() -> void:
	timer.start()
	# Pequeno delay para o jogador não apertar botão sem querer logo ao morrer
	await get_tree().create_timer(0.5).timeout
	pode_reiniciar = true

func _input(event: InputEvent) -> void:
	# Se o jogador apertar qualquer tecla do teclado ou botão do controle
	if pode_reiniciar and (event is InputEventKey or event is InputEventJoypadButton):
		if event.is_pressed():
			reiniciar_jogo()

func _on_timer_timeout() -> void:
	# Acaba os 7 segundos automaticamente
	reiniciar_jogo()

func reiniciar_jogo() -> void:
	# Desconecta para evitar chamadas duplas
	pode_reiniciar = false
	timer.stop()
	
	# Reseta os status do GameManager para o jogador renascer bem
	GameManager.current_hp = GameManager.max_hp
	GameManager.current_sanity = GameManager.max_sanity
	
	# 🔴 AJUSTE INTELIGENTE DE REINÍCIO:
	# Se o jogador passou por um checkpoint, jogamos ele para a cena salva.
	# Caso contrário, ele volta para a cena inicial padrão do início do jogo.
	if GameManager.tem_checkpoint:
		GameManager.change_scene_with_fade(GameManager.checkpoint_cena_path)
	else:
		GameManager.change_scene_with_fade(cena_inicial_padrao)
