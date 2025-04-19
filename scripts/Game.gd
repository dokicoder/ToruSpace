class_name GameManager extends Node3D

@export var camera: Node
const MOVE_STEP: float = 200.0

const CellNode: PackedScene = preload("res://scenes/CellNode3D.tscn")

const STEP = 0.1

var board: BoardData

var delta_acc: float = 0.0

func _deploy_mines():
	const mine_ratio: float = 0.09
	var num_mines = int(Config.WIDTH * Config.HEIGHT * mine_ratio)

	board.deploy_random_mines(num_mines)

func _ready() -> void:
	board = BoardData.new()
	board.init(Config.WIDTH, Config.HEIGHT)
	_deploy_mines()

	_generate_sprite_board()

func _reset():
	for cell in board.cells:
		cell.node.queue_free()
		cell.node = null

	board.reset()
	_deploy_mines()

	_generate_sprite_board()

func handle_node_click(event: InputEvent, cell: CellData):
	if event is InputEventMouseButton:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					if event.pressed:
						print("%d / %d" % [cell.x, cell.y])
						if not board.make_move(cell, BoardData.MoveType.UNMASK_FIELD):
							_reset()
				MOUSE_BUTTON_RIGHT:
					if event.pressed:
						board.make_move(cell, BoardData.MoveType.RESET_MASK)

func _generate_sprite_board():
	print("generate")

	for cell in board.cells:
		var node = CellNode.instantiate()
		node.mesh = node.mesh.duplicate()
		node.material_override = node.material_override.duplicate()
		#node.mesh.surface_set_material(0, material.duplicate())

		#node.texture = node.texture.duplicate()

		# link up visual and data
		node.data = cell
		cell.node = node
		
		node.rotation.x = PI * 0.5
		
		node.update_mesh()
		node.update_texture()

		#node.position.x = (cell.x - 0.5 * Config.WIDTH) * 0.5
		#node.position.y = (cell.y - 0.5 * Config.HEIGHT) * 0.5

		#node.scale.x = 100
		#node.scale.y = 100
		#node.scale.z = 100
		
		

		#node.activated.connect(handle_node_click)

		add_child(node)
	
func _input(event):
	if event.is_action_pressed("Left"):
		camera.position.x -= MOVE_STEP
	if event.is_action_pressed("Right"):
		camera.position.x += MOVE_STEP
	if event.is_action_pressed("Up"):
		camera.position.y -= MOVE_STEP
	if event.is_action_pressed("Down"):
		camera.position.y += MOVE_STEP

func _process(delta: float) -> void:
	rotation.y += 0.3 * delta
	
	delta_acc += delta
	if(delta_acc > STEP):
		delta_acc -= STEP
		if board.flood_step():
			# TODO: this is still very inefficient - all mines are checked even	though nothing changed in the vicinity of most of them
			board.mark_cleared_mines()
	
