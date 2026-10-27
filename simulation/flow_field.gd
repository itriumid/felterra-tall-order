class_name FlowField
extends RefCounted
## The way to the nearest cat from anywhere in an area, around what stands in the way. The ground
## is cut into cells, and from the cats' cells outward each cell learns how far it is to walk
## from it; a walker goes downhill. Built for walkers of one width: a cell any part of which is too
## close to an obstacle for them is a wall, so anywhere in an open cell they fit, and going from
## one open cell to the next never clips a corner. Rebuilt only when a cat moves into another cell.

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
## Which cells see which points straight, as they're asked about.
var _seen := {}


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
func toward(points: Array[Vector2]) -> void:
	var from: Array[int] = []
	for point in points:
		var cell := _nearest_open(point)
		if cell >= 0 and not cell in from:
			from.append(cell)
	from.sort()
	if from == _from:
		return
	_from = from
	_seen.clear()
	_distance.fill(FAR)
	# The cheapest cells first, kept in buckets by cost: no step costs more than DIAGONAL, so the
	# buckets go round.
	var buckets: Array = []
	for index in DIAGONAL + 1:
		buckets.append([])
	var waiting := 0
	for cell in from:
		_distance[cell] = 0
		buckets[0].append(cell)
		waiting += 1
	var cost := 0
	while waiting > 0:
		var bucket: Array = buckets[cost % buckets.size()]
		buckets[cost % buckets.size()] = []
		waiting -= bucket.size()
		for cell: int in bucket:
			if _distance[cell] != cost:
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
				var further := cost + STRAIGHT
				if index >= 4:
					# No cutting a wall's corner.
					if _blocked[y * columns + next_x] == 1 or _blocked[next_y * columns + x] == 1:
						continue
					further = cost + DIAGONAL
				if further < _distance[next]:
					_distance[next] = further
					buckets[further % buckets.size()].append(next)
					waiting += 1
		cost += 1


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
