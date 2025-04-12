class_name Cell extends Node

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

var x: int = -1
var y: int = -1
var neighbors: Array[Cell] = []

var field: FieldState = FieldState.EMPTY
var mask: MaskState = MaskState.BLIND

var closed: bool = false

func increment_field():
    if field < 9:
        field = field + 1

func reset():
    field = FieldState.EMPTY
    mask = MaskState.BLIND
    closed = false