extends Area2D

# --- CATEGORIAS NO INSPECTOR ---
@export_group("Conteúdo do Diálogo")
@export var lista_sequencial: Array[String] = ["Ei! O que você está fazendo aqui?", "As luzes acabaram de cair...", "Tome cuidado."]
@export var velocidade_digitacao: float = 1.5

@export_group("Áudio")
@export var tom_minimo: float = 0.9
@export var tom_maximo: float = 1.2

# --- VARIÁVEIS INTERNAS ---
var dialogo_aberto: bool = false
var indice_atual: int = 0
var animacao_texto: Tween
var esta_digitando: bool = false

@onready var dialogue_sound = $DialogueSound

func _ready():
	# Conecta os sinais
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if body.is_in_group("player"):
		# Se o diálogo ainda não estiver aberto, inicia automaticamente
		if not dialogo_aberto:
			gerenciar_fluxo_dialogo()

func _on_body_exited(body):
	if body.is_in_group("player"):
		fechar_dialogo()
		indice_atual = 0 # Reinicia a conversa para a próxima vez que entrar

func _input(event):
	# O 'E' agora serve apenas para PULAR a animação ou AVANÇAR para a próxima frase
	if event.is_action_pressed("interagir") and dialogo_aberto:
		if esta_digitando:
			pular_animacao()
		else:
			gerenciar_fluxo_dialogo()

func gerenciar_fluxo_dialogo():
	if lista_sequencial.size() > 0 and indice_atual < lista_sequencial.size():
		mostrar_frase(lista_sequencial[indice_atual])
		indice_atual += 1
	else:
		fechar_dialogo()

func mostrar_frase(texto: String):
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
		animacao_texto.tween_property(label, "visible_characters", texto.length(), velocidade_digitacao)
		
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
