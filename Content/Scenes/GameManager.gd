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
	

#====================sistema de sanidade===============================
signal sanity_changed(new_value)

var max_sanity: float = 100.0
var current_sanity: float = 100.0
var is_threatened: bool = false # Ligado pela Boneca

func _process(delta: float) -> void:
	if is_threatened:
		_update_sanity(-8.0 * delta) # Cai 8 por seg
	else:
		_update_sanity(3.0 * delta) # Recupera 3 por seg

func _update_sanity(amount: float) -> void:
	var old_val = current_sanity
	current_sanity = clamp(current_sanity + amount, 0.0, max_sanity)
	
	if old_val != current_sanity:
		sanity_changed.emit(current_sanity)

func tomar_remedio():
	current_sanity = 100.0
	sanity_changed.emit(current_sanity)
