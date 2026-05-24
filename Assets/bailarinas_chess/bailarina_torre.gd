extends Node2D

@export var grid_cell_size: int = 32
@export var movement_speed: float = 100.0
@export var board_origin: Vector2 = Vector2.ZERO

@onready var sprite = $AnimatedSprite2D
@onready var detector = $CollisionDetector

var grid_pos: Vector2i = Vector2i.ZERO
var player_grid_pos: Vector2i = Vector2i.ZERO
var straight_directions = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]

func _ready():
	add_to_group("bailarina")
	grid_pos = world_to_grid(global_position)
	global_position = grid_to_world(grid_pos)
	GameManager.registrar_posicao_peca(get_instance_id(), grid_pos)

func execute_turn():
	var player = get_tree().get_first_node_in_group("player")
	if player: player_grid_pos = player.pos_grid_do_player
	var next_pos = calculate_move()
	if next_pos != grid_pos: await move_to(next_pos)
	else: await get_tree().create_timer(0.1).timeout

func calculate_move() -> Vector2i:
	var valid_moves = []
	for dir in straight_directions:
		for i in range(1, 8):
			var target = grid_pos + (dir * i)
			if not is_valid_pos(target) or not GameManager.casa_esta_livre(target, get_instance_id()): break
			valid_moves.append(target)
	if valid_moves.is_empty(): return grid_pos
	var best_move = valid_moves[0]
	var closest_dist = Vector2(grid_pos).distance_to(Vector2(player_grid_pos))
	for m in valid_moves:
		var dist = Vector2(m).distance_to(Vector2(player_grid_pos))
		if dist < closest_dist:
			closest_dist = dist
			best_move = m
	return best_move

func move_to(new_pos: Vector2i):
	GameManager.remover_posicao_peca(grid_pos)
	grid_pos = new_pos
	GameManager.registrar_posicao_peca(get_instance_id(), grid_pos)
	var target_world = grid_to_world(new_pos)
	if sprite: sprite.play("walk")
	var tween = create_tween()
	tween.tween_property(self, "global_position", target_world, global_position.distance_to(target_world) / movement_speed).set_trans(Tween.TRANS_SINE)
	await tween.finished
	if sprite: sprite.play("idle")
	check_collisions()

func world_to_grid(world_pos: Vector2) -> Vector2i:
	var rel = world_pos - board_origin
	return Vector2i(int(rel.x / grid_cell_size), int(rel.y / grid_cell_size))

func grid_to_world(pos: Vector2i) -> Vector2:
	return board_origin + Vector2(pos.x * grid_cell_size + grid_cell_size / 2.0, pos.y * grid_cell_size + grid_cell_size / 2.0)

func is_valid_pos(pos: Vector2i) -> bool: return pos.x >= 0 and pos.x <= 7 and pos.y >= 0 and pos.y <= 7
func check_collisions():
	for body in detector.get_overlapping_bodies():
		if body.is_in_group("player"):
			body.call("morrer_instantaneamente", "Pisou na Torre!")
			return

func _on_collision_detector_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.morrer_instantaneamente("Pisou na Torre!")

func _on_collision_detector_area_entered(area: Area2D) -> void:
	var owner_node = area if area.is_in_group("player") else area.get_parent()
	if owner_node.is_in_group("player"):
		owner_node.morrer_instantaneamente("Pisou na Torre!")
