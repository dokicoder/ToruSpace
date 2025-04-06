extends Node

const FieldScene: PackedScene = preload("res://scenes/Field.tscn")

func _fieldToTextureRegion(field: MineField.FieldState, mask: MineField.MaskState) -> Vector2:
	if mask == MineField.MaskState.BLIND:
		return Vector2(6 * 128, 128)
	if mask == MineField.MaskState.MARKED_MINE:
		return Vector2(0, 3 * 128)
	if mask == MineField.MaskState.MARKED_UNSURE:
		return Vector2(128, 3 * 128)
		
	if field == MineField.FieldState.MINE_LIVE:
		return Vector2(128, 128)
	if field == MineField.FieldState.MINE_EXPLODED: 
		return Vector2(128, 2 * 128)
		
	if field > 8: 
		return Vector2(2 * 128, 3 * 128)		

	if field == 8: 
		return Vector2(0, 128)
	
	return Vector2(field * 128, 0)

func _generateSpriteBoard():
	print("generate")
	
	for idx in range(0, Brd.width * Brd.height):
		var coords = Brd.board.idxToXY(idx)
		var x = coords[0]
		var y = coords[1]
		
		var field = FieldScene.instantiate() as Field
		field._x = x
		field._y = y
		field.position.x = (x - 0.5 * Brd.width) * 128 + 64
		field.position.y = (y - 0.5 * Brd.height) * 128 + 64
		
		field.texture = field.texture.duplicate()
		field.texture.region.position = _fieldToTextureRegion(Brd.board.getFieldAtIdx(idx), Brd.board.getMaskAtIdx(idx)) #Vector2((2 + idx % 3) * 128, 0)

		add_child(field)

		# if x == 0 || x == Brd.width - 1 || y == 0 || y == Brd.height - 1:
		# 	var borderClone = field.duplicate()
		# 	borderClone.texture = borderClone.texture.duplicate()
		# 	borderClone.self_modulate = Color(0.9, 1.0, 0.9, 0.7)

		# 	borderClone.position.x = (x - 0.5 * Brd.width) * 128 + 64
		# 	borderClone.position.y = (y - 0.5 * Brd.height) * 128 + 64

		# 	if x == 0:
		# 		borderClone.position.x = (0.5 * Brd.width) * 128 + 64
		# 	if x == Brd.width - 1:
		# 		borderClone.position.x = (-0.5 * Brd.width) * 128 + 64
		# 	if y == 0:
		# 		borderClone.position.y = (0.5 * Brd.height) * 128 + 64
		# 	if y == Brd.height - 1:
		# 		borderClone.position.y = (-0.5 * Brd.height) * 128 + 64

		# 	add_child(borderClone)

func _ready() -> void:
	_generateSpriteBoard()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#print("%s" % (get_children().size()))
	for field in get_children():
		field.texture.region.position = _fieldToTextureRegion(Brd.board.getFieldAt(field._x, field._y), Brd.board.getMaskAt(field._x, field._y))
