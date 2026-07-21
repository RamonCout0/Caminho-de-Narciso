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

# Fica true durante um fade de troca de cena, para impedir transições sobrepostas
var _em_transicao: bool = false

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
## Ao renascer o jogador volta sempre inteiro: vida e sanidade cheias, e os
## itens da sala reaparecem (a cena é recarregada do zero).
func respawnar_no_checkpoint() -> bool:
	# Save corrompido ou apagado: sem cena válida não há para onde renascer.
	# Sem esta checagem o jogo tentava carregar "" e ficava numa tela preta.
	if not tem_checkpoint or checkpoint_cena_path == "" \
			or not ResourceLoader.exists(checkpoint_cena_path):
		push_warning("[Checkpoint] Nenhum checkpoint válido para renascer.")
		return false

	reviver() # Vida e sanidade cheias antes de voltar ao mapa

	# Uma transição já em andamento faria o change_scene_with_fade abaixo ser
	# ignorado, deixando '_respawn_pendente' ligado e teleportando o jogador
	# para o checkpoint na PRÓXIMA porta que ele atravessasse.
	while _em_transicao:
		await get_tree().process_frame

	# Descarta qualquer spawn point pendente de uma porta anterior, senão o
	# _ready() do Player disputaria a posição com o checkpoint.
	target_spawn_point = ""

	_respawn_pendente = true
	change_scene_with_fade(checkpoint_cena_path)
	return true

## Zera o progresso salvo — use ao começar um Novo Jogo.
func iniciar_novo_jogo() -> void:
	checkpoint_cena_path = ""
	checkpoint_posicao = Vector2.ZERO
	tem_checkpoint = false
	checkpoints_ativados.clear()
	torres_finalizadas.clear()
	_apagar_disco()
	reviver() # Zera HP, sanidade e a flag de morte

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

# Trava de morte: sem ela, um segundo dano com o HP já em zero re-emitia
# 'player_died' e disparava duas transições para a tela de Game Over.
var esta_morto: bool = false

func take_damage(amount: int):
	if esta_morto:
		return

	current_hp -= amount
	current_hp = clampi(current_hp, 0, max_hp)
	hp_changed.emit(current_hp)

	if current_hp <= 0:
		esta_morto = true
		player_died.emit()
		print("jogador foi de vasco")
		# Limpa as ameaças ativas imediatamente
		_ameacas_ativas.clear()
		is_threatened = false

func heal(amount: int):
	if esta_morto:
		return

	current_hp += amount
	current_hp = clampi(current_hp, 0, max_hp)
	hp_changed.emit(current_hp)

## Restaura o jogador para um novo começo (usado pela tela de Game Over).
## Precisa zerar 'esta_morto', senão o player renasce incapaz de tomar dano.
func reviver() -> void:
	esta_morto     = false
	current_hp     = max_hp
	current_sanity = max_sanity
	_ameacas_ativas.clear()
	is_threatened  = false
	hp_changed.emit(current_hp)
	sanity_changed.emit(current_sanity)

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
	# Trava de reentrância: uma porta e um trigger disparando juntos (ou a morte
	# durante um fade) colocavam dois 'await' competindo pelo mesmo AnimationPlayer.
	if _em_transicao:
		push_warning("[GameManager] Transição já em andamento — ignorando: " + target_path)
		return
	_em_transicao = true

	if not color_rect or not anim_player:
		get_tree().change_scene_to_file(target_path)
		_em_transicao = false
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
		# Busca pelo GRUPO, e não pelo nome do nó: o resto do projeto todo usa
		# is_in_group("player"), então renomear o nó não quebra mais o respawn.
		var player = get_tree().get_first_node_in_group("player")
		if player:
			player.global_position = checkpoint_posicao
			if "velocity" in player:
				player.velocity = Vector2.ZERO
			print("[Checkpoint] Player reposicionado em ", checkpoint_posicao)
		else:
			push_warning("[Checkpoint] Nenhum nó no grupo 'player' na cena: " + target_path)

	anim_player.play_backwards("fade_to_black")
	await anim_player.animation_finished
	color_rect.hide()
	_em_transicao = false

# FUNÇÃO: Puxa a tela de GameOver com o efeito de Fade
func _on_player_died() -> void:
	# Trava o movimento do player durante o fade
	var player = get_tree().get_first_node_in_group("player")
	if player and "pode_se_mover" in player:
		player.pode_se_mover = false

	# A morte tem prioridade, mas não pode atropelar um fade em andamento:
	# sem esta espera, morrer durante a transição de uma porta fazia a tela de
	# Game Over ser descartada pela trava e o jogador ficava travado para sempre.
	while _em_transicao:
		await get_tree().process_frame

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
