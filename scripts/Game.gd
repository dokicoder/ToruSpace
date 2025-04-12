extends Node

@export var camera: Node
const MOVE_STEP: float = 200.0

const FieldScene: PackedScene = preload("res://scenes/Field.tscn")

func _field_to_texture_region(field: Cell.FieldState, mask: Cell.MaskState) -> Vector2:
	if mask == Cell.MaskState.BLIND:
		return Vector2(6 * 128, 128)
	if mask == Cell.MaskState.MARKED_MINE:
		return Vector2(128, 3 * 128)
	if mask == Cell.MaskState.MARKED_UNSURE:
		return Vector2(0, 3 * 128)
		
	if field == Cell.FieldState.MINE_LIVE:
		return Vector2(128, 128)
	if field == Cell.FieldState.MINE_EXPLODED: 
		return Vector2(128, 2 * 128)
		
	if field > 8: 
		return Vector2(2 * 128, 3 * 128)		

	if field == 8: 
		return Vector2(0, 128)
	
	return Vector2(field * 128, 0)

func _generate_sprite_board():
	print("generate")
	
	for idx in range(0, Brd.width * Brd.height):
		var coords = Brd.board.idx_to_xy(idx)
		var x = coords[0]
		var y = coords[1]
		
		var field = FieldScene.instantiate() as Field
		field._x = x
		field._y = y
		field.position.x = (x - 0.5 * Brd.width) * 128 + 64
		field.position.y = (y - 0.5 * Brd.height) * 128 + 64
		
		field.texture = field.texture.duplicate()
		var cell = Brd.board.get_cell_at(x, y)
		field.texture.region.position = _field_to_texture_region(cell.field, cell.mask) #Vector2((2 + idx % 3) * 128, 0)

		add_child(field)

		if x == 0 || x == Brd.width - 1:
			var borderClone = field.duplicate() as Field
			borderClone.texture = borderClone.texture.duplicate()
			borderClone.self_modulate = Color(0.7, 1.0, 0.7, 0.7)

			borderClone.position.y = (y - 0.5 * Brd.height) * 128 + 64

			if x == 0:
				borderClone.position.x = (0.5 * Brd.width) * 128 + 64
			if x == Brd.width - 1:
				borderClone.position.x = (-0.5 * Brd.width - 1) * 128 + 64
			
			borderClone._x = x
			borderClone._y = y

			add_child(borderClone)

		if y == 0 || y == Brd.height - 1:
			var borderClone = field.duplicate() as Field
			borderClone.texture = borderClone.texture.duplicate()
			borderClone.self_modulate = Color(0.7, 1.0, 0.7, 0.7)

			field.position.x = (x - 0.5 * Brd.width) * 128 + 64

			if y == 0:
				borderClone.position.y = (0.5 * Brd.height) * 128 + 64
			if y == Brd.height - 1:
				borderClone.position.y = (-0.5 * Brd.height - 1) * 128 + 64
			
			borderClone._x = x
			borderClone._y = y

			add_child(borderClone)

func _ready() -> void:
	_generate_sprite_board()
	
func _input(event):
	if event.is_action_pressed("Left"):
		camera.position.x -= MOVE_STEP
	if event.is_action_pressed("Right"):
		camera.position.x += MOVE_STEP
	if event.is_action_pressed("Up"):
		camera.position.y -= MOVE_STEP
	if event.is_action_pressed("Down"):
		camera.position.y += MOVE_STEP

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#print("%s" % (get_children().size()))
	for field in get_children():
		var cell = Brd.board.get_cell_at(field._x, field._y)
		field.texture.region.position = _field_to_texture_region(cell.field, cell.mask)
