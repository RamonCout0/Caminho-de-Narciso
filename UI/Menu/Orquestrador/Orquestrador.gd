extends Node

@onready var menu_principal = $MenuPrincipal
@onready var tela_opcoes = $Opcoes

func _on_opcoes_pressed() -> void:
	menu_principal.visible = false

func _on_menu_pressed() -> void:
	menu_principal.visible = true

func _on_sair_pressed() -> void:
	get_tree().quit(0)

func _on_jogar_pressed() -> void:
	# Novo jogo: zera qualquer checkpoint/progresso salvo antes de começar
	GameManager.iniciar_novo_jogo()
	GameManager.change_scene_with_fade("res://Content/Scenes/recepção.tscn")

## Liga este método a um botão "Continuar" para retomar do último checkpoint.
func _on_continuar_pressed() -> void:
	if GameManager.tem_checkpoint:
		GameManager.respawnar_no_checkpoint()
	else:
		# Sem save: cai no comportamento de jogo novo
		_on_jogar_pressed()

func _animacao_tela(tela_apagar: Control, tela_aparecer: Control) -> void:
	var tween: Tween = create_tween().set_parallel(true)

	tela_apagar.modulate.a = 1
	tela_aparecer.modulate.a = 0
	tela_apagar.visible = true
	tela_aparecer.visible = true

	tween.tween_property(tela_apagar, "modulate:a", 0, 1)
	tween.tween_property(tela_aparecer, "modulate:a", 1, 1)
	tween.play()

	await tween.finished

	tela_apagar.visible = false
	tela_aparecer.visible = false
