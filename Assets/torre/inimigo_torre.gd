extends CharacterBody2D

@export var velocidade: float = 150.0

var indo_para_frente: bool = true
var em_movimento: bool = false
var player_na_area: bool = false

# --- SANIDADE ---
# A Torre é uma máquina imparável e opressiva.
@export_group("Sanidade")
@export var range_sanidade : float = 200.0 ## Distância (px) a partir da qual começa a drenar sanidade
@export var taxa_sanidade  : float = 12.0  ## Drenagem de sanidade por segundo (torre em movimento)
const ID_AMEACA : String = "torre"

# Referência ao player guardada quando ele entra na área de detecção
var _player_ref: Node2D = null

@onready var trilho = get_parent() as PathFollow2D 
@onready var sprite = $AnimatedSprite2D
@onready var anim_player = $AnimationPlayer
@onready var audio_move = $AudioStreamPlayer2D

func _ready():
	sprite.play("idle")
	anim_player.play("idle")
	trilho.rotates = false 

func _exit_tree() -> void:
	# Garante limpeza ao sair da cena
	GameManager.remover_ameaca(ID_AMEACA)

func _physics_process(delta):
	if em_movimento:
		if indo_para_frente:
			trilho.progress += velocidade * delta
			if trilho.progress_ratio >= 1.0:
				indo_para_frente = false 
				verificar_parada()
		else:
			trilho.progress -= velocidade * delta
			if trilho.progress_ratio <= 0.0:
				indo_para_frente = true 
				verificar_parada()

	# --- SANIDADE: check de distância por script (independente de CollisionShape) ---
	if _player_ref and em_movimento:
		var dist = global_position.distance_to(_player_ref.global_position)
		if dist <= range_sanidade:
			GameManager.registrar_ameaca(ID_AMEACA, taxa_sanidade)
		else:
			GameManager.remover_ameaca(ID_AMEACA)

func verificar_parada():
	if trilho.progress_ratio <= 0.0 and not player_na_area:
		parar_torre()

func iniciar_torre():
	if not em_movimento:
		em_movimento = true
		sprite.play("move")
		anim_player.play("move")
		if not audio_move.playing:
			audio_move.play()
		# Sanidade gerenciada pelo check de distância em _physics_process

func parar_torre():
	em_movimento = false
	sprite.play("idle")
	anim_player.play("idle")
	audio_move.stop()
	# --- SANIDADE: Torre parada não amedronta ---
	GameManager.remover_ameaca(ID_AMEACA)

# ================= SINAIS (Conecte pelo painel "Nó -> Sinais") =================

func _on_area_deteccao_body_entered(body):
	if body.is_in_group("player"):
		player_na_area = true
		_player_ref = body
		iniciar_torre()

func _on_area_deteccao_body_exited(body):
	if body.is_in_group("player"):
		player_na_area = false
		_player_ref = null
		# Player saiu da área — remove ameaça independente de distância
		GameManager.remover_ameaca(ID_AMEACA)

func _on_area_dano_body_entered(body):
	if body.is_in_group("player"):
		body.levar_dano(5)
		print("VOCÊ MORREU!")


func _on_area_dano_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
