class_name CellNode3D extends MeshInstance3D

const BASE_OFFSET: float = 0.125

signal activated(event: InputEvent, data: CellData)

var data: CellData

func get_torus_position(x: float, y: float):
	const s: float = 1
	const smaller_radius = s / (2 * sin(PI / Config.HEIGHT))
	const larger_radius = s / (2 * sin(PI / Config.WIDTH))

	var smaller_angle = PI * 2 * y / Config.HEIGHT
	var larger_angle = PI * 2 * x / Config.WIDTH

	return Vector3(
		cos(larger_angle) * (larger_radius + cos(smaller_angle) * smaller_radius),
		sin(larger_angle) * (larger_radius + cos(smaller_angle) * smaller_radius),
		sin(smaller_angle) * smaller_radius
	)

func get_torus_mormal(x: float, y: float):
	var smaller_angle = PI * 2 * y / Config.HEIGHT
	var larger_angle = PI * 2 * x / Config.WIDTH

	#  tangent vector with respect to big circle
	var u = Vector3(
		-sin(larger_angle),
		cos(larger_angle),
		0
	)
	# tangent vector with respect to little circle
	var v = Vector3(
		cos(larger_angle) * (-sin(smaller_angle)),
		sin(larger_angle) * (-sin(smaller_angle)),
		cos(smaller_angle)
	)

	return u.cross(v).normalized()

func update_mesh():
	#position.x = cos(larger_angle) * larger_radius
	#position.y = sin(larger_angle) * larger_radius

	var surface_array = []
	surface_array.resize(Mesh.ARRAY_MAX)

	# PackedVector**Arrays for mesh construction.
	var verts = PackedVector3Array()
	var uvs = PackedVector2Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()

	var x1: int = data.x
	var y1: int = data.y
	var x2: int = (x1 + 1) % Config.WIDTH
	var y2: int = (y1 + 1) % Config.HEIGHT

	verts.append(get_torus_position(x1, y1))
	verts.append(get_torus_position(x1, y2))
	verts.append(get_torus_position(x2, y2))
	verts.append(get_torus_position(x2, y1))
	
	uvs.append(Vector2(1,1))
	uvs.append(Vector2(0,1))
	uvs.append(Vector2(0,0))
	uvs.append(Vector2(1,0))

	normals.append(get_torus_mormal(x1, y1))
	normals.append(get_torus_mormal(x1, y2))
	normals.append(get_torus_mormal(x2, y2))
	normals.append(get_torus_mormal(x2, y1))

	indices.append(0)
	indices.append(1)
	indices.append(2)
	indices.append(0)
	indices.append(2)
	indices.append(3)

	# Assign arrays to surface array.
	surface_array[Mesh.ARRAY_VERTEX] = verts
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_INDEX] = indices

	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	

func update_texture():
	print ("update texture", data.highlighted)
	material_override.uv1_offset = _field_to_texture_offset(data.field, data.mask)
	material_override.albedo_color = Color(0.7, 1, 0.7) if(data.highlighted) else Color(1, 1, 1)
	
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

func _process(delta: float) -> void:
	if(data._invalidated_mesh):
		update_mesh()
		data._invalidated_mesh = false
	if(data._invalidated_texture):
		update_texture()
		data._invalidated_texture = false
