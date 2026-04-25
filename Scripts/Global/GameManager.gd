extends Node


# Armazena a cor global da iluminação
var cor_da_luz: Color = Color.WHITE

# Dentro do GameManager.gd
func atualizar_luz_da_cena_atual():
	# Pega a cena que está rodando agora
	var cena_atual = get_tree().current_scene
	var luz = cena_atual.find_child("CanvasModulate", true, false)
	
	if luz:
		luz.color = cor_da_luz
		

#Sistema de HP rsrs=========================
signal hp_changed(new_hp)
signal player_died

var max_hp: int = 5
var current_hp: int = 5

func take_damage(amount: int):
	current_hp -= amount
	current_hp = clampi(current_hp, 0, max_hp) #garante que ele não fique menor
	
	hp_changed.emit(current_hp)
	
	if current_hp <= 0:
		player_died.emit()
		print("jogador foi de vasco")

func heal(amount:int):
	current_hp += amount
	current_hp = clampi(current_hp,0, max_hp)
	hp_changed.emit(current_hp)
	

# ===================== BOSS =====================
# Emitido pelo Hatman quando toma dano ou morre.
# A HUD escuta para mostrar/atualizar a barra de HP do boss.
signal boss_hp_changed(current_hp: int, max_hp: int)
signal boss_morreu()

## Chame isso do Hatman ao tomar dano (evita warning de sinal não usado).
func notificar_boss_hp(hp_atual: int, hp_maximo: int) -> void:
	boss_hp_changed.emit(hp_atual, hp_maximo)

## Chame isso do Hatman ao morrer.
func notificar_boss_morreu() -> void:
	boss_morreu.emit()

#====================sistema de sanidade===============================
signal sanity_changed(new_value)

var max_sanity: float = 100.0
var current_sanity: float = 100.0

# --- Sistema de Multi-Ameaças ---
# Cada inimigo se registra com um ID único e sua taxa de drenagem de sanidade.
# Isso permite que vários inimigos drenem ao mesmo tempo com intensidades diferentes.
# Taxas de referência:
#   Boneca    →  8.0 / seg  (aparição súbita, pisca)
#   Ele Sabe  →  5.0 / seg  (perseguição direta)
#   Torre     → 12.0 / seg  (máquina imparável, muito opressiva)
#   Bailarina → 15.0 / seg  (a mais assustadora - dança + luz)
var _ameacas_ativas: Dictionary = {}

# Mantido para compatibilidade: reflete se há ALGUMA ameaça ativa.
var is_threatened: bool = false

## Registra (ou atualiza) uma ameaça de sanidade. Chame quando o inimigo ativa.
func registrar_ameaca(id: String, taxa_por_segundo: float) -> void:
	_ameacas_ativas[id] = taxa_por_segundo
	is_threatened = true

## Remove a ameaça de sanidade. Chame quando o inimigo desativa/morre/perde o player.
func remover_ameaca(id: String) -> void:
	_ameacas_ativas.erase(id)
	is_threatened = not _ameacas_ativas.is_empty()

func _process(delta: float) -> void:
	var drenagem_total: float = 0.0
	for taxa in _ameacas_ativas.values():
		drenagem_total += taxa

	if drenagem_total > 0.0:
		_update_sanity(-drenagem_total * delta)
	else:
		_update_sanity(3.0 * delta) # Recupera quando seguro

func _update_sanity(amount: float) -> void:
	var old_val = current_sanity
	current_sanity = clamp(current_sanity + amount, 0.0, max_sanity)
	
	if old_val != current_sanity:
		sanity_changed.emit(current_sanity)

func tomar_remedio():
	current_sanity = 100.0
	sanity_changed.emit(current_sanity)
