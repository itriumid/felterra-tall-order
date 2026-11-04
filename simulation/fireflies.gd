class_name Fireflies
extends RefCounted
## Whatever falls, a firefly rises from it, carrying what it was worth to the crew, and hangs where
## it rose. A cat coming within PULL draws it: it comes to him, faster as it comes, and caught, it
## counts for the whole crew. Nobody near, it waits there as long as the run lasts. Freeing an area
## or cleansing a grove calls every one of them in.
##
## A long run leaves hundreds lying about, so they're kept cheap: by slot, in packed arrays, a
## caught one's slot free for the next to rise; in a grid, so a cat only looks at those near him;
## and only the ones coming to a cat move. A guest is sent a slot only when it changes: one rising,
## starting to come, or caught; a guest flies those coming on its own.

## How near a cat draws one, how near it's caught, in meters; how fast one comes at first, how
## quickly it gathers speed, and how fast it goes at most, in meters a second.
const PULL := 1.5
const CATCH := 0.25
const SPEED_FROM := 1.2
const SPEED_UP := 12.0
const SPEED_MOST := 9.0
## How much one firefly carries before a fall's worth is split over another, and how many a single
## fall rises as at most: a dog is one bright one, a giant's worth a few.
const SPLIT_FROM := 4
const MOST_A_FALL := 5
const CELL := 2.0

## Each slot: where it is, what it's worth (none for a free slot), when it rose, in the run's time,
## and how fast it's coming (none while it hangs).
var at := PackedVector2Array()
var worth := PackedInt32Array()
var born := PackedFloat32Array()
var speed := PackedFloat32Array()
var _free := PackedInt32Array()
## Those hanging, by grid cell, as slots; and those coming.
var _cells := {}
var _coming := PackedInt32Array()
## The slots changed since the world was last taken to send.
var _touched := {}


## How many are out, hanging or coming.
func count() -> int:
	var out := 0
	for each in worth:
		out += 1 if each > 0 else 0
	return out


## How much experience is out, hanging or coming.
func total() -> int:
	var sum := 0
	for each in worth:
		sum += each
	return sum


## Fireflies rise where something fell, its worth shared over a few if it was worth a lot.
func rise(where: Vector2, amount: int, time: float) -> void:
	if amount <= 0:
		return
	var many := clampi(ceili(amount / float(SPLIT_FROM)), 1, MOST_A_FALL)
	for index in many:
		var share := amount / many + (1 if index < amount % many else 0)
		# Spread round where it fell, by the golden angle: no dice, so the host's stay its own.
		var spot := where if many == 1 else where + Vector2.from_angle(index * 2.39996) * (0.12 + 0.05 * index)
		_add(spot, share, time)


func _add(where: Vector2, amount: int, time: float) -> void:
	var slot: int
	if _free.is_empty():
		slot = worth.size()
		at.append(where)
		worth.append(amount)
		born.append(time)
		speed.append(0.0)
	else:
		slot = _free[_free.size() - 1]
		_free.resize(_free.size() - 1)
		at[slot] = where
		worth[slot] = amount
		born[slot] = time
		speed[slot] = 0.0
	_hang(slot)


func _hang(slot: int) -> void:
	var cell := _cell_of(at[slot])
	# A packed array comes out of a table as a copy: it's put back with the slot added.
	var slots: PackedInt32Array = _cells.get(cell, PackedInt32Array())
	slots.append(slot)
	_cells[cell] = slots
	_touched[slot] = true


func _unhang(slot: int) -> void:
	var cell := _cell_of(at[slot])
	var slots: PackedInt32Array = _cells.get(cell, PackedInt32Array())
	var found := slots.find(slot)
	if found < 0:
		return
	slots.remove_at(found)
	if slots.is_empty():
		_cells.erase(cell)
	else:
		_cells[cell] = slots


func _free_slot(slot: int) -> void:
	worth[slot] = 0
	speed[slot] = 0.0
	_free.append(slot)
	_touched[slot] = true


static func _cell_of(where: Vector2) -> Vector2i:
	return Vector2i(floori(where.x / CELL), floori(where.y / CELL))


## The slots of those hanging within reach of a point.
func hanging_near(where: Vector2, reach: float) -> PackedInt32Array:
	var near := PackedInt32Array()
	var low := _cell_of(where - Vector2(reach, reach))
	var high := _cell_of(where + Vector2(reach, reach))
	for x in range(low.x, high.x + 1):
		for y in range(low.y, high.y + 1):
			var slots: Variant = _cells.get(Vector2i(x, y))
			if slots == null:
				continue
			for slot: int in slots:
				if at[slot].distance_squared_to(where) <= reach * reach:
					near.append(slot)
	return near


## Where the nearest hanging within reach is, or nowhere (INF).
func nearest(where: Vector2, reach: float) -> Vector2:
	var best := Vector2.INF
	for slot in hanging_near(where, reach):
		if not best.is_finite() or at[slot].distance_squared_to(where) < best.distance_squared_to(where):
			best = at[slot]
	return best


## Swallows those hanging within reach (a tuyul does), and returns what they were worth.
func take_near(where: Vector2, reach: float) -> int:
	var taken := 0
	for slot in hanging_near(where, reach):
		_unhang(slot)
		taken += worth[slot]
		_free_slot(slot)
	return taken


## Every one out comes to the crew.
func call_all() -> void:
	for slot in worth.size():
		if worth[slot] > 0 and speed[slot] <= 0.0:
			_start_coming(slot)


func _start_coming(slot: int) -> void:
	_unhang(slot)
	speed[slot] = SPEED_FROM
	_coming.append(slot)
	_touched[slot] = true


## Cats draw those near them; those coming come; the caught are returned, as {position, worth}.
func step(delta: float, cats: Array[Cat]) -> Array[Dictionary]:
	var standing: Array[Cat] = []
	for cat in cats:
		if cat.alive():
			standing.append(cat)
	for cat in standing:
		for slot in hanging_near(cat.body.position, PULL):
			_start_coming(slot)
	var caught: Array[Dictionary] = []
	if standing.is_empty() or _coming.is_empty():
		return caught
	var still := PackedInt32Array()
	for slot in _coming:
		var to := _fly(slot, delta, standing)
		if to.is_finite():
			caught.append({"position": to, "worth": worth[slot]})
			_free_slot(slot)
		else:
			still.append(slot)
	_coming = still
	return caught


## One coming, a step nearer the nearest cat: where it's caught, if it is, or nowhere (INF). Its
## flight isn't sent: a guest flies it the same way (see glide) until word comes it was caught.
func _fly(slot: int, delta: float, standing: Array[Cat]) -> Vector2:
	var from := at[slot]
	var to := standing[0].body.position
	for cat in standing:
		if cat.body.position.distance_squared_to(from) < to.distance_squared_to(from):
			to = cat.body.position
	speed[slot] = minf(speed[slot] + SPEED_UP * delta, SPEED_MOST)
	var stride := speed[slot] * delta
	if from.distance_to(to) <= CATCH + stride:
		return to
	at[slot] = from.move_toward(to, stride)
	return Vector2.INF


## A guest's side, every frame: those coming fly on to the nearest cat, to be drawn there until
## the host says who caught them.
func glide(delta: float, cats: Array[Cat]) -> void:
	var standing: Array[Cat] = []
	for cat in cats:
		if cat.alive():
			standing.append(cat)
	if standing.is_empty():
		return
	for slot in _coming:
		_fly(slot, delta, standing)


## The slots changed since the last call, and forgets them: the host takes these once a tick.
func take_touched() -> PackedInt32Array:
	var slots := PackedInt32Array(_touched.keys())
	_touched.clear()
	return slots


## Sets one slot as it arrived (a guest's side): kept in the grid so the view finds those on
## screen the same way, but nothing comes on its own.
func put(slot: int, where: Vector2, amount: int, rose: float, coming: float) -> void:
	while worth.size() <= slot:
		at.append(Vector2.ZERO)
		worth.append(0)
		born.append(0.0)
		speed.append(0.0)
	if worth[slot] > 0:
		if speed[slot] > 0.0:
			var found := _coming.find(slot)
			if found >= 0:
				_coming.remove_at(found)
		else:
			_unhang(slot)
	at[slot] = where
	worth[slot] = amount
	born[slot] = rose
	speed[slot] = coming
	if amount > 0:
		if coming > 0.0:
			_coming.append(slot)
		else:
			_hang(slot)
	_touched.clear()


## The slots of every one within an area, in meters, and every one coming: what the view draws.
func within(area: Rect2) -> PackedInt32Array:
	var slots := PackedInt32Array()
	var low := _cell_of(area.position)
	var high := _cell_of(area.end)
	for x in range(low.x, high.x + 1):
		for y in range(low.y, high.y + 1):
			var here: Variant = _cells.get(Vector2i(x, y))
			if here != null:
				slots.append_array(here)
	slots.append_array(_coming)
	return slots
