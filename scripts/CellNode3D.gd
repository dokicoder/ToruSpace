class_name CellNode3D extends MeshInstance3D

const BASE_OFFSET: float = 0.125

signal activated(event: InputEvent, data: CellData)

var data: CellData

func update_transform():
	#position.x = (data.x - 0.5 * Config.WIDTH) * 1.0 #+ 64
	#position.y = (data.y - 0.5 * Config.HEIGHT) * 1.0 #+ 64
	
	const s: float = 1

	const inner_radius = s / (2 * sin(PI/ Config.HEIGHT))
	const outer_radius = s / (2 * sin(PI/ Config.WIDTH))

	var inner_angle = PI * 2 * data.y / Config.HEIGHT
	var outer_angle = PI * 2 * data.x / Config.WIDTH

	position.x = cos(outer_angle) * (outer_radius + cos(inner_angle) * inner_radius);
	position.y = sin(outer_angle)*(outer_radius+cos(inner_angle)*inner_radius);
	position.z = sin(inner_angle) * inner_radius;
	
	

func update_texture():
	var material = mesh.surface_get_material(0)
	material.uv1_offset = _field_to_texture_offset(data.field, data.mask)
	
func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	activated.emit(event, data)

static func _field_to_texture_offset(field: CellData.FieldState, mask: CellData.MaskState) -> Vector3:
	#if mask == CellData.MaskState.BLIND:
		#return Vector3(6 * BASE_OFFSET, BASE_OFFSET, 0.0)
	#if mask == CellData.MaskState.MARKED_MINE:
		#return Vector3(BASE_OFFSET, 3 * BASE_OFFSET, 0.0)
	#if mask == CellData.MaskState.MARKED_UNSURE:
		#return Vector3(0, 3 * BASE_OFFSET, 0.0)
		
	if field == CellData.FieldState.MINE_LIVE:
		return Vector3(BASE_OFFSET, BASE_OFFSET, 0.0)
	if field == CellData.FieldState.MINE_EXPLODED: 
		return Vector3(BASE_OFFSET, 2 * BASE_OFFSET, 0.0)
		
	if field > 8: 
		return Vector3(2 * BASE_OFFSET, 3 * BASE_OFFSET, 0.0)		

	if field == 8: 
		return Vector3(0, BASE_OFFSET, 0.0)
	
	return Vector3(field * BASE_OFFSET, 0.0, 0.0)
