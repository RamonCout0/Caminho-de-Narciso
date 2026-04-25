extends Control

# Arraste suas texturas para cá no Inspector
@export var textura_cheio: Texture2D
@export var textura_oco: Texture2D

@onready var lista_coracoes = $CanvasLayer/HBoxContainer.get_children()

# --- Boss HP bar (criada dinamicamente quando o boss aparece) ---
var _boss_container : Control       = null
var _boss_label     : Label         = null
var _boss_bar       : ProgressBar   = null

func _ready() -> void:
	GameManager.hp_changed.connect(_atualizar_vida)
	_atualizar_vida(GameManager.current_hp)

	# Escuta os sinais do boss
	GameManager.boss_hp_changed.connect(_on_boss_hp_changed)
	GameManager.boss_morreu.connect(_on_boss_morreu)

func _atualizar_vida(vida_atual: int) -> void:
	for i in range(lista_coracoes.size()):
		if i < vida_atual:
			lista_coracoes[i].texture = textura_cheio
		else:
			lista_coracoes[i].texture = textura_oco

# ================================================================
# BOSS HP BAR — surge automaticamente quando o boss emite o sinal
# ================================================================

func _on_boss_hp_changed(hp_atual: int, hp_maximo: int) -> void:
	if _boss_bar == null:
		_criar_boss_bar(hp_maximo)
	_boss_bar.value = hp_atual

	# Tinge a barra de vermelho quando HP crítico (≤40% )
	var pct := float(hp_atual) / float(hp_maximo)
	if pct <= 0.4:
		_boss_bar.modulate = Color(1.0, 0.3, 0.3)
	else:
		_boss_bar.modulate = Color.WHITE

func _on_boss_morreu() -> void:
	if _boss_container:
		var tween = create_tween()
		tween.tween_property(_boss_container, "modulate:a", 0.0, 1.0)
		await tween.finished
		_boss_container.queue_free()
		_boss_container = null
		_boss_bar       = null
		_boss_label     = null

func _criar_boss_bar(hp_maximo: int) -> void:
	var canvas := $CanvasLayer

	# Container centralizado no topo da tela
	_boss_container = VBoxContainer.new()
	_boss_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_boss_container.position = Vector2(0.0, 8.0)
	canvas.add_child(_boss_container)

	# Label com o nome do boss
	_boss_label = Label.new()
	_boss_label.text                     = "■ HATMAN ■"
	_boss_label.horizontal_alignment     = HORIZONTAL_ALIGNMENT_CENTER
	_boss_label.add_theme_font_size_override("font_size", 12)
	_boss_container.add_child(_boss_label)

	# Barra de HP
	_boss_bar = ProgressBar.new()
	_boss_bar.max_value          = hp_maximo
	_boss_bar.value              = hp_maximo
	_boss_bar.show_percentage    = false
	_boss_bar.custom_minimum_size = Vector2(200.0, 14.0)
	# Centraliza a barra horizontalmente
	_boss_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_boss_container.add_child(_boss_bar)

	# Surge com fade in
	_boss_container.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(_boss_container, "modulate:a", 1.0, 0.5)
