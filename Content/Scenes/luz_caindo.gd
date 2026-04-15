extends Area2D

# Arraste o nó do CanvasModulate ou verifique o caminho abaixo
@onready var canvas_modulate = $"../CanvasModulate"
@onready var som_tensao = $SomTensao

@export_group("Configurações da Luz")
@export var cor_escuro: Color = Color(0.05, 0.05, 0.1, 1.0) # Quase preto
@export var tempo_transicao: float = 0.2
@export var piscar_ao_cair: bool = true

var ja_ativou: bool = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player") and not ja_ativou:
		ja_ativou = true
		ativar_queda_de_luz()

func ativar_queda_de_luz():
	# Toca o som de tensão/estalo
	if som_tensao:
		som_tensao.play()
	
	var tween = get_tree().create_tween()
	
	if piscar_ao_cair:
		# Simula a lâmpada morrendo com o som
		tween.tween_property(canvas_modulate, "color", cor_escuro, 0.05)
		tween.tween_property(canvas_modulate, "color", Color.WHITE, 0.05)
		tween.tween_property(canvas_modulate, "color", cor_escuro, 0.05)
		tween.tween_property(canvas_modulate, "color", Color.WHITE, 0.1)
		# Pequena pausa antes do apagão final
		tween.tween_interval(0.1)
	
	# Apaga de vez
	tween.tween_property(canvas_modulate, "color", cor_escuro, tempo_transicao)
