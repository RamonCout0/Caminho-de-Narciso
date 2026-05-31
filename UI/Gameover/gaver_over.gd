extends Control

## Cena de fallback caso o jogador morra sem nenhum checkpoint salvo.
## Na prática, com checkpoint ativo, essa var é ignorada.
@export_file("*.tscn") var cena_inicial_padrao: String = "res://UI/Menu/Orquestrador/Orquestrador.tscn"

@onready var timer = $Timer

var pode_reiniciar: bool = false

func _ready() -> void:
	timer.start()
	await get_tree().create_timer(0.5).timeout
	pode_reiniciar = true

func _input(event: InputEvent) -> void:
	if pode_reiniciar and (event is InputEventKey or event is InputEventJoypadButton):
		if event.is_pressed():
			reiniciar_jogo()

func _on_timer_timeout() -> void:
	reiniciar_jogo()

func reiniciar_jogo() -> void:
	pode_reiniciar = false
	timer.stop()

	# Reseta status antes de sair da tela
	GameManager.current_hp = GameManager.max_hp
	GameManager.current_sanity = GameManager.max_sanity
	GameManager.hp_changed.emit(GameManager.current_hp)
	GameManager.sanity_changed.emit(GameManager.current_sanity)

	# Sempre usa o checkpoint se existir; caso contrário vai pro menu/início
	if GameManager.tem_checkpoint:
		GameManager.change_scene_with_fade(GameManager.checkpoint_cena_path)
	else:
		GameManager.change_scene_with_fade(cena_inicial_padrao)
