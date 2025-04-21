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
		_invalidated_mesh = true

var y: int:
	get(): return _y
	set(value):
		_y = value
		_invalidated_mesh = true

var field: FieldState:
	get(): return _field
	set(value):
		_field = value
		_invalidated_texture = true

var mask: MaskState:
	get(): return _mask
	set(value):
		_mask = value
		_invalidated_texture = true

var highlighted: bool:
	set(value):
		_highlighted = value
		_invalidated_texture = true
	get: return _highlighted

var node: CellNode3D
var neighbors: Array[CellData] = []

# cell data

var _x: int = -1
var _y: int = -1

var _field: FieldState = FieldState.EMPTY
var _mask: MaskState = MaskState.BLIND

var _invalidated_mesh = false
var _invalidated_texture = false

var _highlighted = false


var closed: bool = false

func increment_field():
	if _field < 9:
		_field = _field + 1
		if node: node.update_texture()

func reset():
	closed = false
	_field = FieldState.EMPTY
	_mask = MaskState.BLIND
	_highlighted = false
	if node: node.update_texture()
