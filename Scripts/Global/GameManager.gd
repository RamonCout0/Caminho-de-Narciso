extends Node

# --- REFERÊNCIAS PARA TRANSIÇÃO ---
# Certifique-se que esses nós existam dentro do seu GameManager na cena (CanvasLayer)
@onready var color_rect: ColorRect = $TransitionScreen/ColorRect
@onready var anim_player: AnimationPlayer = $TransitionScreen/AnimationPlayer

# Onde o jogador deve nascer na próxima tela
var target_spawn_point: String = ""

# --- ILUMINAÇÃO ---
var cor_da_luz: Color = Color.WHITE

# ==========================================
#         💾 SISTEMA DE PERSISTÊNCIA
# ==========================================
# Guarda o ID único das torres que já completaram o caminho para não nascerem de novo
var torres_finalizadas: Array[String] = []

# ==========================================
#         💾 SISTEMA DE CHECKPOINT
# ==========================================
var checkpoint_cena_path: String = ""          # Guarda o caminho da cena (.tscn)
var checkpoint_posicao: Vector2 = Vector2.ZERO     # Guarda a posição global (X, Y)
var tem_checkpoint: bool = false                # Flag se o player ativou algum checkpoint

func salvar_checkpoint(cena_path: String, posicao_global: Vector2) -> void:
	checkpoint_cena_path = cena_path
	checkpoint_posicao = posicao_global
	tem_checkpoint = true
	print("💾 Checkpoint salvo com sucesso!")

func atualizar_luz_da_cena_atual():
	var cena_atual = get_tree().current_scene
	var luz = cena_atual.find_child("CanvasModulate", true, false)
	if luz:
		luz.color = cor_da_luz

# --- SISTEMA DE HP ---
signal hp_changed(new_hp)
signal player_died

var max_hp: int = 5
var current_hp: int = 5

func take_damage(amount: int):
	current_hp -= amount
	current_hp = clampi(current_hp, 0, max_hp)
	hp_changed.emit(current_hp)
	
	if current_hp <= 0:
		player_died.emit()
		print("jogador foi de vasco")
		# Limpa as ameaças ativas imediatamente
		_ameacas_ativas.clear()
		is_threatened = false

func heal(amount: int):
	current_hp += amount
	current_hp = clampi(current_hp, 0, max_hp)
	hp_changed.emit(current_hp)

# --- BOSS ---
signal boss_hp_changed(current_hp: int, max_hp: int)
signal boss_morreu()

func notificar_boss_hp(hp_atual: int, hp_maximo: int) -> void:
	boss_hp_changed.emit(hp_atual, hp_maximo)

func notificar_boss_morreu() -> void:
	boss_morreu.emit()

# --- SANIDADE ---
signal sanity_changed(new_value)
var max_sanity: float = 100.0
var current_sanity: float = 100.0
var _ameacas_ativas: Dictionary = {}
var is_threatened: bool = false

func registrar_ameaca(id: String, taxa_por_segundo: float) -> void:
	_ameacas_ativas[id] = taxa_por_segundo
	is_threatened = true

func remover_ameaca(id: String) -> void:
	_ameacas_ativas.erase(id)
	is_threatened = not _ameacas_ativas.is_empty()

func _update_sanity(amount: float) -> void:
	var old_val = current_sanity
	current_sanity = clamp(current_sanity + amount, 0.0, max_sanity)
	if old_val != current_sanity:
		sanity_changed.emit(current_sanity)

func tomar_remedio():
	current_sanity = 100.0
	sanity_changed.emit(current_sanity)

# --- XADREZ ---
var casas_ocupadas: Dictionary = {}

func registrar_posicao_peca(id: int, grid_pos: Vector2i):
	casas_ocupadas[grid_pos] = id

func remover_posicao_peca(grid_pos: Vector2i):
	casas_ocupadas.erase(grid_pos)

func casa_esta_livre(grid_pos: Vector2i, meu_id: int) -> bool:
	if not casas_ocupadas.has(grid_pos):
		return true
	return casas_ocupadas[grid_pos] == meu_id

# --- TRANSIÇÃO DE CENA ---
func _ready() -> void:
	if color_rect:
		color_rect.hide()
	
	# CONEXÃO DA MORTE: Faz o GameManager escutar a si mesmo quando o player morre
	player_died.connect(_on_player_died)

func change_scene_with_fade(target_path: String) -> void:
	if not color_rect or not anim_player:
		get_tree().change_scene_to_file(target_path)
		return

	color_rect.show()
	anim_player.play("fade_to_black")
	await anim_player.animation_finished
	
	var error = get_tree().change_scene_to_file(target_path)
	if error != OK:
		printerr("[ERRO] GameManager falhou ao carregar: ", target_path)
	
	# LÓGICA DE TELEPORTE DO CHECKPOINT:
	# Se a cena carregada for a do checkpoint ativo, coloca o Player na posição certa
	if tem_checkpoint and target_path == checkpoint_cena_path:
		await get_tree().process_frame
		await get_tree().process_frame # segundo frame garante que _ready() dos nós rodou
		var player = get_tree().current_scene.find_child("Player", true, false)
		if player:
			player.global_position = checkpoint_posicao
			if "velocity" in player:
				player.velocity = Vector2.ZERO
			print("[Checkpoint] Player reposicionado em ", checkpoint_posicao)
		else:
			push_warning("[Checkpoint] Nó 'Player' não encontrado na cena: ", target_path)

	anim_player.play_backwards("fade_to_black")
	await anim_player.animation_finished
	color_rect.hide()

# FUNÇÃO: Puxa a tela de GameOver com o efeito de Fade
func _on_player_died() -> void:
	# Trava o movimento do player durante o fade
	var player = get_tree().get_first_node_in_group("player")
	if player and "pode_se_mover" in player:
		player.pode_se_mover = false

	var tela_gameover_path = "res://UI/Gameover/gaver_over.tscn"
	change_scene_with_fade(tela_gameover_path)

# --- PROCESSAMENTO ---
func _process(delta: float) -> void:
	# Lógica de Sanidade (Drenagem vs Recuperação)
	var drenagem_total: float = 0.0
	for taxa in _ameacas_ativas.values():
		drenagem_total += taxa

	if drenagem_total > 0.0:
		_update_sanity(-drenagem_total * delta)
	else:
		_update_sanity(3.0 * delta) # Recupera passivamente quando seguro
