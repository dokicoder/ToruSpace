class_name GameManager extends Node3D

@onready var DonutCenter: Node3D = $"../CameraDonutCenter"
@onready var SideCenter: Node3D = $"../CameraDonutCenter/CameraDonutSideCenter"
#@onready var Camera: Node3D = $"../CameraDonutCenter/CameraDonutSideCenter/Camera"
@onready var Marker: Node3D = $"../CameraDonutCenter/CameraDonutSideCenter/Marker"
@onready var CameraCentral: Node3D = $"../Camera3D"

const GROUND_OFFSET = 7.0

@export var camera: Node
const MOVE_STEP: float = 200.0

const CellNodeScene: PackedScene = preload("res://scenes/CellNode3D.tscn")

const STEP = 0.1

var board: BoardData

var delta_acc: float = 0.0

var x = 15
var y = 56

func _deploy_mines():
	const mine_ratio: float = 0.09
	var num_mines = int(Config.WIDTH * Config.HEIGHT * mine_ratio)

	board.deploy_random_mines(num_mines)

func _ready() -> void:
	board = BoardData.new()
	board.init(Config.WIDTH, Config.HEIGHT)
	_deploy_mines()

	_generate_sprite_board()
	
	update_camera_transform(x, y)

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

func update_camera_transform(xpos: float, ypos: float):
	const s: float = 1

	const smaller_radius = s / (2 * sin(PI / Config.HEIGHT))
	const larger_radius = s / (2 * sin(PI / Config.WIDTH))

	var smaller_angle = PI * 2 * (ypos + 0.005) / Config.HEIGHT
	var larger_angle = PI * 2 * (xpos + 0.005) / Config.WIDTH
	
	DonutCenter.rotation.x = 0
	DonutCenter.rotation.y = larger_angle
	DonutCenter.rotation.z = 0
	SideCenter.rotation.x = smaller_angle
	SideCenter.rotation.y = 0
	SideCenter.rotation.z = 0
	
	SideCenter.position.z = -larger_radius
	Marker.position.z = -smaller_radius - GROUND_OFFSET
	#SideCenter.rotation.z = larger_angle
	

func _generate_sprite_board():
	print("generate")

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
		y -= 1
	if event.is_action_pressed("Right"):
		y += 1
	if event.is_action_pressed("Up"):
		x -= 1
	if event.is_action_pressed("Down"):
		x += 1
	print(x, " ", y)
	update_camera_transform(x, y)

func _process(delta: float) -> void:	
	delta_acc += delta
	if(delta_acc > STEP):
		delta_acc -= STEP
		if board.flood_step():
			# TODO: this is still very inefficient - all mines are checked even	though nothing changed in the vicinity of most of them
			board.mark_cleared_mines()

	
