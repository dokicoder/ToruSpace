class_name BoardData

var _width: int = -1
var _height: int = -1

var cells: Array[CellData] = []

# list of mines to check for automatic marking
var _clear_tracker_mine_list: Array[CellData] = []
var _flood_list: Array[CellData] = []

var _rng: RandomNumberGenerator

enum MoveType {
	UNMASK_FIELD,
	MARK_UNSURE,
	MARK_MINE,
	RESET_MASK,
	TOGGLE_MASK
}

@export var width: int:
	get:
		return _width

@export var height: int:
	get:
		return _height

# set up board with (empty) cells and neighbor information
func init(w, h):
	_width = w
	_height = h
	cells.clear()

	# create cells
	for i in range(_width * _height):
		var cell = CellData.new()

		var indizes = idx_to_xy(i)
		cell.x = indizes[0]
		cell.y = indizes[1]

		cells.append(cell)

	# set up neighbor information
	for i in range(_width * _height):
		var cell = get_cell_at_idx(i)

		for neighbor_idx in get_neighbor_field_indizes(i):
			cell.neighbors.append(get_cell_at_idx(neighbor_idx))

	reset()

func reset():
	_clear_tracker_mine_list.clear()
	_flood_list.clear()

	_rng = RandomNumberGenerator.new()

	for cell in cells:
		cell.reset()

func xy_to_idx(x: int, y: int) -> int:
	assert(x >= 0 && x < _width && y >= 0 && y < _height)
	return y * _width + x

func idx_to_xy(idx: int) -> Array[int]:
	assert(idx >= 0 && idx < _width * _height)
	return [idx % _width, idx / _width]

func get_cell_at(x: int, y: int) -> CellData:
	var idx = xy_to_idx(x, y)
	return get_cell_at_idx(idx)

func get_cell_at_idx(idx: int) -> CellData:
	assert(idx >= 0 && idx < _width * _height)
	return cells[idx]

func drop_mine_at(x:int, y:int) -> bool:
	return drop_mine_at_idx( xy_to_idx(x, y) )

func drop_mine_at_idx(idx: int) -> bool:
	var cell = get_cell_at_idx(idx)
	if cell.field == CellData.FieldState.MINE_LIVE || cell.field == CellData.FieldState.MINE_EXPLODED:
		return false

	cell.field = CellData.FieldState.MINE_LIVE
	_clear_tracker_mine_list.append(cell)
	for neighbor in cell.neighbors:
		neighbor.increment_field()

	return true

func deploy_random_mines(numMines: int):
	var deployedMines = 0

	while(deployedMines < numMines):
		var idx = _rng.randi_range(0, (_width * _height) - 1) 
		if drop_mine_at_idx(idx): deployedMines += 1

	print("Deployed ", deployedMines, " mines")
	
# neighbor ordering:
# 	 0 | 1 | 2
# 	---+---+---
# 	 3 | F | 4
# 	---+---+---
# 	 5 | 6 | 7
# returns indizes linearly, so result is array with 14 elements
func get_neighbor_field_positions(x: int, y: int) -> Array[int]:
	assert(x >= 0 && x < _width && y >= 0 && y < _height)

	var leftX = (x - 1 + _width) % _width
	var rightX = (x + 1) % _width
	var topY = (y - 1 + _height) % _height
	var bottomY = (y + 1) % _height

	return [
		leftX, topY, x, topY, rightX, topY,
		leftX, y, rightX, y,
		leftX, bottomY, x, bottomY, rightX, bottomY
	]

# neighbor ordering:
# 	 0 | 1 | 2
# 	---+---+---
# 	 3 | F | 4
# 	---+---+---
# 	 5 | 6 | 7
func get_neighbor_field_indizes(field_idx: int) -> Array[int]:
	var indizes = idx_to_xy(field_idx)
	var x = indizes[0]
	var y = indizes[1]

	assert(x >= 0 && x < _width && y >= 0 && y < _height)

	var leftX = (x - 1 + _width) % _width
	var rightX = (x + 1) % _width
	var topY = (y - 1 + _height) % _height
	var bottomY = (y + 1) % _height
	
	return [
		xy_to_idx(leftX, topY), xy_to_idx(x, topY), xy_to_idx(rightX, topY),
		xy_to_idx(leftX, y), xy_to_idx(rightX, y),
		xy_to_idx(leftX, bottomY), xy_to_idx(x, bottomY), xy_to_idx(rightX, bottomY)
	]

func _mom_helper(cell: CellData) -> bool:
	if(cell.field == CellData.FieldState.MINE_LIVE): 
		return true

	var numAdjacentBlinds: int = 0

	for neighbor in cell.neighbors:
		# count the mine candidates around number
		# todo: ever heard of map/reduce ?
		if neighbor.mask != CellData.MaskState.CLEAR: 
			numAdjacentBlinds += 1
		
	# if number of blinds equals mine count it can be considered obvious how many mines there are
	return numAdjacentBlinds == cell.field

func mark_obvious_mine(cell: CellData) -> bool:
	if cell.field != CellData.FieldState.MINE_LIVE:
		return false
	
	for neighbor in cell.neighbors:
		if neighbor.mask == CellData.MaskState.BLIND && neighbor.field != CellData.FieldState.MINE_LIVE:
			return false
		if neighbor.mask == CellData.MaskState.CLEAR && !_mom_helper(neighbor):
			return false

	cell.mask = CellData.MaskState.MARKED_MINE
	# TODO: make optional and expose to options menu
	return true

# func free_for_first_move(x: int, y: int):
# 	_is_first_move = false
# 	var field_val = get_field_at(x, y)

# 	if field_val == CellData.FieldState.EMPTY:
# 		return
		
# 	var field_idx = xy_to_idx(x, y)
	
# 	# if field is a mine, just delete it and decrement neighbors
# 	if field_val == CellData.FieldState.MINE_LIVE:
# 		set_field_at(x, y, CellData.FieldState.EMPTY)

# 		for neighbor_idx in get_neighbor.field_indizes(field_idx):
# 			var neighbor_val = get_field_at_idx(neighbor_idx)
# 			# if neighbor is mine, increment center field (which now contains a number, not a mine)
# 			if neighbor_val == CellData.FieldState.MINE_LIVE: 
# 				set_field_at(x, y, CellData.FieldState.EMPTY)
# 			# tell neighbor that mine has vanished
# 			elif neighbor_val != CellData.FieldState.EMPTY:
# 				set_field_at_idx(neighbor_idx, neighbor_val - 1)

# 	# either it did before or it does now after update: field contains number
# 	# act as if surrounding mines have been deleted
# 	var num_removed_mines = 0

# 	for neighbor_idx in get_neighbor.field_indizes(field_idx):
# 		var neighbor_val = get_field_at_idx(neighbor_idx)
# 		# tell all neighbors of any surrounding mine that mine has vanished
# 		if neighbor_val == CellData.FieldState.MINE_LIVE:
# 			var new_neighbor_val = 0
# 			for neighbor_neighbor_idx in get_neighbor.field_indizes(neighbor_idx):
# 				var neighbor_neighbor_val = get_field_at_idx(neighbor_neighbor_idx)
# 				if neighbor_neighbor_val == CellData.FieldState.MINE_LIVE:
# 					new_neighbor_val += 1
# 				elif neighbor_neighbor_val != CellData.FieldState.EMPTY:
# 					set_field_at_idx(neighbor_neighbor_idx, neighbor_neighbor_val - 1)
# 			# now actually delete surrounding mines and replace them with their according field value
# 			set_field_at_idx(neighbor_idx, new_neighbor_val)
# 			# remove 
# 			_clear_tracker_mine_list.remove_at(_clear_tracker_mine_list.find(neighbor_idx))
# 			num_removed_mines += 1
# 	# there were mines removed, we want to know of that
# 	# actualNumberOfMines -= num_removed_mines
# 	# add removed mines again somewhere else
# 	# TODO: somewhere else could actually happen to be the same place --> fix that
# 	deploy_random_mines(num_removed_mines)

func unmask_field(cell: CellData) -> bool:
	#if _is_first_move: 
	#	free_for_first_move(x, y)

	if cell.mask != CellData.MaskState.BLIND: 
		return true

	cell.mask = CellData.MaskState.CLEAR
	_flood_list.append(cell)

	# if unmasked field is a mine, false is returned
	return cell.field != CellData.FieldState.MINE_LIVE
	# cell.field = CellData.FieldState.MINE_EXPLODED

# mark all mines the player probably has identified
# TODO: this should not be done by default later
# I guess this is either a perk or is delayed until the player has identified a certain number of mines
# or is done delayed by some "worker drones"
func mark_cleared_mines():
	print(_clear_tracker_mine_list.size(), " mines to check")

	var minecells_to_delete: Array[CellData] = []

	for index in range(_clear_tracker_mine_list.size()):
		var mine_cell = _clear_tracker_mine_list[index]
		if mark_obvious_mine(mine_cell):
			# mark for deletion
			minecells_to_delete.append(mine_cell)
			print("marked cleared mine")

	# filter the elements marked for deletion
	for mine_cell in minecells_to_delete:
		_clear_tracker_mine_list.remove_at(_clear_tracker_mine_list.find(mine_cell))

func make_move_at(x: int, y: int, type: MoveType) -> bool:
	var cell = get_cell_at(x, y)
	return make_move(cell, type)

func make_move(cell: CellData, type: MoveType) -> bool:
	print_debug("Make move  -> %s at  %d / %d" % [MoveType.keys()[type], cell.x, cell.y])

	if type == MoveType.MARK_MINE:
		cell.mask = CellData.MaskState.MARKED_MINE
	elif type == MoveType.MARK_UNSURE:
		cell.mask = CellData.MaskState.MARKED_UNSURE
	elif type == MoveType.RESET_MASK:
		cell.mask = CellData.MaskState.BLIND
	elif type == MoveType.TOGGLE_MASK:
		if(cell.mask == CellData.MaskState.CLEAR):
			return true
		if(cell.mask == CellData.MaskState.MARKED_UNSURE || cell.mask == CellData.MaskState.MARKED_MINE):
			cell.mask = CellData.MaskState.BLIND
		else:
			cell.mask = CellData.MaskState.MARKED_MINE
	elif type == MoveType.UNMASK_FIELD:
		return unmask_field(cell)
	else:
		print("Invalid move type")
		
	return true

func flood_step():
	# print("FloodStep - current floodList size: %d" % _flood_list.size())

	var next_flood_list: Array[CellData] = []

	var did_flood = not _flood_list.is_empty()

	if _flood_list.size() > 0:
		print("flood count: ", _flood_list.size())

	for cell in _flood_list:
		cell.mask = CellData.MaskState.CLEAR

		if cell.field != CellData.FieldState.EMPTY:
			continue

		cell.closed = true

		for neighbor in cell.neighbors:
			if neighbor.mask == CellData.MaskState.BLIND:

				# only add neighbor if it is not closed and not already on the list
				if (not neighbor.closed
					and next_flood_list.find(neighbor) == -1 
					and _flood_list.find(neighbor) == -1): 
					next_flood_list.append(neighbor)	
	# flood list for next iteration has been defined				
	_flood_list = next_flood_list
	
	return did_flood
