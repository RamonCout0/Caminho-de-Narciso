extends CharacterBody2D

# ================================================================
# HATMAN — Boss de combate
# Ciclo: Surge do chão → Spawna arma perto do player → Spawna 2
# escudos nas bordas da câmera que se chocam (só 1 cai como pickup)
# → Player pega escudo e rebate a bala → Hatman toma dano → repete
# ================================================================

@export_group("Referências")
@export var weapon_scene : PackedScene
@export var shield_scene : PackedScene

@export_group("Combate")
@export var hp_max        : int   = 3
@export var taxa_sanidade : float = 25.0  ## Drenagem de sanidade na aura

@export_group("Timing")
@export var tempo_arma          : float = 3.0   ## Espera antes de spawnar os escudos
@export var tempo_entre_escudos : float = 1.0   ## Delay entre escudo esquerdo e direito
@export var tempo_respiro       : float = 4.0   ## Pausa entre ciclos
@export var shield_respawn_delay: float = 5.0   ## Tempo para novo par de escudos após coleta

@onready var sprite      = $Sprite2D
@onready var aura_trevas = $Aura_Trevas

var player : Node2D
var hp     : int

func _ready() -> void:
	add_to_group("enemy")  # ESSENCIAL: a bala usa is_in_group("enemy") para detectar o boss
	hp = hp_max
	player = get_tree().get_first_node_in_group("player")
	aura_trevas.body_entered.connect(_on_aura_entered)
	aura_trevas.body_exited.connect(_on_aura_exited)
	# Avisa a HUD que o boss apareceu
	GameManager.notificar_boss_hp(hp, hp_max)
	iniciar_combate()

# --------------- INICIALIZAÇÃO ---------------

func iniciar_combate() -> void:
	var tween = create_tween()
	tween.tween_method(set_shader_progress, 0.0, 1.0, 2.0)
	await tween.finished
	loop_de_ataque()

func set_shader_progress(val: float) -> void:
	sprite.material.set_shader_parameter("progress", val)

# --------------- LOOP PRINCIPAL ---------------

func loop_de_ataque() -> void:
	while is_instance_valid(player) and hp > 0:
		# 1. Spawna a arma perto do player (dentro da câmera)
		spawn_arma_na_camera()
		await get_tree().create_timer(tempo_arma).timeout
		if hp <= 0: break

		# 2. Spawna os 2 escudos nas bordas da câmera
		spawn_escudo(-1)  # borda esquerda
		await get_tree().create_timer(tempo_entre_escudos).timeout
		if hp <= 0: break
		spawn_escudo(1)   # borda direita

		# 3. Respiro antes do próximo ciclo
		await get_tree().create_timer(tempo_respiro).timeout

# --------------- CÂMERA ---------------

## Retorna o rect do viewport do player no espaço global.
func _get_rect_camera() -> Rect2:
	var cam  := get_viewport().get_camera_2d()
	var vp   := get_viewport().get_visible_rect().size
	if cam:
		vp /= cam.zoom
	var centro := cam.global_position if cam else player.global_position
	return Rect2(centro - vp * 0.5, vp)

# --------------- SPAWN ---------------

func spawn_arma_na_camera() -> void:
	if not is_instance_valid(player): return
	var arma = weapon_scene.instantiate()
	arma.player = player

	# Gera posição em anel ao redor do player, garantida dentro da câmera
	var cam_rect: Rect2 = _get_rect_camera()
	var margem: float   = 48.0
	var safe: Rect2     = Rect2(cam_rect.position + Vector2(margem, margem),
						cam_rect.size - Vector2(margem * 2.0, margem * 2.0))

	var angulo:   float   = randf() * TAU
	var dist_max: float   = min(160.0, safe.size.x * 0.28)
	var offset:   Vector2 = Vector2(cos(angulo), sin(angulo)) * randf_range(80.0, dist_max)
	var pos:      Vector2 = player.global_position + offset
	pos.x = clamp(pos.x, safe.position.x, safe.end.x)
	pos.y = clamp(pos.y, safe.position.y, safe.end.y)

	arma.global_position = pos
	get_parent().add_child(arma)

func spawn_escudo(side: int) -> void:
	if not is_instance_valid(player): return
	var shield = shield_scene.instantiate()
	shield.side   = side
	shield.player = player
	shield.hatman = self  # referência para o escudo notificar o boss ao cair

	# Spawna na borda esquerda/direita da câmera, na altura do player
	var cam_rect := _get_rect_camera()
	var margem   := 24.0
	var x := cam_rect.position.x + margem if side == -1 else cam_rect.end.x - margem
	shield.global_position = Vector2(x, player.global_position.y)
	get_parent().add_child(shield)

# --------------- DANO E MORTE ---------------

func tomar_dano() -> void:
	hp -= 1
	GameManager.notificar_boss_hp(hp, hp_max)

	# Flash branco de dano
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(3.0, 3.0, 3.0), 0.05)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)

	if hp <= 0:
		_morrer()

func _morrer() -> void:
	GameManager.remover_ameaca("boss_simples")
	GameManager.notificar_boss_morreu()
	# Fade out com dissolve
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 1.2)
	await tween.finished
	queue_free()

# --------------- SANIDADE / AURA ---------------

func _on_aura_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.registrar_ameaca("boss_simples", taxa_sanidade)

func _on_aura_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.remover_ameaca("boss_simples")
