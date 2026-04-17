extends CharacterBody2D

# --- NÓS ---
@onready var anim = $AnimatedSprite2D
@onready var musica = $MusicaCaixinha
@onready var luz_palco = $LuzPalco
@onready var lente_distorcao = $DistorcaoPalco

# --- CONFIGURAÇÕES ---
@export var player : CharacterBody2D
@export var move_speed : float = 40.0      # Velocidade dela deslizando até você
@export var detection_range : float = 600.0
@export var attack_range : float = 40.0    # Se ela encostar em você, game over

# --- AJUSTES DE TEMPO ---
@export var tempo_de_reacao : float = 0.4  # Tempo para o jogador parar e apagar a luz
@export var tempo_min_idle : float = 4.0   # Tempo no escuro (PARADA)
@export var tempo_max_idle : float = 7.0   
@export var tempo_min_dance : float = 5.0  # Tempo da música tocando (MAIOR AGORA)
@export var tempo_max_dance : float = 8.0  

# --- ESTADOS INTERNOS ---
var is_dancing : bool = false
var state_timer : float = 0.0
var reaction_counter : float = 0.0
var has_attacked : bool = false

func _ready():
	luz_palco.enabled = false
	lente_distorcao.visible = false
	anim.play("idle")
	state_timer = randf_range(tempo_min_idle, tempo_max_idle)

func _physics_process(delta):
	if not player or has_attacked:
		return

	var dist_to_player = global_position.distance_to(player.global_position)
	
	if dist_to_player > detection_range:
		_force_idle()
		return

	state_timer -= delta
	if state_timer <= 0:
		_trocar_estado()

	if is_dancing:
		# --- LUZ ACESA: ELA SE MOVE E TE VIGIA ---
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * move_speed
		
		# Se ela chegar muito perto enquanto você está paralisado, ela ataca!
		if dist_to_player <= attack_range:
			_atacar_jogador()
			
		_vigiar_jogador(delta)
	else:
		# --- ESCURO: ELA FICA TOTALMENTE PARADA ---
		velocity = Vector2.ZERO
		reaction_counter = 0 # Reseta a reação do jogador
	
	move_and_slide()

func _trocar_estado():
	is_dancing = !is_dancing
	reaction_counter = 0
	
	if is_dancing:
		anim.play("dance")
		luz_palco.enabled = true
		lente_distorcao.visible = true
		musica.play()
		state_timer = randf_range(tempo_min_dance, tempo_max_dance)
	else:
		anim.play("idle")
		luz_palco.enabled = false
		lente_distorcao.visible = false
		musica.stop()
		state_timer = randf_range(tempo_min_idle, tempo_max_idle)

func _vigiar_jogador(delta):
	var detectou_erro = false
	
	if player.velocity.length() > 20.0 or player.lanterna.enabled:
		detectou_erro = true
	
	if detectou_erro:
		reaction_counter += delta
		if reaction_counter >= tempo_de_reacao:
			_atacar_jogador()
	else:
		reaction_counter = max(0, reaction_counter - delta)

func _atacar_jogador():
	has_attacked = true
	player.levar_dano(5)
	musica.stop()
	luz_palco.enabled = false 
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", player.global_position, 0.1)
	
	print("💀 PEGOU! (Você se moveu, piscou a luz ou ela te alcançou)")

func _force_idle():
	if is_dancing:
		is_dancing = false
		anim.play("idle")
		luz_palco.enabled = false
		musica.stop()
		velocity = Vector2.ZERO
