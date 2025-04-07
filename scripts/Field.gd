class_name Field extends Sprite2D

var _x: int
var _y: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					print("%d / %d" % [_x, _y])
					Brd.board.make_move(_x, _y, MineField.MoveType.CLEAR_FIELD)
			MOUSE_BUTTON_RIGHT:
				if event.pressed:
					Brd.board.make_move(_x, _y, MineField.MoveType.RESET_MASK)
