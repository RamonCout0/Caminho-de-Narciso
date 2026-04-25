extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	# Garante que o jogo comece sem a tela preta na frente
	color_rect.hide() 

# Esta é a nossa função global que substitui o get_tree().change_scene_to_file()
func change_scene(target_path: String) -> void:
	color_rect.show() # Mostra o retângulo
	
	# 1. Faz o Fade Out (Tela fica preta)
	anim_player.play("fade_to_black")
	await anim_player.animation_finished
	
	# 2. Carrega a nova fase enquanto a tela está preta (escondido do jogador)
	var error = get_tree().change_scene_to_file(target_path)
	if error != OK:
		printerr("[ERRO] Falha ao carregar cena: ", target_path)
	
	# 3. Faz o Fade In (Tela volta a ficar transparente)
	# Tocar a animação "de trás pra frente" economiza o trabalho de criar duas animações!
	anim_player.play_backwards("fade_to_black")
	await anim_player.animation_finished
	
	color_rect.hide() # Esconde o retângulo para não bugar cliques do mouses
