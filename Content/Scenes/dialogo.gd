extends Area2D

@export_group("Sequencial (Em Ordem)")
@export var lista_sequencial: Array[String] = []
@export var velocidade_sequencial: float = 1.5

@export_group("Aleatório (Sorteio)")
@export var lista_aleatoria: Array[String] = []
@export var velocidade_aleatoria: float = 1.0

@export_group("Áudio")
@export var tom_minimo: float = 0.9
@export var tom_maximo: float = 1.2

var player_perto: bool = false
var dialogo_aberto: bool = false
var indice_atual: int = 0
var animacao_texto: Tween
var esta_digitando: bool = false

@onready var dialogue_sound = $DialogueSound

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		player_perto = true

func _on_body_exited(body):
	if body.is_in_group("player"):
		player_perto = false
		fechar_dialogo()
		# O segredo está aqui: só resetamos o progresso quando o player vai embora
		indice_atual = 0 

func _input(event):
	if event.is_action_pressed("interagir") and player_perto:
		if esta_digitando:
			pular_animacao()
		else:
			gerenciar_fluxo_dialogo()

func gerenciar_fluxo_dialogo():
	# 1. Se ainda houver frases na sequência, mostra a próxima
	if lista_sequencial.size() > 0 and indice_atual < lista_sequencial.size():
		mostrar_frase(lista_sequencial[indice_atual], velocidade_sequencial)
		indice_atual += 1
	# 2. Se a sequência acabou, mas a caixa ainda está aberta, o próximo clique FECHA a caixa
	elif dialogo_aberto:
		fechar_dialogo()
	# 3. Se a caixa já estava fechada e o player interagir de novo, mostra o aleatório
	elif lista_aleatoria.size() > 0:
		var frase_sorteada = lista_aleatoria.pick_random()
		mostrar_frase(frase_sorteada, velocidade_aleatoria)

func mostrar_frase(texto: String, velocidade: float):
	var box = get_tree().current_scene.find_child("DialogueBox", true, false)
	var label = get_tree().current_scene.find_child("DialogueLabel", true, false)
	
	if box and label:
		box.show()
		label.text = texto
		label.visible_characters = 0
		esta_digitando = true
		dialogo_aberto = true
		
		if animacao_texto: animacao_texto.kill()
		animacao_texto = get_tree().create_tween()
		animacao_texto.tween_property(label, "visible_characters", texto.length(), velocidade)
		
		var ultima_letra = 0
		while animacao_texto and animacao_texto.is_running():
			if label.visible_characters > ultima_letra:
				var char_atual = texto[label.visible_characters - 1]
				if char_atual != " " and char_atual != "\n":
					dialogue_sound.pitch_scale = randf_range(tom_minimo, tom_maximo)
					dialogue_sound.play()
				ultima_letra = label.visible_characters
			await get_tree().process_frame
		
		esta_digitando = false

func pular_animacao():
	if animacao_texto:
		animacao_texto.kill()
		var label = get_tree().current_scene.find_child("DialogueLabel", true, false)
		if label: label.visible_characters = -1
		esta_digitando = false
		if dialogue_sound: dialogue_sound.stop()

func fechar_dialogo():
	var box = get_tree().current_scene.find_child("DialogueBox", true, false)
	if animacao_texto: animacao_texto.kill()
	if dialogue_sound: dialogue_sound.stop()
	if box: box.hide()
	dialogo_aberto = false
