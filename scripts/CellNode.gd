class_name CellNode extends Sprite2D

signal activated(event: InputEvent, data: CellData)

var data: CellData

func update_transform():
	position.x = (data.x - 0.5 * Config.WIDTH) * 128 + 64
	position.y = (data.y - 0.5 * Config.HEIGHT) * 128 + 64

func update_texture():
	texture.region.position = _field_to_texture_offset(data.field, data.mask)
	
func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	activated.emit(event, data)

static func _field_to_texture_offset(field: CellData.FieldState, mask: CellData.MaskState) -> Vector2:
	if mask == CellData.MaskState.BLIND:
		return Vector2(6 * 128, 128)
	if mask == CellData.MaskState.MARKED_MINE:
		return Vector2(128, 3 * 128)
	if mask == CellData.MaskState.MARKED_UNSURE:
		return Vector2(0, 3 * 128)
		
	if field == CellData.FieldState.MINE_LIVE:
		return Vector2(128, 128)
	if field == CellData.FieldState.MINE_EXPLODED: 
		return Vector2(128, 2 * 128)
		
	if field > 8: 
		return Vector2(2 * 128, 3 * 128)		

	if field == 8: 
		return Vector2(0, 128)
	
	return Vector2(field * 128, 0)
