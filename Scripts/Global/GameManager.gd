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
const SAVE_PATH := "user://narciso_save.cfg"

var checkpoint_cena_path: String = ""          # Guarda o caminho da cena (.tscn)
var checkpoint_posicao: Vector2 = Vector2.ZERO     # Guarda a posição global (X, Y)
var tem_checkpoint: bool = false                # Flag se o player ativou algum checkpoint

# IDs dos checkpoints que já foram ativados — garante que cada um salve só UMA vez
var checkpoints_ativados: Array[String] = []

# Fica true só durante o renascimento, para o reposicionamento não atrapalhar
# transições normais (portas) que voltam para a cena do checkpoint.
var _respawn_pendente: bool = false

## Autosave: chamado pelo nó Checkpoint quando o player encosta nele.
## Cada checkpoint (identificado por 'id') salva apenas uma vez.
func salvar_checkpoint(id: String, cena_path: String, posicao_global: Vector2) -> void:
	if id in checkpoints_ativados:
		return # Esse checkpoint já foi ativado antes — não salva de novo
	checkpoints_ativados.append(id)
	checkpoint_cena_path = cena_path
	checkpoint_posicao = posicao_global
	tem_checkpoint = true
	_salvar_em_disco()
	print("💾 Checkpoint salvo: ", id)

## Renasce no último checkpoint (chamado pela tela de Game Over).
func respawnar_no_checkpoint() -> void:
	_respawn_pendente = true
	change_scene_with_fade(checkpoint_cena_path)

## Zera o progresso salvo — use ao começar um Novo Jogo.
func iniciar_novo_jogo() -> void:
	checkpoint_cena_path = ""
	checkpoint_posicao = Vector2.ZERO
	tem_checkpoint = false
	checkpoints_ativados.clear()
	torres_finalizadas.clear()
	_apagar_disco()

# --- PERSISTÊNCIA EM DISCO ---
func _salvar_em_disco() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("checkpoint", "cena_path", checkpoint_cena_path)
	cfg.set_value("checkpoint", "posicao", checkpoint_posicao)
	cfg.set_value("checkpoint", "tem_checkpoint", tem_checkpoint)
	cfg.set_value("checkpoint", "ativados", checkpoints_ativados)
	cfg.set_value("progresso", "torres_finalizadas", torres_finalizadas)
	var err := cfg.save(SAVE_PATH)
	if err != OK:
		printerr("[Save] Falha ao gravar o save: ", err)

func _carregar_do_disco() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return # Sem save ainda — começa do zero
	checkpoint_cena_path = cfg.get_value("checkpoint", "cena_path", "")
	checkpoint_posicao = cfg.get_value("checkpoint", "posicao", Vector2.ZERO)
	tem_checkpoint = cfg.get_value("checkpoint", "tem_checkpoint", false)
	checkpoints_ativados.assign(cfg.get_value("checkpoint", "ativados", []))
	torres_finalizadas.assign(cfg.get_value("progresso", "torres_finalizadas", []))
	print("💾 Save carregado (checkpoint: ", tem_checkpoint, ")")

func _apagar_disco() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

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

	# Carrega o save do disco (se existir) para já saber se há checkpoint
	_carregar_do_disco()

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
	# Só reposiciona quando for um RENASCIMENTO (não em transições normais de porta).
	if _respawn_pendente:
		_respawn_pendente = false
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
