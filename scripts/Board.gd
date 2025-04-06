class_name Board extends Node

const width: int = 20
const height: int = 20

var board: MineField

func _debug_setAllFieldMaskType():
	board.setMaskAt(0, 0, MineField.MaskState.MARKED_UNSURE)
	board.setMaskAt(1, 0, MineField.MaskState.MARKED_MINE)
	board.setMaskAt(2, 0, MineField.MaskState.BLIND)
	board.setMaskAt(3, 0, MineField.MaskState.CLEAR)
	
	for x in range(0, 9):
		board.setMaskAt(x, 1, MineField.MaskState.CLEAR)
		board.setFieldAt(x, 1, x)

	board.setMaskAt(9, 1, MineField.MaskState.CLEAR)
	board.setMaskAt(10, 1, MineField.MaskState.CLEAR)
	board.setFieldAt(9, 1, MineField.FieldState.MINE_LIVE)
	board.setFieldAt(10, 1, MineField.FieldState.MINE_EXPLODED)

func _ready() -> void:
	pass # Replace with function body.
	board = MineField.new()

	board.init(width, height)
	board.deployRandomMines(20)

	#_debug_setAllFieldMaskType()

	
