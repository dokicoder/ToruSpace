class_name Board extends Node

const width: int = 200
const height: int = 200

var board: MineField

var delta_acc: float = 0.0

const STEP = 0.1

func _debug_set_all_field_mask_types():
	board.set_mask_at(0, 0, Cell.MaskState.MARKED_UNSURE)
	board.set_mask_at(1, 0, Cell.MaskState.MARKED_MINE)
	board.set_mask_at(2, 0, Cell.MaskState.BLIND)
	board.set_mask_at(3, 0, Cell.MaskState.CLEAR)
	
	for x in range(0, 9):
		board.set_mask_at(x, 1, Cell.MaskState.CLEAR)
		board.set_field_at(x, 1, x)

	board.set_mask_at(9, 1, Cell.MaskState.CLEAR)
	board.set_mask_at(10, 1, Cell.MaskState.CLEAR)
	board.set_field_at(9, 1, Cell.FieldState.MINE_LIVE)
	board.set_field_at(10, 1, Cell.FieldState.MINE_EXPLODED)

func reset():
	board.init(width, height)
	
	const mine_ratio: float = 0.09 # 0.11

	var num_mines = int(width * height * mine_ratio)

	board.deploy_random_mines(num_mines)

func _ready() -> void:
	pass # Replace with function body.
	board = MineField.new()

	reset()

	#_debug_set_all_field_mask_types()
	
func _process(delta: float) -> void:
	delta_acc += delta
	if(delta_acc > STEP):
		delta_acc -= STEP
		if board.flood_step():
			board.mark_cleared_mines()
	
