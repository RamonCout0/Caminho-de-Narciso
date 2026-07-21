extends CharacterBody2D

# ================================================================
# ELE SABE — perseguidor direto.
# Fica parado até o player entrar na AreaDeteccao; a partir daí
# persegue em linha reta e drena sanidade enquanto estiver atrás dele.
# ================================================================

@export var velocidade: float = 150.0

# --- SANIDADE ---
@export_group("Sanidade")
@export var taxa_sanidade: float = 5.0 ## Drenagem de sanidade por segundo (durante a perseguição)

# ID único por instância para não conflitar com outros "ele sabe" na mesma cena
var _id_ameaca: String = ""
var _ameaca_registrada: bool = false

var _alvo: Node2D = null

@onready var som_perseguicao = $AudioStreamPlayer2D
@onready var som_passos      = $SomPassos
@onready var area_deteccao   = $AreaDeteccao
@onready var anim            = $AnimatedSprite2D

func _ready() -> void:
	_id_ameaca = "ele_sabe_%d" % get_instance_id()

	area_deteccao.body_entered.connect(_on_body_entered)
	area_deteccao.body_exited.connect(_on_body_exited)

	anim.play("idle")

## Garante que a drenagem de sanidade não sobreviva à troca de cena.
func _exit_tree() -> void:
	_parar_ameaca()

func _physics_process(_delta: float) -> void:
	if _alvo:
		var direcao = (_alvo.global_position - global_position).normalized()
		velocity = direcao * velocidade

		if direcao.x != 0:
			anim.flip_h = direcao.x < 0

		if anim.animation != "run":
			anim.play("run")

		# --- SANIDADE: drena enquanto persegue ---
		if not _ameaca_registrada:
			GameManager.registrar_ameaca(_id_ameaca, taxa_sanidade)
			_ameaca_registrada = true

		# --- SOM DE PERSEGUIÇÃO ---
		if not som_perseguicao.playing:
			som_perseguicao.play()

		# --- SOM DE PASSOS ---
		if velocity.length() > 10 and not som_passos.playing:
			som_passos.pitch_scale = randf_range(0.8, 1.2)
			som_passos.play()

		move_and_slide()
	else:
		velocity = Vector2.ZERO

		if anim.animation != "idle":
			anim.play("idle")

		# --- SANIDADE: para de drenar quando perde o player ---
		_parar_ameaca()

		if som_perseguicao.playing: som_perseguicao.stop()
		if som_passos.playing: som_passos.stop()

func _parar_ameaca() -> void:
	if _ameaca_registrada:
		GameManager.remover_ameaca(_id_ameaca)
		_ameaca_registrada = false

# ================= SINAIS =================

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_alvo = body
		print("Inimigo avistou o player! Iniciando perseguição.")

func _on_body_exited(body: Node2D) -> void:
	if body == _alvo:
		_alvo = null
		print("Player escapou.")
