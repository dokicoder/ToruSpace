class_name GameManager extends Node

@export var camera: Node
const MOVE_STEP: float = 200.0

const CellNode: PackedScene = preload("res://scenes/CellNode.tscn")

const STEP = 0.1

var board: BoardData

var delta_acc: float = 0.0

func _ready() -> void:
	board = BoardData.new()

	board.init(Config.WIDTH, Config.HEIGHT)

	const mine_ratio: float = 0.09
	var num_mines = int(Config.WIDTH * Config.HEIGHT * mine_ratio)

	board.deploy_random_mines(num_mines)

	_generate_sprite_board()

func handle_node_click(event: InputEvent, cell: CellData):
	if event is InputEventMouseButton:
			match event.button_index:
				MOUSE_BUTTON_LEFT:
					if event.pressed:
						print("%d / %d" % [cell.x, cell.y])
						if not board.make_move(cell, BoardData.MoveType.UNMASK_FIELD):
							board.reset()
				MOUSE_BUTTON_RIGHT:
					if event.pressed:
						board.make_move(cell, BoardData.MoveType.RESET_MASK)

func _generate_sprite_board():
	print("generate")

	for cell in board.cells:
		var node = CellNode.instantiate() as CellNode
		node.texture = node.texture.duplicate()

		# link up visual and data
		node.data = cell
		cell.node = node
		node.update_transform()
		node.update_texture()

		node.activated.connect(handle_node_click)

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
	delta_acc += delta
	if(delta_acc > STEP):
		delta_acc -= STEP
		if board.flood_step():
			# TODO: this is still very inefficient - all mines are checked even	though nothing changed in the vicinity of most of them
			board.mark_cleared_mines()
	
