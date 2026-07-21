extends Area2D
class_name GatilhoDialogo

# ================================================================
# GATILHO DE DIÁLOGO (Dialogic)
# Substitui o antigo dialogo.gd / dialogo1.gd.
#
# Como usar:
#   1. Instancie 'gatilho_dialogo.tscn' na sala e ajuste o CollisionShape2D.
#   2. No Inspector, arraste a timeline (.dtl) para o campo 'Timeline'.
#   3. Escolha o modo: AO_ENTRAR (automático) ou INTERAGIR (tecla E).
# ================================================================

enum Modo {
	AO_ENTRAR, ## Dispara sozinho assim que o player encosta na área
	INTERAGIR, ## Espera o player apertar a tecla de interagir dentro da área
}

@export_group("Diálogo")
## A timeline (.dtl) que será tocada. Sem isso o gatilho não faz nada.
@export var timeline: DialogicTimeline
@export var modo: Modo = Modo.AO_ENTRAR
## Se ligado, esta conversa acontece só uma vez por partida.
@export var apenas_uma_vez: bool = true

@export_group("Comportamento")
## Congela o player enquanto a caixa de diálogo estiver na tela.
@export var travar_player: bool = true

var _player_perto: Node2D = null
var _ja_disparou: bool = false
var _em_dialogo: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if modo != Modo.INTERAGIR or _em_dialogo or _player_perto == null:
		return
	if event.is_action_pressed("interagir"):
		iniciar()
		# Impede que o mesmo 'E' também seja lido como coleta de item pelo player
		get_viewport().set_input_as_handled()

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	_player_perto = body
	if modo == Modo.AO_ENTRAR:
		iniciar()

func _on_body_exited(body: Node2D) -> void:
	if body == _player_perto:
		_player_perto = null

## Dispara a timeline. Pode ser chamada de fora (por um cutscene, botão etc).
func iniciar() -> void:
	if _em_dialogo:
		return
	if apenas_uma_vez and _ja_disparou:
		return
	if timeline == null:
		push_warning("[GatilhoDialogo] Nenhuma timeline definida em '%s'." % name)
		return

	_ja_disparou = true
	_em_dialogo = true
	_travar(true)

	# CONNECT_ONE_SHOT: a conexão se desfaz sozinha ao terminar, evitando que
	# um gatilho antigo continue reagindo a diálogos de outros gatilhos.
	Dialogic.timeline_ended.connect(_ao_terminar, CONNECT_ONE_SHOT)
	Dialogic.start(timeline)

func _ao_terminar() -> void:
	_em_dialogo = false
	_travar(false)

## Busca o player pelo GRUPO (e não por referência guardada): se ele morreu ou
## trocou de cena no meio da conversa, não corremos o risco de destravar um nó
## que não existe mais — nem de deixar o player congelado para sempre.
func _travar(travado: bool) -> void:
	if not travar_player:
		return
	var p := get_tree().get_first_node_in_group("player")
	if p and "pode_se_mover" in p:
		p.pode_se_mover = not travado
