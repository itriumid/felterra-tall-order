class_name VillageMap
extends RefCounted
## The cats' village at the forest's edge, as a place to walk: a forest path coming in from the
## left, the village itself, and on its far side the path out to the clearing. Everything
## between runs happens here. The cats he's rescued live in it.
##
## When the story starts, the company's machines have already been through: every building is a
## ruin. Bringing them back, one by one, is how the village grows, and each opens what it holds.
## Runs headless at the arena's step, in meters and seconds.

## The whole of it, in meters: the forest path to the left of VILLAGE_FROM, the village to the
## right, two screens tall. The path runs along the middle, between PATH_TOP and PATH_BOTTOM, and
## on through the village as its road; the houses stand off it, up and down their own footpaths.
const SIZE := Vector2(37.0, 18.0)
const VILLAGE_FROM := 12.0
const PATH_TOP := 7.6
const PATH_BOTTOM := 10.4
## Where he stands on the title, on the forest path, and where he walks in to, in the village.
const TITLE_SPOT := Vector2(5.0, 9.0)
const HOME_SPOT := Vector2(19.0, 9.2)
## Where the Elder meets him, the first time he walks in: just inside the village.
const MEETING_SPOT := Vector2(14.6, 9.0)
## The exit: walking out through the gate, on the path, starts a run: he's seen off, and walks on
## off the village's right edge, into the forest. Off the path, the edge is trees. Coming home
## from a run, he walks back in from there.
const EXIT_FROM := 35.6
const RETURN_SPOT := Vector2(33.5, 9.0)
## Where he walks on to as he's seen off, past the edge and out of sight; where a villager with a
## word for him on the way stands, beside the path inside the gate; and how fast whoever has that
## word trots over.
const OFF_INTO_THE_FOREST := Vector2(38.6, 9.0)
const SEE_OFF_SPOT := Vector2(33.0, 11.0)
const TROT_SPEED := 1.8
## How close to a door he has to be to use it, past a share of the building's width.
const DOOR_REACH := 0.7
## How fast he walks in a cutscene with a story to tell over it, how fast with none (his own
## full pace: nothing to wait for), and how fast the villagers amble.
const STROLL_SPEED := 1.4
const WALK_IN_SPEED := Cat.SPEED
const AMBLE_SPEED := 0.7
## Where the Elder keeps, in the square before the longhouse; where he stands to see him off, at
## the gate; and how far from him he stops when he walks out to meet him.
const ELDER_SPOT := Vector2(18.0, 4.2)
const ELDER_AT_THE_GATE := Vector2(34.6, 7.2)
const ELDER_MEETS := 1.0
## How far behind Tompel Jogiboy keeps, and how fast he trots to catch up.
const JOGI_HEEL := 0.9
const JOGI_SPEED := 3.0
## How far from his spot he lets Tompel get before setting off, and how close he comes to settle.
const JOGI_SET_OFF := 1.2
const JOGI_SETTLE := 0.25
## His play: what he can get up to, how long he stands before he's bored (from, to), how fast he
## plays, how wide and fast his zoomies go round Tompel, and how long a sniff and a dig take.
const JOGI_PLAYS: Array[String] = ["zoomies", "chase", "dig"]
const JOGI_BORED := Vector2(2.5, 6.0)
const JOGI_PLAY_SPEED := 4.5
const ZOOMIES_RADIUS := 1.4
const ZOOMIES_TURN := 3.2
const JOGI_SNIFF_TIME := 0.9
const JOGI_DIG_TIME := 1.8
## How far outside a wall something pushed out of it ends up, in meters.
const EDGE_GAP := 0.001
## The buildings, by name: his home, the Elder's longhouse, the smithy, the huts, and the
## watchtower, the market and the healer's hut. Each is a ruin until
## it's restored, and stays solid either way: a ruin is still in the way.
## The longhouse heads the village square, and the smithy stands at its side.
const LONGHOUSE := Rect2(16.8, 2.0, 5.0, 1.6)
const SMITHY := Rect2(23.6, 4.6, 3.2, 1.5)
const SQUARE := Rect2(16.4, 3.6, 6.4, 4.0)
## The map of the forest, carved on a board at the gate: where the next run goes. It was never a
## ruin.
const BOARD := Rect2(34.3, 10.9, 1.2, 0.45)
## What the cats freed in the story bring back: Jingga's watchtower, Kopi and Susu's market stall
## across the road from the square, and Bu Jamu's healer's hut by the gate.
const WATCHTOWER := Rect2(31.0, 3.0, 1.4, 1.2)
const MARKET := Rect2(20.0, 11.4, 2.4, 1.2)
const HEALER := Rect2(32.8, 4.8, 2.0, 1.3)
## His own home: the first house in from the forest.
const HOME := Rect2(12.6, 4.6, 2.0, 1.3)
## The huts, each at its own depth off the road: the weaver's first, by the way in.
const HUTS: Array[Rect2] = [
	Rect2(13.8, 12.0, 2.0, 1.4), Rect2(17.2, 14.4, 2.0, 1.4), Rect2(24.0, 12.4, 2.0, 1.4),
	Rect2(27.6, 14.8, 2.0, 1.4), Rect2(28.4, 1.6, 2.0, 1.3),
]
## What makes it a village and not a row of huts, each in the way where it stands, but for
## what's flat on the ground or overhead: the well in the square and a bench by it, the gardens
## behind the houses, the woodpile by the smithy, a washing line, rice drying on its mat, and the
## coconut palms.
const PROPS: Array[Dictionary] = [
	{"kind": "well", "footprint": Rect2(18.9, 5.2, 0.9, 0.7)},
	{"kind": "bench", "footprint": Rect2(21.0, 6.2, 1.2, 0.35)},
	{"kind": "garden", "footprint": Rect2(12.4, 2.2, 2.6, 1.6)},
	{"kind": "garden", "footprint": Rect2(13.4, 14.8, 2.6, 1.6)},
	{"kind": "garden", "footprint": Rect2(30.4, 15.0, 2.4, 1.6)},
	{"kind": "woodpile", "footprint": Rect2(27.1, 5.4, 1.1, 0.5)},
	{"kind": "washing", "footprint": Rect2(21.0, 15.0, 2.6, 0.1), "flat": true},
	{"kind": "mat", "footprint": Rect2(30.0, 12.0, 1.8, 1.0), "flat": true},
	{"kind": "palm", "footprint": Rect2(15.5, 0.9, 0.3, 0.3)},
	{"kind": "palm", "footprint": Rect2(23.0, 1.6, 0.3, 0.3)},
	{"kind": "palm", "footprint": Rect2(16.6, 11.4, 0.3, 0.3)},
	{"kind": "palm", "footprint": Rect2(26.8, 16.4, 0.3, 0.3)},
	{"kind": "palm", "footprint": Rect2(32.6, 12.8, 0.3, 0.3)},
]

var cat := Cat.new()
## The Elder, who has always been here, ruin or no ruin: gray, in his batik headcloth. He keeps by
## the longhouse, walks out to meet him when there's something to say, and comes to the gate to see
## him off. Where he's walking to, or nowhere (INF).
var elder := Cat.new()
var elder_to := Vector2.INF
## Jogiboy, who lives next door to the Elder and has decided Tompel is his friend: in Felterra
## everyone is equal, a dog as much as anyone. He goes everywhere Tompel goes in the village,
## trotting after him, and stands by him when he stops.
var jogi := Cat.new()
var _jogi_trotting := false
## What Jogiboy's playing at ("" for nothing: following Tompel), and whether he's digging now; how
## long he's stood, and how long before he's bored of it; and where his play has got to.
var jogi_playing := ""
var jogi_digging := false
var _jogi_idle := 0.0
var _jogi_bored_after := 3.0
var _jogi_play_for := 0.0
var _jogi_dug_for := 0.0
var _jogi_lap := 0.0
var _jogi_spot := Vector2.ZERO
## The cats he's rescued, ambling about: each a Cat in its own coat, with where it's going.
var villagers: Array[Cat] = []
var names: Array[String] = []
var buildings: Array[Dictionary] = []
var random := RandomNumberGenerator.new()
var time := 0.0
## Where he's being walked to in a cutscene, or nowhere (INF): while he is, steering is ignored.
## And how fast: slower while a story is told over the walk.
var walking_to := Vector2.INF
var stroll_speed := STROLL_SPEED
## Whether he's being seen off, walking out of the village: whoever has a word for him on the way
## comes to the gate, and stays there, watching him go.
var seeing_off := false
var _amble_to: Array[Vector2] = []
## The villagers called over to say something, by index: they stay put until let go.
var _staying := {}
var _solids: Array[Rect2] = []
## The way to where each villager is going, around everything, and where it was found for; the
## Elder's the same; and the ground they're found over, walls and all.
var _ways: Array[FlowField] = []
var _ways_for: Array[Vector2] = []
var _elder_way: FlowField
var _elder_way_for := Vector2.INF
var _ground_plan: FlowField
## How long each villager has gone without getting nearer to where it's going, and the nearest
## it's been: one that can't get there goes somewhere else.
var _held_up: Array[float] = []
var _nearest: Array[float] = []
const GIVES_UP := 3.0


## Every building's name, in the order they stand.
static func building_names() -> Array[String]:
	var names_in_order: Array[String] = ["home", "longhouse", "smithy"]
	for index in HUTS.size():
		names_in_order.append("hut_%d" % index)
	names_in_order.append_array(["watchtower", "market", "healer"])
	return names_in_order


func _init(rescued: Array = [], restored: Array = [], seed_value := 39) -> void:
	random.seed = seed_value
	cat.weapons.clear()
	cat.body.position = TITLE_SPOT
	elder.weapons.clear()
	elder.coat = "gray"
	elder.gear = {"head": "batik_headcloth"}
	elder.body.position = ELDER_SPOT
	elder.facing = Vector2.DOWN
	jogi.weapons.clear()
	jogi.body.position = ELDER_SPOT + Vector2(-1.2, 0.5)
	buildings.append({"name": "home", "kind": "home", "footprint": HOME, "paint": 5})
	buildings.append({"name": "longhouse", "kind": "longhouse", "footprint": LONGHOUSE})
	buildings.append({"name": "smithy", "kind": "smithy", "footprint": SMITHY})
	for index in HUTS.size():
		buildings.append({"name": "hut_%d" % index, "kind": "hut", "footprint": HUTS[index], "paint": index})
	buildings.append({"name": "watchtower", "kind": "watchtower", "footprint": WATCHTOWER})
	buildings.append({"name": "market", "kind": "market", "footprint": MARKET})
	buildings.append({"name": "healer", "kind": "healer", "footprint": HEALER, "paint": 5})
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


## The building he's at the door of, by name, or "" if he isn't at one: close to the middle of
## the side facing the road, where its door is.
func at_door() -> String:
	for building in buildings:
		var footprint: Rect2 = building.footprint
		if cat.body.position.distance_to(door_of(footprint)) <= DOOR_REACH + footprint.size.x * 0.25:
			return building.name
	return ""


## Whether a building stands below the road, its door on its far side so it faces the road like
## the rest; but the map board, a sign, faces the village.
static func faces_up(footprint: Rect2) -> bool:
	return footprint.position.y > PATH_BOTTOM and footprint != BOARD


## The middle of a building's side that faces the road: its door.
static func door_of(footprint: Rect2) -> Vector2:
	return Vector2(footprint.get_center().x, footprint.position.y if faces_up(footprint) else footprint.end.y)


## Where he stands at a building's door, a step out from it.
static func door_step(footprint: Rect2) -> Vector2:
	return door_of(footprint) + Vector2(0.0, -0.45 if faces_up(footprint) else 0.45)


## The ground worn bare by feet: the square, and a footpath from every door to the road.
static func worn_ground() -> Array[Rect2]:
	var worn: Array[Rect2] = [SQUARE]
	var footprints: Array[Rect2] = [HOME, LONGHOUSE, SMITHY, WATCHTOWER, MARKET, HEALER]
	footprints.append_array(HUTS)
	for footprint in footprints:
		var door := door_of(footprint)
		var road := PATH_BOTTOM if faces_up(footprint) else PATH_TOP
		worn.append(Rect2(door.x - 0.45, minf(door.y, road), 0.9, absf(road - door.y)))
	return worn


## Everything in the way: the buildings, and the props that aren't flat. Nothing moves once
## built, so it's gathered once.
func _solid() -> Array[Rect2]:
	if _solids.is_empty():
		for building in buildings:
			_solids.append(building.footprint)
		for prop: Dictionary in PROPS:
			if not prop.get("flat", false):
				_solids.append(prop.footprint)
	return _solids


## Marks a building restored, as he sees it: the village keeps the record.
func show_restored(building_name: String) -> void:
	for building in buildings:
		if building.name == building_name:
			building.restored = true


## Walks him to a spot on his own, for a cutscene.
func walk_to(spot: Vector2) -> void:
	walking_to = spot


func walking() -> bool:
	return walking_to.is_finite()


## He walks on out of the village. Whoever has a word for him on the way, by who they are (see
## speaker_named), comes to the gate to say it; everyone else goes on with their day.
func see_off(speakers: Array = []) -> void:
	seeing_off = true
	if "elder" in speakers:
		elder_to = ELDER_AT_THE_GATE
	var others := 0
	for who in speakers:
		var index := names.find(who)
		if index >= 0:
			_amble_to[index] = SEE_OFF_SPOT + Vector2(-0.8 * others, 0.3 * (others % 2))
			_staying[index] = true
			others += 1
	walk_to(OFF_INTO_THE_FOREST)


## The Elder walks out to meet him where he's going, stopping a step short of it and facing him.
func elder_meets(spot: Vector2) -> void:
	elder_to = spot + (ELDER_SPOT - spot).normalized() * ELDER_MEETS


## A villager with something to say comes over to where he'll be, and stays there until let go.
func call_over(who: String, spot: Vector2) -> void:
	var index := names.find(who)
	if index < 0:
		return
	_amble_to[index] = spot + Vector2(1.0, -0.6)
	_staying[index] = true


## Everyone who was called over goes about their day again.
func let_go() -> void:
	for index in _staying:
		_amble_to[index] = _somewhere_in_the_village()
	_staying.clear()


## The Elder goes back to his place by the longhouse.
func elder_home() -> void:
	elder_to = ELDER_SPOT


## Who's speaking a line, by who they are: "elder", "tompel", "jogiboy", or a villager's name. Nobody, if
## they aren't in the village.
func speaker_named(who: String) -> Cat:
	match who:
		"elder": return elder
		"tompel": return cat
		"jogiboy": return jogi
	var index := names.find(who)
	return villagers[index] if index >= 0 else null


## Whether he's out of sight past the village's edge, seen off.
func gone() -> bool:
	return cat.body.position.x >= SIZE.x + 1.0


## Whether he's walked out through the gate onto the path to the forest: he's seen off.
func leaving() -> bool:
	var at := cat.body.position
	return at.x >= EXIT_FROM and at.y > PATH_TOP and at.y < PATH_BOTTOM


func step(delta: float) -> void:
	time += delta
	_step_elder(delta)
	_step_jogi(delta)
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
			if _staying.has(index):
				# At the gate watching him go, or by him, talking.
				villager.facing = (cat.body.position - villager.body.position).normalized()
			elif random.randf() < delta * 0.5:
				_amble_to[index] = _somewhere_in_the_village()
			_move(villager, Vector2.ZERO, delta)
		else:
			# The way round whatever's between, not straight into it.
			while _ways.size() <= index:
				_ways.append(null)
				_ways_for.append(Vector2.INF)
				_held_up.append(0.0)
				_nearest.append(INF)
			if _ways_for[index] != _amble_to[index]:
				_ways[index] = _way_to(_amble_to[index])
				_ways_for[index] = _amble_to[index]
				_nearest[index] = INF
			if toward.length() < _nearest[index] - 0.05:
				_held_up[index] = 0.0
				_nearest[index] = toward.length()
			else:
				_held_up[index] += delta
			if _held_up[index] >= GIVES_UP and not _staying.has(index):
				# It can't get there from here: somewhere else, then.
				_held_up[index] = 0.0
				_amble_to[index] = _somewhere_in_the_village()
			var going := _ways[index].way(villager.body.position, _amble_to[index])
			villager.steering = going
			_move(villager, going * (TROT_SPEED if seeing_off and _staying.has(index) else AMBLE_SPEED), delta)


## The Elder walks where he's going, at a trot to the gate and an old cat's pace otherwise; there,
## he turns to him.
func _step_elder(delta: float) -> void:
	var toward := (elder_to - elder.body.position) if elder_to.is_finite() else Vector2.ZERO
	if toward.length() < 0.05:
		elder_to = Vector2.INF
		_move(elder, Vector2.ZERO, delta)
		if elder.body.position.distance_to(cat.body.position) < 4.0:
			elder.facing = (cat.body.position - elder.body.position).normalized()
		return
	if _elder_way_for != elder_to:
		_elder_way = _way_to(elder_to)
		_elder_way_for = elder_to
	_move(elder, _elder_way.way(elder.body.position, elder_to) * (TROT_SPEED if seeing_off else AMBLE_SPEED * 1.6), delta)


## Jogiboy follows Tompel at his heels, a step behind and to the side. While Tompel walks, he keeps
## pace with him, smoothly, catching up a little faster when he's fallen behind; when Tompel stops,
## he comes up and stands by him, and only sets off again once Tompel has got well ahead. Not
## fussing at every step keeps him from stopping and starting. Seeing him off, he waits at the gate.
func _step_jogi(delta: float) -> void:
	var goal := cat.body.position - cat.facing * JOGI_HEEL + cat.facing.orthogonal() * 0.35
	if seeing_off:
		goal = Vector2(EXIT_FROM - 0.6, PATH_BOTTOM - 0.4)
	var toward := goal - jogi.body.position
	var walking := cat.body.velocity.length() > 0.2 and not seeing_off
	if walking or seeing_off:
		jogi_playing = ""
		jogi_digging = false
		_jogi_idle = 0.0
	if walking:
		# Keeping pace: going the way Tompel goes, as fast, and closing on his spot a little more
		# for every step behind, never past a trot.
		_jogi_trotting = true
		_move(jogi, (cat.body.velocity + toward * 2.0).limit_length(JOGI_SPEED), delta)
		return
	if not jogi_playing.is_empty():
		_jogi_play(delta)
		return
	if _jogi_trotting and toward.length() < JOGI_SETTLE:
		_jogi_trotting = false
	elif not _jogi_trotting and toward.length() > JOGI_SET_OFF:
		_jogi_trotting = true
	if not _jogi_trotting:
		_move(jogi, Vector2.ZERO, delta)
		# Standing, he turns to Tompel, once he's clearly to one side.
		var to_him := cat.body.position - jogi.body.position
		if absf(to_him.x) > 0.4:
			jogi.facing = Vector2(signf(to_him.x), 0.0)
		# Left standing a while, he finds something to play at.
		_jogi_idle += delta
		if _jogi_idle >= _jogi_bored_after and not seeing_off:
			_start_playing()
		return
	# Coming up to him: slowing as he arrives, not stopping dead.
	_move(jogi, toward.normalized() * minf(JOGI_SPEED, maxf(toward.length() * 3.0, 0.8)), delta)


## Bored of standing, Jogiboy plays: zoomies round Tompel, a dash after something only he can see
## and a sniff at it, or a dig a little way off.
func _start_playing() -> void:
	jogi_playing = JOGI_PLAYS[random.randi_range(0, JOGI_PLAYS.size() - 1)]
	_jogi_idle = 0.0
	_jogi_bored_after = random.randf_range(JOGI_BORED.x, JOGI_BORED.y)
	_jogi_play_for = 0.0
	_jogi_lap = (jogi.body.position - cat.body.position).angle()
	var away := Vector2.from_angle(random.randf() * TAU) * random.randf_range(1.2, 2.6)
	_jogi_spot = (cat.body.position + away).clamp(Vector2(VILLAGE_FROM + 0.6, 0.8), SIZE - Vector2(0.8, 0.8))


func _jogi_play(delta: float) -> void:
	_jogi_play_for += delta
	match jogi_playing:
		"zoomies":
			# Round and round him, flat out, twice.
			_jogi_lap += ZOOMIES_TURN * delta
			var round_him := cat.body.position + Vector2.from_angle(_jogi_lap) * ZOOMIES_RADIUS
			_move(jogi, (round_him - jogi.body.position).limit_length(1.0) * JOGI_PLAY_SPEED, delta)
			if _jogi_play_for >= TAU * 2.0 / ZOOMIES_TURN:
				jogi_playing = ""
		"chase", "dig":
			var toward := _jogi_spot - jogi.body.position
			if toward.length() > 0.2 and _jogi_play_for < 3.0:
				_move(jogi, toward.normalized() * JOGI_PLAY_SPEED, delta)
				_jogi_dug_for = 0.0
				return
			# There: a sniff, or a dig, then back to Tompel.
			_move(jogi, Vector2.ZERO, delta)
			_jogi_dug_for += delta
			jogi_digging = jogi_playing == "dig"
			if _jogi_dug_for >= (JOGI_DIG_TIME if jogi_playing == "dig" else JOGI_SNIFF_TIME):
				jogi_playing = ""
				jogi_digging = false


## Moves a cat at a pace, facing the way it goes, kept out of the buildings and on the ground
## there is: the path, in the forest, and the whole village beyond it.
func _move(walker: Cat, velocity: Vector2, delta: float) -> void:
	walker.body.velocity = velocity
	if velocity.length_squared() > 0.0001:
		walker.facing = velocity.normalized()
	var next := walker.body.position + velocity * delta
	for solid in _solid():
		var footprint := solid.grow(walker.body.radius)
		if footprint.has_point(next):
			# Against a wall, he slides along it, the way that's still open; failing that, out.
			if walker != cat:
				# A villager has its way round already: it keeps what part of its going still
				# fits, at its full pace, or it would creep along the wall.
				var pace := velocity.length()
				var first := Vector2(signf(velocity.x) * pace, 0.0) if absf(velocity.x) >= absf(velocity.y) else Vector2(0.0, signf(velocity.y) * pace)
				var second := Vector2(0.0, signf(velocity.y) * pace) if first.x != 0.0 else Vector2(signf(velocity.x) * pace, 0.0)
				if first != Vector2.ZERO and not footprint.has_point(walker.body.position + first * delta):
					next = walker.body.position + first * delta
				elif second != Vector2.ZERO and not footprint.has_point(walker.body.position + second * delta):
					next = walker.body.position + second * delta
				else:
					next = _push_out(next, footprint)
				continue
			var across := walker.body.position + Vector2(velocity.x, 0.0) * delta
			var along := walker.body.position + Vector2(0.0, velocity.y) * delta
			if not footprint.has_point(along) and absf(velocity.y) > 0.0001:
				next = along
			elif not footprint.has_point(across) and absf(velocity.x) > 0.0001:
				next = across
			else:
				next = _push_out(next, footprint)
	var top := PATH_TOP if next.x < VILLAGE_FROM else 0.4
	var bottom := PATH_BOTTOM if next.x < VILLAGE_FROM else SIZE.y - 0.4
	# Off the right edge only along the path: that's the way out. Seen off, he walks on out of
	# sight.
	var right := SIZE.x if next.y > PATH_TOP and next.y < PATH_BOTTOM else SIZE.x - 0.4
	if walker == cat and seeing_off:
		right = OFF_INTO_THE_FOREST.x
	walker.body.position = Vector2(clampf(next.x, 0.4, right), clampf(next.y, top, bottom))


## The way to a spot from anywhere in the village, around the buildings, the props, and the forest
## either side of the path.
func _way_to(spot: Vector2) -> FlowField:
	var field := FlowField.sharing(_plan())
	var toward: Array[Vector2] = [spot]
	field.toward(toward)
	return field


## The village's ground, walls and all, for the ways over it: found once.
func _plan() -> FlowField:
	if _ground_plan == null:
		var standing: Array[Obstacle] = []
		for footprint in _solid():
			standing.append(Obstacle.from({"kind": "wall", "rect": footprint}))
		standing.append(Obstacle.from({"kind": "wall", "rect": Rect2(-1.0, -1.0, VILLAGE_FROM + 1.0, PATH_TOP + 1.0)}))
		standing.append(Obstacle.from({"kind": "wall", "rect": Rect2(-1.0, PATH_BOTTOM, VILLAGE_FROM + 1.0, SIZE.y - PATH_BOTTOM + 1.0)}))
		_ground_plan = FlowField.new(SIZE, standing, Cat.RADIUS)
	return _ground_plan


func _push_out(point: Vector2, box: Rect2) -> Vector2:
	var distances := [point.x - box.position.x, box.end.x - point.x, point.y - box.position.y, box.end.y - point.y]
	var nearest: int = distances.find(distances.min())
	# Just past the edge, not on it: on it still counts as inside, and nothing could slide.
	match nearest:
		0: return Vector2(box.position.x - EDGE_GAP, point.y)
		1: return Vector2(box.end.x + EDGE_GAP, point.y)
		2: return Vector2(point.x, box.position.y - EDGE_GAP)
	return Vector2(point.x, box.end.y + EDGE_GAP)


## Somewhere in the open to amble to: not in a building, and not wedged in a gap a cat would
## have to squeeze into sideways.
func _somewhere_in_the_village() -> Vector2:
	for attempt in 20:
		var spot := Vector2(random.randf_range(VILLAGE_FROM + 1.0, SIZE.x - 2.0), random.randf_range(1.0, SIZE.y - 1.0))
		if not _plan().blocked(spot):
			return spot
	return HOME_SPOT
