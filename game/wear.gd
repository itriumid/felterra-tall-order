class_name Wear
extends RefCounted
## What a fight leaves on the giants and the machines: each hit's mark, where it landed and in the
## kind of what landed it. Rounds punch holes, blades cut, blunt weapons dent, fire and blasts
## scorch, and bolts, arrows, darts and nails stay in. A machine's marks sit on its hull where it
## was hit from, and turn with it; a giant's are on his vest. Only the view keeps them, from the
## hits it's handed: nothing is sent online for them, and a guest's view marks its own.

## The most marks anything carries: past that, a new one takes an old one's place.
const MOST := 40
## Fire burns in ticks: it scorches again only this often, in seconds, or it'd blacken a giant
## in a moment.
const BURN_EVERY := 0.6

## A blunt blade dents; every other blade cuts.
const BLUNT: Array[String] = ["nunchaku", "rattan_staff", "hammer"]
const SHAFTS: Array[String] = ["crossbow", "panah", "sumpit"]
## What hits are, by what they're credited to, when it isn't a weapon's own.
const BY := {
	"fire": "scorch", "slash": "gash", "rolling_slash": "gash", "ankles": "gash", "riposte": "gash",
	"pounce": "gash", "cub": "dent", "log": "dent", "jaws": "dent", "boot": "dent", "mines": "blast",
	"petasan": "blast", "spikes": "gash", "nail": "nail", "caltrop": "nail",
}

## Marks, by what carries them, each {along, across, up, face, kind, angle} on a machine (in its
## own frame: along its facing, across it, and up from the ground), or {along, off, kind, angle}
## on a giant (up his vest from hip to shoulder, and across it in pixels).
var marks := {}
var _burned_at := {}


## What a hit leaves, or "" if nothing.
static func kind_of(event: Dictionary) -> String:
	var by: String = event.get("by", "")
	var source: String = event.get("source", "")
	if by == "blade":
		return "dent" if source in BLUNT else "gash"
	if by == "round":
		if source == "nail_gun":
			return "nail"
		if source in SHAFTS:
			return "shaft"
		if source == "ketapel":
			return "dent"
		if source == "flare_gun":
			return "scorch"
		return "hole"
	if BY.has(by):
		return BY[by]
	# A blast is credited to the weapon that burst: the grenade, the oil, the cannon.
	if Upgrades.WEAPON_NAMES.has(by) or by == "meriam_bambu":
		return "blast"
	return ""


## Each hit on a giant or a machine, marked on it.
func take(events: Array[Dictionary], arena: Arena, clock: float) -> void:
	for event in events:
		if not event.get("giant", false):
			continue
		var kind := kind_of(event)
		if kind.is_empty():
			continue
		var target := Wear.target_of(event, arena)
		if target == null:
			continue
		if kind == "scorch" and clock - float(_burned_at.get(target, -BURN_EVERY)) < BURN_EVERY:
			continue
		if kind == "scorch":
			_burned_at[target] = clock
		var direction: Vector2 = event.get("direction", Vector2.ZERO)
		var mark := _on_machine(target, direction, kind) if target is Machine else _on_giant(direction, kind)
		_add(target, mark)


## What goes down is marked all over, as it burns out: soot across the top of a machine.
func burn_out(machine: Machine) -> void:
	var hull := Wear.hull(machine)
	for index in 10:
		_add(machine, {"along": hull.along + randf_range(-0.45, 0.45) * hull.length, "across": randf_range(-0.4, 0.4) * hull.width,
			"up": hull.top, "face": Vector2.ZERO, "kind": "scorch", "angle": randf() * TAU})


## Forgets what's no longer in the fight.
func keep_only(arena: Arena) -> void:
	for target: Object in marks.keys():
		if not (target in arena.machines or target in arena.giants):
			marks.erase(target)
			_burned_at.erase(target)


func of(target: Object) -> Array:
	return marks.get(target, [])


## Where a machine's hull is, in its own frame, for its marks to sit on: {along (its middle),
## length, width, bottom, top}, above its body's own height (a helicopter's in the air).
static func hull(machine: Machine) -> Dictionary:
	if machine is Helicopter:
		return {"along": 0.2, "length": 2.6, "width": 1.2, "bottom": 0.25, "top": 1.2}
	if machine is LoggingTruck:
		return {"along": 1.6, "length": 1.3, "width": 1.6, "bottom": 0.45, "top": 1.85}
	if machine is LogLoader or machine is Bulldozer:
		return {"along": 0.0, "length": machine.length * 0.85, "width": machine.width * 0.85, "bottom": 0.55, "top": 1.05}
	return {"along": 0.0, "length": 2.6, "width": 1.7, "bottom": 0.55, "top": 1.05}


func _add(target: Object, mark: Dictionary) -> void:
	if not marks.has(target):
		marks[target] = []
	var list: Array = marks[target]
	if list.size() < MOST:
		list.append(mark)
	else:
		list[randi() % MOST] = mark


## On the face of the hull turned toward where the hit came from; a blast or fire, or now and
## then anything, on the top.
func _on_machine(machine: Machine, direction: Vector2, kind: String) -> Dictionary:
	var hull := Wear.hull(machine)
	var mark := {"kind": kind, "angle": randf() * TAU}
	var from := -direction
	if from.length_squared() < 0.0001 or kind in ["scorch", "blast"] or randf() < 0.25:
		mark.merge({"along": hull.along + randf_range(-0.4, 0.4) * hull.length, "across": randf_range(-0.4, 0.4) * hull.width,
			"up": hull.top, "face": Vector2.ZERO})
		return mark
	var forward := machine.facing()
	var along := from.dot(forward)
	var across := from.dot(forward.orthogonal())
	var up := randf_range(hull.bottom + 0.05, hull.top - 0.05)
	if absf(along) > absf(across):
		mark.merge({"along": hull.along + signf(along) * hull.length * 0.5, "across": randf_range(-0.4, 0.4) * hull.width,
			"up": up, "face": Vector2(signf(along), 0.0)})
	else:
		mark.merge({"along": hull.along + randf_range(-0.4, 0.4) * hull.length, "across": signf(across) * hull.width * 0.5,
			"up": up, "face": Vector2(0.0, signf(across))})
	return mark


## Somewhere on his vest: the hits come from all round him, and the vest's the size it is.
func _on_giant(direction: Vector2, kind: String) -> Dictionary:
	return {"along": randf_range(0.1, 0.9), "off": randf_range(-5.0, 5.0), "kind": kind, "angle": randf() * TAU,
		"from": -direction}


## Whether a mark on a machine's face shows: on top, or on a face turned toward the viewer.
static func shows(machine: Machine, mark: Dictionary) -> bool:
	var face: Vector2 = mark.face
	if face == Vector2.ZERO:
		return true
	var forward := machine.facing()
	return (forward * face.x + forward.orthogonal() * face.y).y > 0.1


## What a hit landed on, as the hit names it: the machine (its joint's hits are the machine's), or
## the giant. Never found by where it stands: a frame can step the world more than once, and by
## the time it's drawn a machine has moved on from where it was hit.
static func target_of(event: Dictionary, _arena: Arena) -> Object:
	var on: Variant = event.get("on")
	return on if on is Machine or on is Giant else null
