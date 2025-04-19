class_name CellData

enum FieldState {
	EMPTY = 0,
	MINE_LIVE = 16,
	MINE_EXPLODED = 32,
}	

enum MaskState {
	BLIND = 0,
	CLEAR = 1,
	MARKED_UNSURE = 2,
	MARKED_MINE = 3,
}

var x: int:
	get(): return _x
	set(value):
		_x = value
		if node: node.update_mesh()

var y: int:
	get(): return _y
	set(value):
		_y = value
		if node: node.update_mesh()

var field: FieldState:
	get(): return _field
	set(value):
		_field = value
		if node: node.update_texture()

var mask: MaskState:
	get(): return _mask
	set(value):
		_mask = value
		if node: node.update_texture()

var node: CellNode3D
var neighbors: Array[CellData] = []

# cell data

var _x: int = -1
var _y: int = -1

var _field: FieldState = FieldState.EMPTY
var _mask: MaskState = MaskState.BLIND

var closed: bool = false

func increment_field():
	if _field < 9:
		_field = _field + 1
		if node: node.update_texture()

func reset():
	closed = false
	_field = FieldState.EMPTY
	_mask = MaskState.BLIND
	if node: node.update_texture()
