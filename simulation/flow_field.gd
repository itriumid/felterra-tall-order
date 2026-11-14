class_name FlowField
extends RefCounted
## The way to the nearest cat from anywhere in an area, around what stands in the way. The ground
## is cut into cells, and from the cats' cells outward each cell learns how far it is to walk
## from it; a walker goes downhill. Built for walkers of one width: a cell any part of which is too
## close to an obstacle for them is a wall, so anywhere in an open cell they fit, and going from
## one open cell to the next never clips a corner. Rebuilt when a cat moves into another cell, a
## little a step (see toward).

## How big a cell is, in meters, and what a step costs, straight and on the diagonal: about one
## to the square root of two, in whole numbers so the cheapest is always next.
const CELL := 0.5
const STRAIGHT := 5
const DIAGONAL := 7
const FAR := 1 << 30
const NEIGHBORS: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]

var columns := 0
var rows := 0
var _blocked := PackedByteArray()
var _distance := PackedInt32Array()
var _from: Array[int] = []
## Which cells see which points straight, as they're asked about; and the most of it kept.
var _seen := {}
const MOST_SEEN := 200000


func _init(size := Vector2.ZERO, obstacles: Array[Obstacle] = [], clearance := 0.0) -> void:
	if size == Vector2.ZERO:
		return
	columns = ceili(size.x / CELL)
	rows = ceili(size.y / CELL)
	_blocked.resize(columns * rows)
	_distance.resize(columns * rows)
	_distance.fill(FAR)
	for obstacle in obstacles:
		var reach := obstacle.rect.grow(clearance)
		for y in range(maxi(floori(reach.position.y / CELL), 0), mini(ceili(reach.end.y / CELL), rows)):
			for x in range(maxi(floori(reach.position.x / CELL), 0), mini(ceili(reach.end.x / CELL), columns)):
				if _blocked[y * columns + x] == 0 and obstacle.overlaps(Rect2(Vector2(x, y) * CELL, Vector2.ONE * CELL), clearance):
					_blocked[y * columns + x] = 1


## A field over the same ground as another, its walls already found, to be built toward
## somewhere else: finding the walls is the slow part, and the ground doesn't change.
static func sharing(template: FlowField) -> FlowField:
	var field := FlowField.new()
	field.columns = template.columns
	field.rows = template.rows
	field._blocked = template._blocked
	field._distance.resize(template._distance.size())
	field._distance.fill(FAR)
	return field


## Whether a point can be walked to from where the field was last built toward.
func reaches(where: Vector2) -> bool:
	var cell := _nearest_open(where)
	return cell >= 0 and _distance[cell] < FAR


func blocked(where: Vector2) -> bool:
	var cell := _cell(where)
	return cell < 0 or _blocked[cell] == 1


## Builds the field toward these points, if any of them has moved to another cell since.
##
## All at once, unless it's asked for gradually, as a fight asks: then a little each call (WORK
## cells of it), into a second field that takes over when it's done, so the horde follows the way
## to where the cats were a moment ago while the way to where they are is found (and before there's
## any way at all, goes straight).
## Finding it all in one step, every time a cat crossed into another cell, stopped the world for
## most of a frame several times a second. A build under way is finished before the next starts,
## so cats on the move never keep one from finishing.
func toward(points: Array[Vector2], gradually := false) -> void:
	var from: Array[int] = []
	for point in points:
		var cell := _nearest_open(point)
		if cell >= 0 and not cell in from:
			from.append(cell)
	from.sort()
	if not gradually:
		if from != _from:
			_begin(from)
			_work(FAR)
		return
	if _waiting == 0 and from != _from:
		_begin(from)
	_work(WORK)


## How many cells of a build are worked through in one call.
const WORK := 700
## The field being built: its distances, where it's being built toward, and how far it's got (the
## cells waiting, in buckets by cost, the cheapest first: no step costs more than DIAGONAL, so the
## buckets go round).
var _building := PackedInt32Array()
var _building_toward: Array[int] = []
var _buckets: Array = []
var _waiting := 0
var _cost := 0


func _begin(from: Array[int]) -> void:
	_building_toward = from
	_building.resize(_distance.size())
	_building.fill(FAR)
	_buckets.clear()
	for index in DIAGONAL + 1:
		_buckets.append([])
	_waiting = 0
	_cost = 0
	for cell in from:
		_building[cell] = 0
		_buckets[0].append(cell)
		_waiting += 1
	if _waiting == 0:
		_finish()


## Works through up to so many cells of the build under way; done, the new field takes over.
func _work(most: int) -> void:
	if _waiting == 0:
		return
	var worked := 0
	var distance := _building
	while _waiting > 0 and worked < most:
		var bucket: Array = _buckets[_cost % _buckets.size()]
		_buckets[_cost % _buckets.size()] = []
		_waiting -= bucket.size()
		worked += bucket.size()
		for cell: int in bucket:
			if distance[cell] != _cost:
				continue
			var x := cell % columns
			var y := cell / columns
			for index in NEIGHBORS.size():
				var step := NEIGHBORS[index]
				var next_x := x + step.x
				var next_y := y + step.y
				if next_x < 0 or next_y < 0 or next_x >= columns or next_y >= rows:
					continue
				var next := next_y * columns + next_x
				if _blocked[next] == 1:
					continue
				var further := _cost + STRAIGHT
				if index >= 4:
					# No cutting a wall's corner.
					if _blocked[y * columns + next_x] == 1 or _blocked[next_y * columns + x] == 1:
						continue
					further = _cost + DIAGONAL
				if further < distance[next]:
					distance[next] = further
					_buckets[further % _buckets.size()].append(next)
					_waiting += 1
		_cost += 1
	_building = distance
	if _waiting == 0:
		_finish()


func _finish() -> void:
	var done := _distance
	_distance = _building
	_building = done
	_from = _building_toward


## Which way a walker at a point should go for prey at another: straight at it when nothing
## stands between, and otherwise the way around, toward the next cell nearer.
func way(at: Vector2, to: Vector2) -> Vector2:
	var straight := (to - at).normalized()
	var cell := _cell(at)
	if cell >= 0 and _blocked[cell] == 1:
		# Hard by a wall, closer than the way keeps: on to the open neighbor nearest the prey, the
		# way the rest of the way goes, never straight.
		var out := _downhill_of(cell)
		if out == cell:
			out = _nearest_open(at)
		if out < 0 or _distance[out] >= FAR:
			return straight
		var into := _middle(out) - at
		return into.normalized() if into.length_squared() > 0.0001 else straight
	# Where the way ends, or in sight of where it's going, the last of it is straight.
	if cell < 0 or _distance[cell] >= FAR or _distance[cell] == 0 or _sees(cell, to):
		return straight
	var downhill := _middle(_downhill_of(cell)) - at
	return downhill.normalized() if downhill.length_squared() > 0.0001 else straight


## The middle of a cell, in meters.
func _middle(cell: int) -> Vector2:
	return (Vector2(cell % columns, cell / columns) + Vector2.ONE * 0.5) * CELL


## The neighbor of a cell nearest the prey, or the cell itself if none is nearer: the first of any
## tied, so an even split either way round something still goes one way.
func _downhill_of(cell: int) -> int:
	var x := cell % columns
	var y := cell / columns
	# A walled cell has no distance of its own: any open neighbor is the way out of it.
	var lowest := _distance[cell] if _blocked[cell] == 0 else FAR
	var best := cell
	for index in NEIGHBORS.size():
		var step := NEIGHBORS[index]
		var next_x := x + step.x
		var next_y := y + step.y
		if next_x < 0 or next_y < 0 or next_x >= columns or next_y >= rows:
			continue
		if index >= 4 and (_blocked[y * columns + next_x] == 1 or _blocked[next_y * columns + x] == 1):
			continue
		var distance := _distance[next_y * columns + next_x]
		if _blocked[next_y * columns + next_x] == 0 and distance < lowest:
			lowest = distance
			best = next_y * columns + next_x
	return best


## Whether the straight line from anywhere in a cell to a point crosses no wall: from its middle
## and every corner. Worked out once per cell and point's cell for as long as the field stands.
func _sees(cell: int, to: Vector2) -> bool:
	var key := cell * (columns * rows + 1) + _cell(to) + 1
	if _seen.has(key):
		return _seen[key]
	# What sees what depends only on the walls, which never move, so it's kept from one build to
	# the next: working it all out again after every build was a hitch of its own. Only so much is
	# kept, though.
	if _seen.size() > MOST_SEEN:
		_seen.clear()
	var corner := Vector2(cell % columns, cell / columns) * CELL
	var clear := true
	for from: Vector2 in [corner + Vector2.ONE * CELL * 0.5, corner, corner + Vector2(CELL, 0.0), corner + Vector2(0.0, CELL), corner + Vector2.ONE * CELL]:
		if not _clear_line(from, to):
			clear = false
			break
	_seen[key] = clear
	return clear


func _clear_line(from: Vector2, to: Vector2) -> bool:
	var steps := ceili(from.distance_to(to) / (CELL * 0.5))
	for index in range(1, steps):
		var point := from.lerp(to, float(index) / steps)
		# Right by where it's going doesn't count: a door is against its wall.
		if point.distance_to(to) < CELL * 1.5:
			return true
		var on := _cell(point)
		if on >= 0 and _blocked[on] == 1:
			return false
	return true


func _cell(where: Vector2) -> int:
	var x := floori(where.x / CELL)
	var y := floori(where.y / CELL)
	if x < 0 or y < 0 or x >= columns or y >= rows:
		return -1
	return y * columns + x


## The cell a point is in, or the nearest open one to it when it's in a wall (a cat on a stump).
func _nearest_open(where: Vector2) -> int:
	var cell := _cell(where.clamp(Vector2.ZERO, Vector2(columns, rows) * CELL - Vector2.ONE * 0.01))
	if cell < 0 or _blocked[cell] == 0:
		return cell
	var x := cell % columns
	var y := cell / columns
	for ring in range(1, 6):
		for dy in range(-ring, ring + 1):
			for dx in range(-ring, ring + 1):
				var next_x := x + dx
				var next_y := y + dy
				if next_x >= 0 and next_y >= 0 and next_x < columns and next_y < rows and _blocked[next_y * columns + next_x] == 0:
					return next_y * columns + next_x
	return -1
