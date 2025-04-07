class_name Board extends Node

const width: int = 38
const height: int = 38

var board: MineField

var delta_acc: float = 0.0

const STEP = 0.1

func _debug_set_all_field_mask_types():
	board.set_mask_at(0, 0, MineField.MaskState.MARKED_UNSURE)
	board.set_mask_at(1, 0, MineField.MaskState.MARKED_MINE)
	board.set_mask_at(2, 0, MineField.MaskState.BLIND)
	board.set_mask_at(3, 0, MineField.MaskState.CLEAR)
	
	for x in range(0, 9):
		board.set_mask_at(x, 1, MineField.MaskState.CLEAR)
		board.set_field_at(x, 1, x)

	board.set_mask_at(9, 1, MineField.MaskState.CLEAR)
	board.set_mask_at(10, 1, MineField.MaskState.CLEAR)
	board.set_field_at(9, 1, MineField.FieldState.MINE_LIVE)
	board.set_field_at(10, 1, MineField.FieldState.MINE_EXPLODED)

func _ready() -> void:
	pass # Replace with function body.
	board = MineField.new()

	board.init(width, height)

	var num_mines = int(width * height * 0.11)

	board.deploy_random_mines(num_mines)

	#_debug_set_all_field_mask_types()

	
func _process(delta: float) -> void:
	delta_acc += delta
	if(delta_acc > STEP):
		delta_acc -= STEP
		board.flood_step()
		board.mark_cleared_mines()
	
