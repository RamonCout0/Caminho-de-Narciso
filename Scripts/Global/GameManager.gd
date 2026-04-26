extends Node

# --- ILUMINAÇÃO ---
var cor_da_luz: Color = Color.WHITE

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

# ==========================================
#        SISTEMA DE XADREZ (RECUPERADO)
# ==========================================

# Dicionário para guardar as posições ocupadas: {Vector2i: NodeID}
var casas_ocupadas: Dictionary = {}

func registrar_posicao_peca(id: int, grid_pos: Vector2i):
	casas_ocupadas[grid_pos] = id

func remover_posicao_peca(grid_pos: Vector2i):
	casas_ocupadas.erase(grid_pos)

func casa_esta_livre(grid_pos: Vector2i, meu_id: int) -> bool:
	if not casas_ocupadas.has(grid_pos):
		return true
	return casas_ocupadas[grid_pos] == meu_id

# ------------------------------------------

func _process(delta: float) -> void:
	# Processamento de Sanidade
	var drenagem_total: float = 0.0
	for taxa in _ameacas_ativas.values():
		drenagem_total += taxa

	if drenagem_total > 0.0:
		_update_sanity(-drenagem_total * delta)
	else:
<<<<<<< HEAD
		_update_sanity(3.0 * delta)
=======
		_update_sanity(3.0 * delta) # Recupera quando seguro

func _update_sanity(amount: float) -> void:
	var old_val = current_sanity
	current_sanity = clamp(current_sanity + amount, 0.0, max_sanity)
	
	if old_val != current_sanity:
		sanity_changed.emit(current_sanity)

func tomar_remedio():
	current_sanity = 100.0
	sanity_changed.emit(current_sanity)
	
	
	
	
	# Referências para o sistema de transição (ajuste os caminhos se precisar)
@onready var color_rect: ColorRect = $TransitionScreen/ColorRect
@onready var anim_player: AnimationPlayer = $TransitionScreen/AnimationPlayer

# Essa variável vai guardar o nome de onde o jogador deve nascer na próxima tela
var target_spawn_point: String = ""

func _ready() -> void:
	# Garante que a tela preta comece desligada
	if color_rect:
		color_rect.hide()

# Adicione esta função ao seu GameManager
func change_scene_with_fade(target_path: String) -> void:
	color_rect.show()
	
	# 1. Fade Out
	anim_player.play("fade_to_black")
	await anim_player.animation_finished
	
	# 2. Troca a Cena
	var error = get_tree().change_scene_to_file(target_path)
	if error != OK:
		printerr("[ERRO] GameManager falhou ao carregar: ", target_path)
	
	# 3. Fade In
	anim_player.play_backwards("fade_to_black")
	await anim_player.animation_finished
	
	color_rect.hide()
>>>>>>> b7df3e07ec67bf18ccf74a4a6f2a4eae20a2fe57
