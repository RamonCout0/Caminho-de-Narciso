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
	
	get_tree().change_scene_to_file("res://Content/Scenes/Cenario1.tscn")


func _animacao_tela(tela_apagar: Control,
						tela_aparecer: Control) -> void:
							
	var tween : Tween = create_tween().set_parallel(true)
	
	tela_apagar.modulate.a = 1 
	tela_aparecer.modulate.a = 0
	
	tela_apagar.visible = true
	tela_aparecer.visible = true
	
	tween.tween_property(
		tela_apagar,"modulate:a",
		0,
		1
	)
	tween.tween_property(
		tela_aparecer,"modulate:a",
		1,
		1
	)
	tween.play()
	
	await tween.finished
	
	tela_apagar.visible = false
	tela_aparecer.visible = false
							
