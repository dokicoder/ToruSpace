class_name GameManager extends Node3D

@onready var DonutCenter: Node3D = $"../BaseTransform/CameraDonutCenter"
@onready var SideCenter: Node3D = $"../BaseTransform/CameraDonutCenter/CameraDonutSideCenter"
@onready var CameraContainer: Node3D = $"../BaseTransform/CameraDonutCenter/CameraDonutSideCenter/CameraContainer" 

const s: float = 1

@export var ground_offset: float = 7.0

@export var camera: Node
const MOVE_STEP: float = 200.0

const CellNodeScene: PackedScene = preload("res://scenes/CellNode3D.tscn")

const STEP = 0.1

var board: BoardData

var delta_acc: float = 0.0

var _x: int = 0
var _y: int = 0
var _last_x: int = 0
var _last_y: int = 0

var x:
	set(value):
		_last_x = _x
		_last_y = _y
		_x = (value + Config.WIDTH) % Config.WIDTH
		update_highlight()
	get(): return _x
var y:
	set(value):
		_last_x = _x
		_last_y = _y
		_y = (value + Config.HEIGHT) % Config.HEIGHT
		update_highlight()
	get(): return _y

func update_highlight():
	board.get_cell_at(_last_x, _last_y).highlighted = false
	board.get_cell_at(_x, _y).highlighted = true
	
func _deploy_mines():
	const mine_ratio: float = 0.09
	var num_mines = int(Config.WIDTH * Config.HEIGHT * mine_ratio)

	board.deploy_random_mines(num_mines)

func _ready() -> void:
	board = BoardData.new()
	board.init(Config.WIDTH, Config.HEIGHT)

	_generate_sprite_board()
	
	_reset()
	
	update_camera_transform(x, y)

func _reset():
	board.reset()
	_deploy_mines()

	x = 0
	y = 0

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

func update_camera_transform(xpos: float, ypos: float):
	const smaller_radius = s / (2 * sin(PI / Config.HEIGHT)) 
	const larger_radius = s / (2 * sin(PI / Config.WIDTH))

	var smaller_angle = PI * 2 * (ypos + 0.5) / Config.HEIGHT
	var larger_angle = PI * 2 * (xpos + 0.5) / Config.WIDTH
	
	# node that stays at center of donut and gets rotated around y ("UP") axis
	# located "in the center of the donut hole"
	DonutCenter.rotation.x = 0
	DonutCenter.rotation.y = -larger_angle
	DonutCenter.rotation.z = 0

	# node that tracks the center of the "donut dough" and is sweeped through the donut circle
	SideCenter.rotation.x = smaller_angle
	SideCenter.rotation.y = 0
	SideCenter.rotation.z = 0
	SideCenter.position.z = larger_radius

	# node that tracks the current position on the donut surface
	CameraContainer.position.z = smaller_radius + ground_offset
	
func _generate_sprite_board():
	for cell in board.cells:
		var node = CellNodeScene.instantiate()
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

		add_child(node)
	
func _input(event):
	if event.is_action_pressed("Left"):
		y += 1
	if event.is_action_pressed("Right"):
		y -= 1
	if event.is_action_pressed("Up"):
		x += 1
	if event.is_action_pressed("Down"):
		x -= 1
	if event.is_action_pressed("Mark"):
		board.make_move_at(x, y, BoardData.MoveType.TOGGLE_MASK)
	if event.is_action_pressed("Unmask"):
		if not board.make_move_at(x, y, BoardData.MoveType.UNMASK_FIELD):
			_reset()
		
	print(x, " ", y)
	update_camera_transform(x, y)

func _process(delta: float) -> void:	
	delta_acc += delta
	if(delta_acc > STEP):
		delta_acc -= STEP
		if board.flood_step():
			# TODO: this is still very inefficient - all mines are checked even	though nothing changed in the vicinity of most of them
			board.mark_cleared_mines()
