extends CharacterBody2D

@export var velocidade: float = 150.0

## Dê um nome ÚNICO para cada torre no Inspector (ex: "torre_fase1_sala3")
@export var id_unico_da_torre: String = "torre_padrao"

var em_movimento: bool = false
var player_na_area: bool = false

# --- SANIDADE ---
@export_group("Sanidade")
@export var range_sanidade : float = 200.0 
@export var taxa_sanidade  : float = 12.0  
const ID_AMEACA : String = "torre"

var _ameaca_registrada: bool = false
var _player_ref: Node2D = null

@onready var trilho = get_parent() as PathFollow2D 
@onready var sprite = $AnimatedSprite2D
@onready var anim_player = $AnimationPlayer
@onready var audio_move = $AudioStreamPlayer2D

func _ready():
	# 🔴 CHECAGEM DE PERSISTÊNCIA: Se esta torre já terminou no passado, ela deixa de existir
	if id_unico_da_torre in GameManager.torres_finalizadas:
		queue_free()
		return # Para a execução do código aqui para não quebrar nada
		
	sprite.play("idle")
	anim_player.play("idle")
	trilho.rotates = false 
	trilho.loop = false 

func _exit_tree() -> void:
	if _ameaca_registrada:
		GameManager.remover_ameaca(ID_AMEACA)

func _physics_process(delta):
	if em_movimento:
		trilho.progress += velocidade * delta
		
		if trilho.progress_ratio >= 1.0:
			finalizar_trajeto()

	# --- SISTEMA DE SANIDADE ---
	if _player_ref and em_movimento:
		var dist = global_position.distance_to(_player_ref.global_position)
		if dist <= range_sanidade:
			if not _ameaca_registrada:
				GameManager.registrar_ameaca(ID_AMEACA, taxa_sanidade)
				_ameaca_registrada = true
		else:
			if _ameaca_registrada:
				GameManager.remover_ameaca(ID_AMEACA)
				_ameaca_registrada = false

func iniciar_torre():
	if trilho.progress_ratio >= 1.0:
		return
		
	if not em_movimento:
		em_movimento = true
		sprite.play("move")
		anim_player.play("move")
		if not audio_move.playing:
			audio_move.play()

func parar_torre():
	em_movimento = false
	sprite.play("idle")
	anim_player.play("idle")
	
	if _ameaca_registrada:
		GameManager.remover_ameaca(ID_AMEACA)
		_ameaca_registrada = false

func finalizar_trajeto():
	em_movimento = false
	sprite.play("idle")
	anim_player.play("idle")
	audio_move.stop()
	
	if _ameaca_registrada:
		GameManager.remover_ameaca(ID_AMEACA)
		_ameaca_registrada = false
		
	# 💾 SALVA O ESTADO NO GAMEMANAGER: Avisa que essa torre específica acabou
	if not id_unico_da_torre in GameManager.torres_finalizadas:
		GameManager.torres_finalizadas.append(id_unico_da_torre)
	
	# Deleta a torre da cena atual para que ela suma do mapa imediatamente
	queue_free()

# ================= SINAIS =================

func _on_area_deteccao_body_entered(body):
	if body.is_in_group("player"):
		player_na_area = true
		_player_ref = body
		
		if not audio_move.playing:
			audio_move.play()
			
		iniciar_torre()

func _on_area_deteccao_body_exited(body):
	if body.is_in_group("player"):
		player_na_area = false
		_player_ref = null
		
		audio_move.stop()
		parar_torre()

func _on_area_dano_body_entered(body):
	if body.is_in_group("player"):
		if body.has_method("levar_dano"):
			body.levar_dano(5) 
		print("VOCÊ MORREU!")
