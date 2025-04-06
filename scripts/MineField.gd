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
	CLEAR_MARK,
}

var _width: int = -1
var _height: int = -1

# TODO: may be more efficient as some packed array
var _field: PackedByteArray = []
var _mask: PackedByteArray = []
var _mineIdxList: PackedByteArray = []
var _floodList: PackedByteArray = []
var _closedList: PackedByteArray = []

var _isFirstMove = true
var _numLiveMines = 0

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
	_mineIdxList.clear()
	_floodList.clear()
	_closedList.clear()

	_isFirstMove = true
	_numLiveMines = 0

	_rng = RandomNumberGenerator.new()

	for i in range(_width * _height):
		_field.append(FieldState.EMPTY)
		_mask.append(MaskState.BLIND)

func xYtoIdx(x: int, y: int) -> int:
	assert(x >= 0 && x < _width && y >= 0 && y < _height)
	return y * _width + x

func idxToXY(idx: int) -> Array[int]:
	assert(idx >= 0 && idx < _width * _height)
	return [idx % _width, idx / _width]

func getFieldAt(x: int, y: int) -> FieldState:
	assert(x >= 0 && x < _width && y >= 0 && y < _height)
	return _field[y * _width + x]

func getFieldAtIdx(idx: int) -> FieldState:
	assert(idx >= 0 && idx < _width * _height)
	return _field[idx]

func getMaskAt(x: int, y: int) -> MaskState:
	assert(x >= 0 && x < _width && y >= 0 && y < _height)
	return _mask[y * _width + x]

func getMaskAtIdx(idx: int) -> MaskState:
	assert(idx >= 0 && idx < _width * _height)
	return _mask[idx]

func setFieldAt(x: int, y: int, state: FieldState):
	assert(x >= 0 && x < _width && y >= 0 && y < _height)
	setFieldAtIdx(y * _width + x, state)

func setFieldAtIdx(idx: int, state: FieldState):
	assert(idx >= 0 && idx < _width * _height)
	_field[idx] = state

func setMaskAt(x: int, y: int, state: MaskState):
	assert(x >= 0 && x < _width && y >= 0 && y < _height)
	setMaskAtIdx(y * _width + x, state)

func setMaskAtIdx(idx: int, state: MaskState):
	assert(idx >= 0 && idx < _width * _height)
	_mask[idx] = state
	
func incrementFieldAt(x: int, y: int):
	incrementFieldAtIdx(y * _width + x)

func incrementFieldAtIdx(idx: int):
	var val = getFieldAtIdx(idx)
	if val < 9:
		setFieldAtIdx(idx, val+1)

func dropMine(x:int, y:int) -> bool:
	var fieldVal = getFieldAt(x, y)
	if fieldVal == FieldState.MINE_LIVE || fieldVal == FieldState.MINE_EXPLODED:
		return false

	setFieldAt(x, y, FieldState.MINE_LIVE)
	_numLiveMines += 1
	return true

func dropMineAtIdx(idx: int) -> bool:
	if _field[idx] == FieldState.MINE_LIVE || _field[idx] == FieldState.MINE_EXPLODED:
		return false

	setFieldAtIdx(idx, FieldState.MINE_LIVE)
	for neighborIdx in getNeighborFieldIndizes(idx):
		incrementFieldAtIdx(neighborIdx)
		
	_numLiveMines += 1
	return true

func deployRandomMines(numMines: int):
	var deployedMines = 0

	while(deployedMines < numMines):
		var idx = _rng.randi_range(0, (_width * _height) - 1) 
		if dropMineAtIdx(idx): deployedMines += 1

	print("Deployed ", deployedMines, " mines")
	
# neighbor ordering:
# 	 0 | 1 | 2
# 	---+---+---
# 	 3 | F | 4
# 	---+---+---
# 	 5 | 6 | 7
# returns indizes linearly, so result is array with 14 elements
func getNeighborFieldPositions(x: int, y: int) -> Array[int]:
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
func getNeighborFieldIndizes(fieldIdx: int) -> Array[int]:
	var indizes = idxToXY(fieldIdx)
	var x = indizes[0]
	var y = indizes[1]

	assert(x >= 0 && x < _width && y >= 0 && y < _height)

	var leftX = (x - 1 + _width) % _width
	var rightX = (x + 1) % _width
	var topY = (y - 1 + _height) % _height
	var bottomY = (y + 1) % _height
	
	return [
		xYtoIdx(leftX, topY), xYtoIdx(x, topY), xYtoIdx(rightX, topY),
		xYtoIdx(leftX, y), xYtoIdx(rightX, y),
		xYtoIdx(leftX, bottomY), xYtoIdx(x, bottomY), xYtoIdx(rightX, bottomY)
	]

func _momHelper(fieldIdx: int) -> bool:
	var fieldVal = getFieldAtIdx(fieldIdx)

	if(fieldVal == FieldState.MINE_LIVE): 
		return true

	var numAdjacentBlinds: int = 0
	for neighborIdx in getNeighborFieldIndizes(fieldIdx):
		var neighborMask = _mask[neighborIdx]
		# count the mine candidates around number
		# todo: ever heard of map/reduce ?
		if neighborMask != MaskState.CLEAR: 
			numAdjacentBlinds += 1
		
	# if number of blinds equals mine count it can be considered obvious how many mines there are
	return numAdjacentBlinds == fieldVal

func markObviousMine(fieldIdx: int) -> bool:
	var fieldVal = getFieldAtIdx(fieldIdx)

	if fieldVal != FieldState:
		return false

	for neighborIdx in getNeighborFieldIndizes(fieldIdx):
		var neighborMask = _mask[neighborIdx]
		var neighborVal = _field[neighborIdx]
		if neighborMask == MaskState.BLIND && neighborVal != FieldState.MINE_LIVE:
			return false
		if neighborMask == MaskState.CLEAR && !_momHelper(neighborIdx):
			return false

	# TODO: make optional and expose to options menu
	return true

func freeForFirstMove(x: int, y: int):
	_isFirstMove = false
	var fieldVal = getFieldAt(x, y)

	if fieldVal == FieldState.EMPTY:
		return
		
	var fieldIdx = xYtoIdx(x, y)
	
	# if field is a mine, just delete it and decrement neighbors
	if fieldVal == FieldState.MINE_LIVE:
		setFieldAt(x, y, FieldState.EMPTY)

		for neighborIdx in getNeighborFieldIndizes(fieldIdx):
			var neighborVal = getFieldAtIdx(neighborIdx)
			# if neighbor is mine, increment center field (which now contains a number, not a mine)
			if neighborVal == FieldState.MINE_LIVE: 
				setFieldAt(x, y, FieldState.EMPTY)
			# tell neighbor that mine has vanished
			elif neighborVal != FieldState.EMPTY:
				setFieldAtIdx(neighborIdx, neighborVal - 1)

	# either it did before or it does now after update: field contains number
	# act as if surrounding mines have been deleted
	var numRemovedMines = 0

	for neighborIdx in getNeighborFieldIndizes(fieldIdx):
		var neighborVal = getFieldAtIdx(neighborIdx)
		# tell all neighbors of any surrounding mine that mine has vanished
		if neighborVal == FieldState.MINE_LIVE:
			var newNeighborVal = 0
			for neighborNeighborIdx in getNeighborFieldIndizes(neighborIdx):
				var neighborNeighborVal = getFieldAtIdx(neighborNeighborIdx)
				if neighborNeighborVal == FieldState.MINE_LIVE:
					newNeighborVal += 1
				elif neighborNeighborVal != FieldState.EMPTY:
					setFieldAtIdx(neighborNeighborIdx, neighborNeighborVal - 1)
			# now actually delete surrounding mines and replace them with their according field value
			setFieldAtIdx(neighborIdx, newNeighborVal)
			# remove 
			_mineIdxList.remove_at(_mineIdxList.find(neighborIdx))
			numRemovedMines += 1
	# there were mines removed, we want to know of that
	# actualNumberOfMines -= numRemovedMines
	# add removed mines again somewhere else
	# TODO: somewhere else could actually happen to be the same place --> fix that
	deployRandomMines(numRemovedMines)


func clearField(x: int, y: int) -> bool:
	#if _isFirstMove: 
	#freeForFirstMove(x, y)
	
	print("clear field ", x, " ", y)
	
	var fieldVal = getFieldAt(x, y)
	var fieldMask = getMaskAt(x, y)
	var fieldIdx = xYtoIdx(x, y)
	
	print(fieldVal, "- m ", fieldMask)
	
	if getMaskAt(x, y) != MaskState.BLIND: 
		return true
	_floodList.append(fieldIdx)
	
	setMaskAtIdx(fieldIdx, MaskState.CLEAR)

	#floodStep()

	# mark obvious mines
	markClearedMines()

	# full flood operation could be slow
	# fullyFloodFrom(field)

	# congrats, you are dead. or lost a life
	if fieldVal == FieldState.MINE_LIVE: 
		setFieldAt(x, y, FieldState.MINE_EXPLODED)
		setMaskAt(x, y, MaskState.MARKED_MINE)
		return false

	return true


# mark all mines the player probably has identified
# TODO: maybe finer-tune implementation
func markClearedMines():
	for index in _mineIdxList:
		if markObviousMine(index):
			# mark for deletion
			_mineIdxList[index] = -1
			# _numberOfMarkedMines += 1
			print("marked cleared mine")

	# filter the elements marked for deletion
	_mineIdxList = Array(_mineIdxList).filter(func (e): e != -1)

func makeMove(x: int, y: int, type: MoveType):
	assert(x >= 0 && x < _width && y >= 0 && y < _height)
	print("Make move  -> ", MoveType.keys()[type], " at ", x, ", ", y)

	if type == MoveType.MARK_MINE:
		setMaskAt(x, y, MaskState.MARKED_MINE)
	elif type == MoveType.MARK_UNSURE:
		setMaskAt(x, y, MaskState.MARKED_UNSURE)
	elif type == MoveType.CLEAR_MARK:
		setMaskAt(x, y, MaskState.CLEAR)
	elif type == MoveType.CLEAR_FIELD:
		clearField(x, y)
	else:
		print("Invalid move type")

func floodStep():
	print("FloodStep - current floodList size: %d" % _floodList.size())

	var nextFloodList: PackedByteArray = []

	for fieldIdx in _floodList:
		if getFieldAtIdx(fieldIdx) != FieldState.EMPTY:
			continue

		setMaskAtIdx(fieldIdx, MaskState.CLEAR)
		for neighborIdx in getNeighborFieldIndizes(fieldIdx):
			if getMaskAtIdx(neighborIdx) == MaskState.BLIND:

				# if neighbor is already in closed or current list, skip it
				if _floodList.find(neighborIdx) != -1: continue
				if _closedList.find(neighborIdx) != -1: continue

				# these neighbors need to be considered next iteration
				nextFloodList.append(neighborIdx)
	
	# replace closedList with current floodList, update floodList to nextFloodList
	_closedList = _floodList
	_floodList = nextFloodList
