class_name Board extends Node

const width: int = 20
const height: int = 20

var board: MineField

func _ready() -> void:
	pass # Replace with function body.
	board = MineField.new()

	board.init(width, height)
	board.deployRandomMines(40)
