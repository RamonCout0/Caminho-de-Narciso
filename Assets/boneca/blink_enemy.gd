extends CharacterBody2D

@onready var sprite : Sprite2D            = $Sprite2D
@onready var audio  : AudioStreamPlayer2D = $AudioStreamPlayer2D

@export var player : Node2D

# ⭐ COMPORTAMENTO
@export var detection_range     : float = 100.0  # Quando começa a perseguir
@export var attack_range        : float = 50.0   # Quando ataca
@export var move_speed          : float = 28.0   # Velocidade de perseguição

# ⭐ LANTERNA (Novas configurações)
@export var flashlight_cone_angle : float = 30.0 # Abertura do cone de luz (graus)
@export var flashlight_max_dist   : float = 250.0 # Distância máxima que a luz cega o inimigo

# ⭐ SANIDADE
@export_group("Sanidade")
@export var range_sanidade  : float = 150.0 ## Distância (px) a partir da qual começa a drenar sanidade
@export var taxa_sanidade   : float = 8.0   ## Drenagem de sanidade por segundo

# ⭐ TELEPORTE E PISCADA
@export var teleport_delay      : float = 19.0   # Tempo MÍNIMO entre teleportes
@export var teleport_jump       : float = 120.0
@export var teleport_jump_grow  : float = 18.0

@export var shader_blink_interval : float = 4.0
@export var shader_blink_count    : float = 2.0
@export var shader_blink_speed    : float = 0.18
@export var shader_close_ratio    : float = 0.35

var shader_mat          : ShaderMaterial
var _current_jump       : float
var _burst_duration     : float
var _full_cycle         : float
var _elapsed            : float = 0.0

# ⭐ ESTADOS
var _player_in_range    : bool  = false  # Detectado?
var _is_in_burst        : bool  = false  # Piscando?
var _can_teleport       : bool  = true   # Cooldown de TP?
var _blinked_this_burst : bool  = false
var _is_attacking       : bool  = false

# ⭐ FADE DE TELA
var _fade_overlay : CanvasLayer
var _fade_rect    : ColorRect


func _ready() -> void:
	_current_jump   = teleport_jump
	_burst_duration = shader_blink_count * shader_blink_speed
	_full_cycle     = _burst_duration + shader_blink_interval

	shader_mat = sprite.material as ShaderMaterial
	if shader_mat:
		shader_mat.set_shader_parameter("blink_interval", shader_blink_interval)
		shader_mat.set_shader_parameter("blink_count",    shader_blink_count)
		shader_mat.set_shader_parameter("blink_speed",    shader_blink_speed)
		shader_mat.set_shader_parameter("close_ratio",    shader_close_ratio)
		shader_mat.set_shader_parameter("u_time",         0.0)

	if not player:
		push_error("BlinkEnemy: arrasta o jogador no campo Player do Inspector!")

	# ⭐ Cria overlay de fade
	_create_fade_overlay()


func _create_fade_overlay() -> void:
	_fade_overlay = CanvasLayer.new()
	_fade_overlay.layer = 100  # Acima de tudo
	add_child(_fade_overlay)

	_fade_rect = ColorRect.new()
	_fade_rect.anchor_left   = 0
	_fade_rect.anchor_top    = 0
	_fade_rect.anchor_right  = 1
	_fade_rect.anchor_bottom = 1
	_fade_rect.color = Color(0, 0, 0, 0)  # Transparente
	_fade_overlay.add_child(_fade_rect)


func _physics_process(delta: float) -> void:
	if not player:
		return

	_elapsed += delta
	if shader_mat:
		shader_mat.set_shader_parameter("u_time", _elapsed)

	# ⭐ Detecta se jogador está em range
	var dist_to_player = global_position.distance_to(player.global_position)
	_player_in_range = dist_to_player <= detection_range

	# Sanidade: drena apenas quando o player está dentro do range_sanidade
	if dist_to_player <= range_sanidade:
		GameManager.registrar_ameaca("boneca", taxa_sanidade)
	else:
		GameManager.remover_ameaca("boneca")

	# Se jogador não está em range → para
	if not _player_in_range:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# ⭐ SISTEMA DE LANTERNA (Congela o inimigo)
	if esta_sendo_iluminado():
		velocity = Vector2.ZERO
		move_and_slide()
		return # Para de processar a perseguição neste frame

# <-- NOVA TRAVA: Se já está atacando, não faz mais nada até terminar!
	if _is_attacking:
		return

	# ⭐ Jogador está em range e NÃO está iluminado - começa a perseguir
	_check_blink(_elapsed)

	# Se está no ataque → não persegue, só teleporta
	if dist_to_player <= attack_range:
		velocity = Vector2.ZERO
		_on_reach_player()
	else:
		# Persegue normalmente
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * move_speed
		move_and_slide()


# --- NOVA FUNÇÃO: DETECÇÃO DE LUZ INDEPENDENTE ---
func esta_sendo_iluminado() -> bool:
	# 1. Pega a lanterna pelo grupo, não importa onde ela esteja na cena
	var lanterna = get_tree().get_first_node_in_group("lanterna_player")
	
	# Se não existir lanterna na cena ou ela estiver desligada, ignora
	if not lanterna or not lanterna.enabled:
		return false
		
	# 2. Verifica a distância (medindo direto da lanterna para o inimigo)
	var dist = global_position.distance_to(lanterna.global_position)
	if dist > flashlight_max_dist:
		return false
		
	# 3. Verifica o ângulo do cone
	var direcao_lanterna = Vector2.RIGHT.rotated(lanterna.global_rotation)
	var direcao_para_inimigo = (global_position - lanterna.global_position).normalized()
	
	var angulo_entre = rad_to_deg(direcao_lanterna.angle_to(direcao_para_inimigo))
	
	# Se o ângulo for menor que o cone, ele está na luz!
	if abs(angulo_entre) <= flashlight_cone_angle:
		return true
		
	return false
# -------------------------------------------------


func _check_blink(t: float) -> void:
	var cycle = fmod(t, _full_cycle)

	# Detecta se está no burst
	_is_in_burst = cycle < _burst_duration

	# Fora do burst → reseta
	if not _is_in_burst:
		_blinked_this_burst = false
		return

	# Calcula openness
	var local    = fmod(cycle, shader_blink_speed) / shader_blink_speed
	var openness : float
	if local < shader_close_ratio:
		openness = 1.0 - _smoothstep(0.0, shader_close_ratio, local)
	else:
		openness = _smoothstep(shader_close_ratio, 1.0, local)

	# Teleporta quando olho fecha (openness < 0.08) E pode teleportar
	if openness < 0.08 and not _blinked_this_burst and _can_teleport:
		_blinked_this_burst = true
		_teleport_toward_player()


func _teleport_toward_player() -> void:
	_can_teleport = false  # ⭐ Bloqueia teleportes

	var old_pos  = global_position
	var dist_now = global_position.distance_to(player.global_position)

	var jump = minf(_current_jump, dist_now)
	var dir  = (player.global_position - global_position).normalized()
	global_position += dir * jump
	_current_jump   += teleport_jump_grow

	print("👁 Teleporte! %.0fpx | Falta: %.0fpx" % [
		jump,
		global_position.distance_to(player.global_position)
	])

	if audio and audio.stream:
		audio.pitch_scale = randf_range(0.85, 1.15)
		audio.play()

	_spawn_ghost_at(old_pos)
	_flash_sprite()

	# ⭐ Reseta cooldown após delay
	await get_tree().create_timer(teleport_delay).timeout
	_can_teleport = true


func _flash_sprite() -> void:
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1.8, 1.8, 1.8, 1.0), 0.03)
	tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)


func _spawn_ghost_at(pos: Vector2) -> void:
	var ghost             = sprite.duplicate() as Sprite2D
	ghost.material        = null
	ghost.modulate        = Color(1.0, 1.0, 1.0, 0.5)
	ghost.global_position = pos
	get_parent().add_child(ghost)
	var tween = create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.5)
	tween.tween_callback(ghost.queue_free)


func _on_reach_player() -> void:
	_is_attacking = true
	print("💀 Chegou perto! ATACANDO!")
	# Remove a ameaça de sanidade durante o ataque/teleporte
	GameManager.remover_ameaca("boneca")
	# ==========================================
	# ⭐ AQUI ESTÁ A IMPLEMENTAÇÃO DO DANO ⭐
	# Verificamos se o player tem a função de tomar dano e aplicamos 1 de hit!
	if player.has_method("levar_dano"):
		player.levar_dano(1)
	# ==========================================
	# ⭐ Fade in rápido
	var tween = create_tween()
	tween.tween_property(_fade_rect, "color", Color(0, 0, 0, 0.8), 0.15)
	await tween.finished

	# Teleporta pra trás do jogador com distância aleatória
	var angle = randf() * TAU
	var teleport_dist = 200.0
	global_position = player.global_position + Vector2.from_angle(angle) * teleport_dist
	
	# Som
	if audio and audio.stream:
		audio.pitch_scale = randf_range(0.7, 0.9)
		audio.play()

	# Fade out
	tween = create_tween()
	tween.tween_property(_fade_rect, "color", Color(0, 0, 0, 0), 0.3)
	await tween.finished

	# Reseta pra perseguição normal
	_current_jump = teleport_jump
	_can_teleport = true
	_is_attacking = false  # ESSENCIAL: sem isso a boneca trava para sempre após o 1º ataque


func _smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t = clampf((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


# Sinais da collision shape de proximidade desativados —
# o range agora é controlado por 'range_sanidade' no Inspector.
func _on_collision_shape_2d_2_body_entered(_body: Node2D) -> void:
	pass

func _on_collision_shape_2d_2_body_exited(_body: Node2D) -> void:
	pass
