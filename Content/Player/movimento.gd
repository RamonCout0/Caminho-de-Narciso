extends CharacterBody2D

# --- NÓS E RECURSOS ---
@onready var animated_sprite = $AnimatedSprite2D
@onready var footstep_sound = $FootstepSound
@onready var lanterna = $Lanterna
@onready var som_lanterna = $SomLanterna
@onready var som_dano = $SomDano
@onready var som_cura = $SomCura
@onready var pivot_escudo = $pivot_escudo

# --- CONFIGURAÇÕES ---
@export var max_speed: int = 150
@export var acceleration: int = 1500
@export var friction: int = 1200

var current_direction = "down"
var has_shield: bool = false

func _ready():
	# Garante que a lanterna comece ligada
	if lanterna:
			lanterna.enabled = true

func _physics_process(delta):
	
	if not pode_se_mover:
		velocity = Vector2.ZERO # Para o boneco imediatamente
		move_and_slide()        # Aplica a parada
		return

	# ... aqui continua o seu código normal de movimento ...
	# --- TRAVA DE DIÁLOGO ---
	var ui_dialogo = get_tree().current_scene.find_child("DialogueBox", true, false)
	if ui_dialogo and ui_dialogo.visible:
		velocity = Vector2.ZERO
		move_and_slide()
		footstep_sound.stop()
		handle_animations(Vector2.ZERO)
		return
	# ------------------------

	# --- TRAVA DO XADREZ ---
	if in_chess_mode:
		_process_chess_input()
		return
	# ------------------------

	# MOVIMENTAÇÃO LIVRE NORMAL
	var input_direction = Input.get_vector("mv_left", "mv_right", "mv_up", "mv_down")
	var target_velocity = input_direction * max_speed
	
	if input_direction.length() > 0:
		velocity = velocity.move_toward(target_velocity, acceleration * delta)
		if !footstep_sound.playing:
			footstep_sound.pitch_scale = randf_range(0.8, 1.2)
			footstep_sound.play()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		footstep_sound.stop()
	
	move_and_slide()
	handle_animations(input_direction)
	
	# Checagem de colisão física (move_and_slide)
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var objeto = collision.get_collider()
		
		# Se encostar em algo que está no grupo das bailarinas
		if objeto.is_in_group("bailarina"):
			morrer_instantaneamente("Atropelado por uma bailarina!")


func _process(_delta):
	if lanterna:
		lanterna.look_at(get_global_mouse_position())
		if Input.is_action_just_pressed("toggle_lanterna"):
			lanterna.enabled = !lanterna.enabled
			som_lanterna.play()
			
	if Input.is_action_just_pressed("interagir"):
		if has_node("Area_Coleta"):
			var areas = $Area_Coleta.get_overlapping_areas()
			for area in areas:
				if area.is_in_group("pickup_shield"):
					has_shield = true
					area.queue_free()
					break
					
	if pivot_escudo:
		if has_shield:
			pivot_escudo.visible = true
			pivot_escudo.look_at(get_global_mouse_position())
		else:
			pivot_escudo.visible = false

func handle_animations(input_direction: Vector2):
	if input_direction.length() > 0:
		if abs(input_direction.x) > abs(input_direction.y):
			current_direction = "side"
			animated_sprite.play("walk_side")
			animated_sprite.flip_h = (input_direction.x > 0)
		else:
			if input_direction.y > 0:
				current_direction = "down"
				animated_sprite.play("walk_down")
			else:
				current_direction = "up"
				animated_sprite.play("walk_up")
			animated_sprite.flip_h = false
	else:
		match current_direction:
			"down": animated_sprite.play("idle_down")
			"up": animated_sprite.play("idle_up")
			"side": animated_sprite.play("idle_side")

# ==========================================
#        SISTEMA DE COMBATE / STATUS
# ==========================================

func levar_dano(quantidade: int):
	GameManager.take_damage(quantidade)
	if som_dano:
		som_dano.pitch_scale = randf_range(0.9, 1.1)
		som_dano.play()
	
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color.RED, 0.1)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)

func receber_cura(quantidade: int):
	if som_cura:
		som_cura.pitch_scale = randf_range(1.0, 1.2)
		som_cura.play()
	GameManager.heal(quantidade)
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color.GREEN, 0.1)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)

func take_damage():
	levar_dano(1)

func consume_shield() -> void:
	has_shield = false
	if pivot_escudo:
		pivot_escudo.visible = false
	var tween = create_tween()
	tween.tween_property(animated_sprite, "modulate", Color(0.3, 0.8, 2.0), 0.06)
	tween.tween_property(animated_sprite, "modulate", Color.WHITE, 0.15)


# ==========================================
#        SISTEMA DE XADREZ (NOVO)
# ==========================================

func iniciar_modo_xadrez(manager_node: Node, inicio_grid_x: int, inicio_grid_y: int):
	in_chess_mode = true
	xadrez_manager = manager_node
	
	if not xadrez_manager.player_turn_started.is_connected(iniciar_turno_jogador):
		xadrez_manager.player_turn_started.connect(iniciar_turno_jogador)
	
	pos_grid_do_player = Vector2i(inicio_grid_x, inicio_grid_y)
	global_position = Vector2(pos_grid_do_player.x * grid_size + (grid_size / 2.0), pos_grid_do_player.y * grid_size + (grid_size / 2.0))
	velocity = Vector2.ZERO
	handle_animations(Vector2.ZERO)

func iniciar_turno_jogador():
	print("📢 Turno do player! Você tem 2 movimentos.")
	movimentos_restantes = 1
	is_my_turn_in_chess = true

func _process_chess_input():
	if not is_my_turn_in_chess:
		return

	var direcao_movimento = Vector2i.ZERO
	
	if Input.is_action_just_pressed("mv_right"): direcao_movimento = Vector2i.RIGHT
	elif Input.is_action_just_pressed("mv_left"): direcao_movimento = Vector2i.LEFT
	elif Input.is_action_just_pressed("mv_up"): direcao_movimento = Vector2i.UP
	elif Input.is_action_just_pressed("mv_down"): direcao_movimento = Vector2i.DOWN

	if direcao_movimento != Vector2i.ZERO:
		tentar_mover_jogador(pos_grid_do_player + direcao_movimento)

func tentar_mover_jogador(nova_pos_grid: Vector2i):
	var diff_x = abs(nova_pos_grid.x - pos_grid_do_player.x)
	var diff_y = abs(nova_pos_grid.y - pos_grid_do_player.y)

	# REGRAS: Aceita reta ou diagonal (1 quadrado)
	var eh_diagonal = (diff_x == diff_y)
	var eh_reta = (diff_x == 0 or diff_y == 0)
	var moveu_um_quadrado = (diff_x <= 1 and diff_y <= 1)

	# Regra do tabuleiro 8x8 (0 a 7)
	var fora_dos_limites = nova_pos_grid.x < 0 or nova_pos_grid.x > 7 or nova_pos_grid.y < 0 or nova_pos_grid.y > 7

	# --- AJUSTE AQUI ---
	# Se estiver fora do grid, a gente só cancela o movimento em vez de matar!
	if fora_dos_limites:
		print("Opa, parede! Não pode sair do grid.")
		return # Sai da função sem tirar HP e sem gastar o turno

	# Se for um movimento maluco (tipo pular 3 casas), a gente também só ignora
	if (not eh_reta and not eh_diagonal) or not moveu_um_quadrado:
		return

	# O ÚNICO jeito de morrer agora é o cheque-mate (pisar na bailarina)
	if esta_em_cheque(nova_pos_grid):
		morrer_instantaneamente("Cheque-Mate!")
		return

	# Se tudo der certo, executa o movimento
	is_my_turn_in_chess = false 
	pos_grid_do_player = nova_pos_grid
	animar_movimento_xadrez(nova_pos_grid)

func animar_movimento_xadrez(nova_pos_grid: Vector2i):
	var nova_pos_visual = Vector2(nova_pos_grid.x * grid_size + (grid_size / 2.0), nova_pos_grid.y * grid_size + (grid_size / 2.0))
	
	handle_animations((nova_pos_visual - global_position).normalized())
	
	var tween = create_tween()
	tween.tween_property(self, "global_position", nova_pos_visual, 0.2).set_trans(Tween.TRANS_SINE)
	
	await tween.finished
	handle_animations(Vector2.ZERO)

	# --- VERIFICAÇÃO DE VITÓRIA (LINHA DE CHEGADA) ---
	# Se a posição Y for 0, significa que você chegou na última linha!
	if nova_pos_grid.y <= 0:
		vencer_xadrez()
		return # Sai da função para não gastar movimentos ou passar o turno
	# ------------------------------------------------

	movimentos_restantes -= 1
	
	if movimentos_restantes > 0:
		is_my_turn_in_chess = true 
	else:
		if xadrez_manager and xadrez_manager.has_method("player_finished_move"):
			xadrez_manager.player_finished_move()

# Função para limpar o estado de jogo e te libertar
func vencer_xadrez():
	print("🏆 Você escapou do xadrez!")
	in_chess_mode = false
	is_my_turn_in_chess = false
	
	# Chama o manager para fazer o fade-out da música
	if xadrez_manager and xadrez_manager.has_method("finalizar_encontro"):
		xadrez_manager.finalizar_encontro()
	
	GameManager.casas_ocupadas.clear()
	
	# Avisa o manager que o encontro acabou (opcional)
	if xadrez_manager:
		xadrez_manager.is_encounter_active = false
func morrer_instantaneamente(motivo: String):
	print(motivo)
	GameManager.take_damage(GameManager.max_hp)

func esta_em_cheque(pos_grid_alvo: Vector2i) -> bool:
	var pos_alvo_pixel = Vector2(pos_grid_alvo.x * grid_size + (grid_size / 2.0), pos_grid_alvo.y * grid_size + (grid_size / 2.0))
	var espaco = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = pos_alvo_pixel
	
	# MASCARA 2: Significa que ele SÓ vai detectar o que estiver no Layer 2 (Bailarinas)
	# Assim ele ignora a parede (Layer 1) e não te mata à toa.
	query.collision_mask = 2 
	query.collide_with_areas = true
	
	var resultado = espaco.intersect_point(query)
	return resultado.size() > 0
