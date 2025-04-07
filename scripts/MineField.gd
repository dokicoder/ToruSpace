class_name MineField

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

enum MoveType {
	CLEAR_FIELD,
	MARK_UNSURE,
	MARK_MINE,
	RESET_MASK,
}

var _width: int = -1
var _height: int = -1

# TODO: may be more efficient as some packed array
var _field: PackedByteArray = []
var _mask: PackedByteArray = []
var _mine_idx_list: PackedInt32Array = []
var _flood_list: PackedInt32Array = []
var _closed_list: PackedInt32Array = []

var _is_first_move = true
var _num_live_mines = 0

var _rng: RandomNumberGenerator

@export var width: int:
	get:
		return _width

@export var height: int:
	get:
		return _height

func init(w, h):
	_width = w
	_height = h

	reset()

func reset():
	#_field.resize((_width * _height))
	#_mask.resize((_width * _height))
	_field.clear()
	_mask.clear()
	_mine_idx_list.clear()
	_flood_list.clear()
	_closed_list.clear()

	_is_first_move = true
	_num_live_mines = 0

	_rng = RandomNumberGenerator.new()

	for i in range(_width * _height):
		_field.append(FieldState.EMPTY)
		_mask.append(MaskState.BLIND)

func xy_to_idx(x: int, y: int) -> int:
	assert(x >= 0 && x < _width && y >= 0 && y < _height)
	return y * _width + x

func idx_to_xy(idx: int) -> Array[int]:
	assert(idx >= 0 && idx < _width * _height)
	return [idx % _width, idx / _width]

func get_field_at(x: int, y: int) -> FieldState:
	assert(x >= 0 && x < _width && y >= 0 && y < _height)
	return _field[y * _width + x]

func get_field_at_idx(idx: int) -> FieldState:
	assert(idx >= 0 && idx < _width * _height)
	return _field[idx]

func get_mask_at(x: int, y: int) -> MaskState:
	assert(x >= 0 && x < _width && y >= 0 && y < _height)
	return _mask[y * _width + x]

func get_mask_at_idx(idx: int) -> MaskState:
	assert(idx >= 0 && idx < _width * _height)
	return _mask[idx]

func set_field_at(x: int, y: int, state: FieldState):
	assert(x >= 0 && x < _width && y >= 0 && y < _height)
	set_field_at_idx(y * _width + x, state)

func set_field_at_idx(idx: int, state: FieldState):
	assert(idx >= 0 && idx < _width * _height)
	_field[idx] = state

func set_mask_at(x: int, y: int, state: MaskState):
	assert(x >= 0 && x < _width && y >= 0 && y < _height)
	set_mask_at_idx(y * _width + x, state)

func set_mask_at_idx(idx: int, state: MaskState):
	assert(idx >= 0 && idx < _width * _height)
	_mask[idx] = state
	
func increment_field_at(x: int, y: int):
	increment_field_at_idx(y * _width + x)

func increment_field_at_idx(idx: int):
	var val = get_field_at_idx(idx)
	if val < 9:
		set_field_at_idx(idx, val+1)

func drop_mine_at(x:int, y:int) -> bool:
	return drop_mine_at_idx( xy_to_idx(x, y) )

func drop_mine_at_idx(idx: int) -> bool:
	if _field[idx] == FieldState.MINE_LIVE || _field[idx] == FieldState.MINE_EXPLODED:
		return false

	set_field_at_idx(idx, FieldState.MINE_LIVE)
	_mine_idx_list.append(idx)
	for neighbor_idx in get_neighbor_field_indizes(idx):
		increment_field_at_idx(neighbor_idx)
		
	_num_live_mines += 1
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

func _mom_helper(field_idx: int) -> bool:
	var field_val = get_field_at_idx(field_idx)

	if(field_val == FieldState.MINE_LIVE): 
		return true

	var numAdjacentBlinds: int = 0
	for neighbor_idx in get_neighbor_field_indizes(field_idx):
		var neighborMask = _mask[neighbor_idx]
		# count the mine candidates around number
		# todo: ever heard of map/reduce ?
		if neighborMask != MaskState.CLEAR: 
			numAdjacentBlinds += 1
		
	# if number of blinds equals mine count it can be considered obvious how many mines there are
	return numAdjacentBlinds == field_val

func mark_obvious_mine(field_idx: int) -> bool:
	var field_val = get_field_at_idx(field_idx)

	if field_val != FieldState.MINE_LIVE:
		return false

	for neighbor_idx in get_neighbor_field_indizes(field_idx):
		var neighborMask = _mask[neighbor_idx]
		var neighbor_val = _field[neighbor_idx]
		if neighborMask == MaskState.BLIND && neighbor_val != FieldState.MINE_LIVE:
			return false
		if neighborMask == MaskState.CLEAR && !_mom_helper(neighbor_idx):
			return false

	# TODO: make optional and expose to options menu
	return true

func free_for_first_move(x: int, y: int):
	_is_first_move = false
	var field_val = get_field_at(x, y)

	if field_val == FieldState.EMPTY:
		return
		
	var field_idx = xy_to_idx(x, y)
	
	# if field is a mine, just delete it and decrement neighbors
	if field_val == FieldState.MINE_LIVE:
		set_field_at(x, y, FieldState.EMPTY)

		for neighbor_idx in get_neighbor_field_indizes(field_idx):
			var neighbor_val = get_field_at_idx(neighbor_idx)
			# if neighbor is mine, increment center field (which now contains a number, not a mine)
			if neighbor_val == FieldState.MINE_LIVE: 
				set_field_at(x, y, FieldState.EMPTY)
			# tell neighbor that mine has vanished
			elif neighbor_val != FieldState.EMPTY:
				set_field_at_idx(neighbor_idx, neighbor_val - 1)

	# either it did before or it does now after update: field contains number
	# act as if surrounding mines have been deleted
	var num_removed_mines = 0

	for neighbor_idx in get_neighbor_field_indizes(field_idx):
		var neighbor_val = get_field_at_idx(neighbor_idx)
		# tell all neighbors of any surrounding mine that mine has vanished
		if neighbor_val == FieldState.MINE_LIVE:
			var new_neighbor_val = 0
			for neighbor_neighbor_idx in get_neighbor_field_indizes(neighbor_idx):
				var neighbor_neighbor_val = get_field_at_idx(neighbor_neighbor_idx)
				if neighbor_neighbor_val == FieldState.MINE_LIVE:
					new_neighbor_val += 1
				elif neighbor_neighbor_val != FieldState.EMPTY:
					set_field_at_idx(neighbor_neighbor_idx, neighbor_neighbor_val - 1)
			# now actually delete surrounding mines and replace them with their according field value
			set_field_at_idx(neighbor_idx, new_neighbor_val)
			# remove 
			_mine_idx_list.remove_at(_mine_idx_list.find(neighbor_idx))
			num_removed_mines += 1
	# there were mines removed, we want to know of that
	# actualNumberOfMines -= num_removed_mines
	# add removed mines again somewhere else
	# TODO: somewhere else could actually happen to be the same place --> fix that
	deploy_random_mines(num_removed_mines)

func clear_field(x: int, y: int) -> bool:
	#if _is_first_move: 
	#free_for_first_move(x, y)
	
	print_debug("clear field (%", x, " ", y)
	
	var field_val = get_field_at(x, y)
	#var field_mask = get_mask_at(x, y)
	var field_idx = xy_to_idx(x, y)
	
	if get_mask_at(x, y) != MaskState.BLIND: 
		return true

	_flood_list.append(field_idx)
	
	set_mask_at_idx(field_idx, MaskState.CLEAR)

	#flood_step()

	# mark obvious mines
	#mark_cleared_mines()

	# full flood operation could be slow
	# fullyFloodFrom(field)

	# congrats, you are dead. or lost a life
	# if field_val == FieldState.MINE_LIVE: 
	# 	set_field_at(x, y, FieldState.MINE_EXPLODED)
	# 	set_mask_at(x, y, MaskState.MARKED_MINE)
	# 	return false

	return true


# mark all mines the player probably has identified
# TODO: maybe finer-tune implementation
func mark_cleared_mines():
	for index in _mine_idx_list:
		if mark_obvious_mine(index):
			# mark for deletion
			_mine_idx_list[index] = -1
			# _numberOfMarkedMines += 1
			print("marked cleared mine")

	# filter the elements marked for deletion
	_mine_idx_list = Array(_mine_idx_list).filter(func (e): e != -1)

func make_move(x: int, y: int, type: MoveType):
	assert(x >= 0 && x < _width && y >= 0 && y < _height)
	print("Make move  -> ", MoveType.keys()[type], " at ", x, ", ", y)

	if type == MoveType.MARK_MINE:
		set_mask_at(x, y, MaskState.MARKED_MINE)
	elif type == MoveType.MARK_UNSURE:
		set_mask_at(x, y, MaskState.MARKED_UNSURE)
	elif type == MoveType.RESET_MASK:
		set_mask_at(x, y, MaskState.BLIND)
	elif type == MoveType.CLEAR_FIELD:
		clear_field(x, y)
	else:
		print("Invalid move type")

func flood_step():
	# print("FloodStep - current floodList size: %d" % _flood_list.size())

	var next_flood_list: PackedInt32Array = []

	if _flood_list.size() > 0:
		print("flood count: ", _flood_list.size())

	for field_idx in _flood_list:
		if get_field_at_idx(field_idx) != FieldState.EMPTY:
			continue

		set_mask_at_idx(field_idx, MaskState.CLEAR)
		for neighbor_idx in get_neighbor_field_indizes(field_idx):
			if get_mask_at_idx(neighbor_idx) == MaskState.BLIND:

				# if neighbor is already in closed or current list, skip it
				#if _flood_list.find(neighbor_idx) != -1: continue
				#if _closed_list.find(neighbor_idx) != -1: continue

				if (_closed_list.find(neighbor_idx) == -1 and 
					next_flood_list.find(neighbor_idx) == -1 and
					_flood_list.find(neighbor_idx) == -1): 
					next_flood_list.append(neighbor_idx)
				# these neighbors need to be considered next iteration
				
	
	# replace closedList with current floodList, update floodList to next_flood_list
	_closed_list = _flood_list
	_flood_list = next_flood_list
	
	return not next_flood_list.is_empty()
