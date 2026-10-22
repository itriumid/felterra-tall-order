class_name VillageMap
extends RefCounted
## The cats' village at the forest's edge, as a place to walk: a forest path coming in from the
## left, the village itself, and on its far side the path out to the clearing. Everything
## between runs happens here. The cats she's rescued live in it.
##
## When the story starts, the company's machines have already been through: every building is a
## ruin. Bringing them back, one by one, is how the village grows, and each opens what it holds.
## Runs headless at the arena's step, in meters and seconds.

## The whole of it, in meters: the forest path to the left of VILLAGE_FROM, the village to the
## right. The path runs along the middle, between PATH_TOP and PATH_BOTTOM.
const SIZE := Vector2(30.0, 9.0)
const VILLAGE_FROM := 12.0
const PATH_TOP := 3.6
const PATH_BOTTOM := 6.4
## Where she stands on the title, on the forest path, and where she walks in to, in the village.
const TITLE_SPOT := Vector2(5.0, 5.0)
const HOME_SPOT := Vector2(19.0, 5.2)
## The exit: walking off the village's right edge, on the path, starts a run; off the path, the
## edge is trees. Coming home from one, she walks back in from there.
const EXIT_FROM := 29.7
const RETURN_SPOT := Vector2(26.5, 5.0)
## How close to a door she has to be to use it, past a share of the building's width.
const DOOR_REACH := 0.7
## How fast she walks in a cutscene with a story to tell over it, how fast with none (her own
## full pace: nothing to wait for), and how fast the villagers amble.
const STROLL_SPEED := 1.4
const WALK_IN_SPEED := Cat.SPEED
const AMBLE_SPEED := 0.7
## The buildings, by name: the elder's longhouse, the smithy, and the huts. Each is a ruin until
## it's restored, and stays solid either way: a ruin is still in the way.
const LONGHOUSE := Rect2(15.5, 1.3, 5.0, 1.6)
const SMITHY := Rect2(22.5, 1.4, 3.2, 1.5)
## The map of the forest, carved on a board at the gate: where the next run goes. It was never a
## ruin.
const BOARD := Rect2(27.3, 6.7, 1.2, 0.45)
const HUTS: Array[Rect2] = [
	Rect2(14.0, 7.0, 2.0, 1.4), Rect2(17.5, 7.2, 2.0, 1.4), Rect2(21.0, 7.0, 2.0, 1.4),
	Rect2(24.5, 7.2, 2.0, 1.4), Rect2(26.8, 1.6, 2.0, 1.3), Rect2(12.6, 1.6, 2.0, 1.3),
]

var cat := Cat.new()
## The cats she's rescued, ambling about: each a Cat in its own coat, with where it's going.
var villagers: Array[Cat] = []
var names: Array[String] = []
var buildings: Array[Dictionary] = []
var random := RandomNumberGenerator.new()
var time := 0.0
## Where she's being walked to in a cutscene, or nowhere (INF): while she is, steering is ignored.
## And how fast: slower while a story is told over the walk.
var walking_to := Vector2.INF
var stroll_speed := STROLL_SPEED
var _amble_to: Array[Vector2] = []


## Every building's name, in the order they stand.
static func building_names() -> Array[String]:
	var names_in_order: Array[String] = ["longhouse", "smithy"]
	for index in HUTS.size():
		names_in_order.append("hut_%d" % index)
	return names_in_order


func _init(rescued: Array = [], restored: Array = [], seed_value := 39) -> void:
	random.seed = seed_value
	cat.weapons.clear()
	cat.body.position = TITLE_SPOT
	buildings.append({"name": "longhouse", "kind": "longhouse", "footprint": LONGHOUSE})
	buildings.append({"name": "smithy", "kind": "smithy", "footprint": SMITHY})
	for index in HUTS.size():
		buildings.append({"name": "hut_%d" % index, "kind": "hut", "footprint": HUTS[index], "paint": index})
	for building in buildings:
		building.restored = building.name in restored
	buildings.append({"name": "board", "kind": "board", "footprint": BOARD, "restored": true})
	for each: Dictionary in rescued:
		var villager := Cat.new()
		villager.weapons.clear()
		villager.coat = each.get("coat", "orange")
		villager.body.position = _somewhere_in_the_village()
		villagers.append(villager)
		names.append(each.get("name", ""))
		_amble_to.append(_somewhere_in_the_village())


## The building she's at the door of, by name, or "" if she isn't at one: close to the middle of
## its front, where its door is.
func at_door() -> String:
	for building in buildings:
		var footprint: Rect2 = building.footprint
		var door := Vector2(footprint.get_center().x, footprint.end.y)
		if cat.body.position.distance_to(door) <= DOOR_REACH + footprint.size.x * 0.25:
			return building.name
	return ""


## Marks a building restored, as she sees it: the village keeps the record.
func show_restored(building_name: String) -> void:
	for building in buildings:
		if building.name == building_name:
			building.restored = true


## Walks her to a spot on her own, for a cutscene.
func walk_to(spot: Vector2) -> void:
	walking_to = spot


func walking() -> bool:
	return walking_to.is_finite()


## Whether she's walked out onto the path to the clearing: the run starts.
func leaving() -> bool:
	var at := cat.body.position
	return at.x >= EXIT_FROM and at.y > PATH_TOP and at.y < PATH_BOTTOM


func step(delta: float) -> void:
	time += delta
	if walking():
		var toward := walking_to - cat.body.position
		if toward.length() < 0.05:
			walking_to = Vector2.INF
			cat.steering = Vector2.ZERO
		else:
			cat.steering = toward.normalized() * minf(stroll_speed / Cat.SPEED, 1.0)
	_move(cat, cat.steering * Cat.SPEED, delta)
	for index in villagers.size():
		var villager := villagers[index]
		var toward := _amble_to[index] - villager.body.position
		if toward.length() < 0.2:
			# A moment's pause, then somewhere else.
			if random.randf() < delta * 0.5:
				_amble_to[index] = _somewhere_in_the_village()
			_move(villager, Vector2.ZERO, delta)
		else:
			villager.steering = toward.normalized()
			_move(villager, toward.normalized() * AMBLE_SPEED, delta)


## Moves a cat at a pace, facing the way it goes, kept out of the buildings and on the ground
## there is: the path, in the forest, and the whole village beyond it.
func _move(walker: Cat, velocity: Vector2, delta: float) -> void:
	walker.body.velocity = velocity
	if velocity.length_squared() > 0.0001:
		walker.facing = velocity.normalized()
	var next := walker.body.position + velocity * delta
	for building in buildings:
		var footprint: Rect2 = (building.footprint as Rect2).grow(walker.body.radius)
		if footprint.has_point(next):
			next = _push_out(next, footprint)
	var top := PATH_TOP if next.x < VILLAGE_FROM else 0.4
	var bottom := PATH_BOTTOM if next.x < VILLAGE_FROM else SIZE.y - 0.4
	# Off the right edge only along the path: that's the way out.
	var right := SIZE.x if next.y > PATH_TOP and next.y < PATH_BOTTOM else SIZE.x - 0.4
	walker.body.position = Vector2(clampf(next.x, 0.4, right), clampf(next.y, top, bottom))


func _push_out(point: Vector2, box: Rect2) -> Vector2:
	var distances := [point.x - box.position.x, box.end.x - point.x, point.y - box.position.y, box.end.y - point.y]
	var nearest: int = distances.find(distances.min())
	match nearest:
		0: return Vector2(box.position.x, point.y)
		1: return Vector2(box.end.x, point.y)
		2: return Vector2(point.x, box.position.y)
	return Vector2(point.x, box.end.y)


func _somewhere_in_the_village() -> Vector2:
	for attempt in 20:
		var spot := Vector2(random.randf_range(VILLAGE_FROM + 1.0, SIZE.x - 2.0), random.randf_range(1.0, SIZE.y - 1.0))
		if not buildings.any(func(building: Dictionary) -> bool: return (building.footprint as Rect2).grow(0.3).has_point(spot)):
			return spot
	return HOME_SPOT
