class_name Snapshot
extends RefCounted
## Playing online, the host runs the world and sends it to each guest about 20 times a second:
## everything that moves or changes, compressed. A guest never steps the world; it puts each
## snapshot into its own arena, laid out from the same area and seed, and draws that.
##
## Everything is sent by its public script variables, the way the views read them, each object
## under the host's id for it, so the guest updates the same objects in place: a walk cycle keeps
## counting, a muzzle flash knows a round was fired. A field goes only when it's changed since the
## last snapshot that guest was sent; snapshots go in order and are never lost, so each guest
## always has what the next one changes. The horde and the fallen, hundreds at a time, go packed:
## only what's drawn.
##
## Take the world once a tick with `take`, then hand it to each guest's own Sender; a guest puts
## what arrives into its arena with a Receiver.

## What the guest lays out for itself from the area and its seed, or never needs: where things
## stand, the host's dice and its plan, and what's sent packed or on its own.
const ARENA_SKIPS: Array[String] = ["obstacles", "random", "plan", "area", "size", "spawning", "events", "creatures", "fallen"]
## The horde, packed: each creature's id and kind, then these, as whole centimeters (or hundredths)
## in 16 bits each.
const CREATURE_FIELDS := 9
## The fallen, packed the same way: where each lies or flies.
const FALLEN_FIELDS := 6
const SCALE := 100.0


## The world as it stands this tick, every field of every object, before it's cut down to what
## each guest hasn't had.
static func take(arena: Arena, events: Array[Dictionary]) -> Dictionary:
	var objects := {}
	var fields := {}
	for property in arena.get_property_list():
		var name: String = property.name
		if not property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE or name.begins_with("_") or name in ARENA_SKIPS:
			continue
		fields[name] = _encode(arena.get(name), objects)
	return {
		"arena": fields, "objects": objects, "creatures": _pack_creatures(arena.creatures),
		"fallen": _pack_fallen(arena.fallen), "events": _encode(events, objects),
	}


## An object as {"@": id}, its fields set down in `objects` under that id with its script; arrays
## and tables as theirs; anything else as it is.
static func _encode(value: Variant, objects: Dictionary) -> Variant:
	if value is Array:
		var list := []
		for item: Variant in value:
			list.append(_encode(item, objects))
		return list
	if value is Dictionary:
		var table := {}
		for key: Variant in value:
			table[key] = _encode(value[key], objects)
		return table
	if not value is Object:
		return value
	# Only the simulation's own objects: an engine object (its dice, say) is the host's alone.
	if value == null or not value is RefCounted or (value as Object).get_script() == null:
		return null
	var id: int = (value as Object).get_instance_id()
	if not objects.has(id):
		var fields := {"#": ((value as Object).get_script() as Script).resource_path}
		objects[id] = fields
		for property in (value as Object).get_property_list():
			var name: String = property.name
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and not name.begins_with("_"):
				fields[name] = _encode((value as Object).get(name), objects)
	return {"@": id}


## One guest's side of the sending: what they were last sent, so the next sends only what's changed.
class Sender:
	var _arena := {}
	var _objects := {}
	var _fallen := PackedByteArray()
	var _fallen_kinds := PackedStringArray()

	## What's changed for this guest since their last, packed to send.
	func delta(world: Dictionary) -> PackedByteArray:
		var arena := {}
		for name: String in world.arena:
			if not _arena.has(name) or _arena[name] != world.arena[name]:
				arena[name] = world.arena[name]
		var objects := {}
		for id: int in world.objects:
			var now: Dictionary = world.objects[id]
			var was: Dictionary = _objects.get(id, {})
			var changed := {}
			for name: String in now:
				if name == "#" and not was.is_empty():
					continue
				if not was.has(name) or was[name] != now[name]:
					changed[name] = now[name]
			if not changed.is_empty():
				objects[id] = changed
		var gone: Array[int] = []
		for id: int in _objects:
			if not world.objects.has(id):
				gone.append(id)
		# The fallen lying still don't change: only those that have since the last.
		var fallen: Dictionary = world.fallen
		var numbers: PackedByteArray = fallen.numbers
		var moved := PackedInt32Array()
		var record := FALLEN_FIELDS * 2
		for index in numbers.size() / record:
			var at := index * record
			if at + record > _fallen.size() or numbers.slice(at, at + record) != _fallen.slice(at, at + record) \
					or index >= _fallen_kinds.size() or _fallen_kinds[index] != fallen.kinds[index]:
				moved.append(index)
		var moved_numbers := PackedByteArray()
		var moved_kinds := PackedStringArray()
		for index in moved:
			moved_numbers.append_array(numbers.slice(index * record, index * record + record))
			moved_kinds.append(fallen.kinds[index])
		_arena = world.arena
		_objects = world.objects
		_fallen = numbers
		_fallen_kinds = fallen.kinds
		var state := {
			"arena": arena, "objects": objects, "gone": gone, "creatures": world.creatures,
			"fallen": {"count": numbers.size() / record, "moved": moved, "numbers": moved_numbers, "kinds": moved_kinds},
			"events": world.events,
		}
		var bytes := var_to_bytes(state)
		var packed := bytes.compress(FileAccess.COMPRESSION_ZSTD)
		packed.resize(packed.size() + 4)
		packed.encode_u32(packed.size() - 4, bytes.size())
		return packed


## A guest's side: the host's objects by id, kept from one snapshot to the next.
class Receiver:
	var objects := {}
	var _creature_ids := {}

	## Puts a snapshot into the guest's arena, and returns the events that came with it.
	func apply(packed: PackedByteArray, arena: Arena) -> Array[Dictionary]:
		var size := packed.decode_u32(packed.size() - 4)
		var state: Dictionary = bytes_to_var(packed.slice(0, packed.size() - 4).decompress(size, FileAccess.COMPRESSION_ZSTD))
		for id: int in state.gone:
			objects.erase(id)
		# Every object first, so a field can point at one sent after it.
		for id: int in state.objects:
			var fields: Dictionary = state.objects[id]
			if fields.has("#") and (not objects.has(id) or (objects[id].get_script() as Script).resource_path != fields["#"]):
				objects[id] = Snapshot._make(fields["#"])
		for id: int in state.objects:
			var object: Object = objects.get(id)
			if object == null:
				continue
			var fields: Dictionary = state.objects[id]
			for name: String in fields:
				if name != "#":
					Snapshot.put(object, name, _decode(fields[name], object.get(name)))
		for name: String in state.arena:
			Snapshot.put(arena, name, _decode(state.arena[name], arena.get(name)))
		_unpack_creatures(state.creatures, arena)
		_unpack_fallen(state.fallen, arena)
		var events: Array[Dictionary] = []
		events.assign(_decode(state.events, null))
		return events

	func _decode(value: Variant, existing: Variant) -> Variant:
		if value is Array:
			var list := []
			for index in (value as Array).size():
				var was: Variant = existing[index] if existing is Array and index < (existing as Array).size() else null
				list.append(_decode(value[index], was))
			return list
		if not value is Dictionary:
			return value
		if value.has("@") and value.size() == 1:
			return objects.get(value["@"])
		var table := {}
		for key: Variant in value:
			table[key] = _decode(value[key], existing.get(key) if existing is Dictionary else null)
		return table

	func _unpack_creatures(packed: Dictionary, arena: Arena) -> void:
		var ids: PackedInt64Array = packed.ids
		var kinds: PackedStringArray = packed.kinds
		var numbers: PackedByteArray = packed.numbers
		var creatures: Array[Creature] = []
		var here := {}
		for index in ids.size():
			var id := ids[index]
			here[id] = true
			var creature: Creature = objects.get(id)
			if creature == null or creature.kind != kinds[index]:
				creature = Creature.new(kinds[index])
				objects[id] = creature
			var at := func(field: int) -> float: return numbers.decode_s16((index * CREATURE_FIELDS + field) * 2) / SCALE
			creature.body.position = Vector2(at.call(0), at.call(1))
			creature.body.height = at.call(2)
			creature.body.velocity = Vector2(at.call(3), at.call(4))
			creature.tripped_for = at.call(5)
			creature.state = roundi(at.call(6) * SCALE)
			creature.carrying = roundi(at.call(7) * SCALE)
			var marks := roundi(at.call(8) * SCALE)
			creature.afflictions.clear()
			if marks & 1:
				creature.afflictions.burn = {"left": 1.0}
			if marks & 2:
				creature.afflictions.poison = {"left": 1.0}
			creatures.append(creature)
		for id: int in _creature_ids:
			if not here.has(id):
				objects.erase(id)
		_creature_ids = here
		arena.creatures = creatures

	## The fallen kept by their place in the line, not by id: lying still, one is as good as
	## another.
	func _unpack_fallen(packed: Dictionary, arena: Arena) -> void:
		while arena.fallen.size() > packed.count:
			arena.fallen.pop_back()
		while arena.fallen.size() < packed.count:
			arena.fallen.append(Body.new())
		var numbers: PackedByteArray = packed.numbers
		var moved: PackedInt32Array = packed.moved
		for slot in moved.size():
			var body := arena.fallen[moved[slot]]
			body.kind = packed.kinds[slot]
			var at := func(field: int) -> float: return numbers.decode_s16((slot * FALLEN_FIELDS + field) * 2) / SCALE
			body.position = Vector2(at.call(0), at.call(1))
			body.height = at.call(2)
			body.velocity = Vector2(at.call(3), at.call(4))
			body.vertical_speed = at.call(5)


## Sets a field from what arrived: a typed array is filled, not swapped for an untyped one.
static func put(object: Object, name: String, value: Variant) -> void:
	var was: Variant = object.get(name)
	if value is Array and was is Array and (was as Array).is_typed():
		(was as Array).assign(value)
	else:
		object.set(name, value)


## A fresh object of a simulation class, by its script: a cage wants dice to be made with.
static func _make(path: String) -> Object:
	if path == (Cage as Script).resource_path:
		return Cage.new(RandomNumberGenerator.new())
	return (load(path) as Script).new()


static func _pack_creatures(creatures: Array[Creature]) -> Dictionary:
	var ids := PackedInt64Array()
	var kinds := PackedStringArray()
	var numbers := PackedByteArray()
	numbers.resize(creatures.size() * CREATURE_FIELDS * 2)
	for index in creatures.size():
		var creature := creatures[index]
		ids.append(creature.get_instance_id())
		kinds.append(creature.kind)
		var marks := (1 if creature.afflictions.get("burn", {}).get("left", 0.0) > 0.0 else 0) \
			+ (2 if creature.afflictions.get("poison", {}).get("left", 0.0) > 0.0 else 0)
		var values := [creature.body.position.x, creature.body.position.y, creature.body.height,
			creature.body.velocity.x, creature.body.velocity.y, creature.tripped_for,
			creature.state / SCALE, creature.carrying / SCALE, marks / SCALE]
		for field in CREATURE_FIELDS:
			numbers.encode_s16((index * CREATURE_FIELDS + field) * 2, clampi(roundi(values[field] * SCALE), -32768, 32767))
	return {"ids": ids, "kinds": kinds, "numbers": numbers}


## Every one of the fallen, packed: the Sender sends on only those that have changed. Their kind
## goes with them: the view draws a rat's body as a rat's.
static func _pack_fallen(fallen: Array[Body]) -> Dictionary:
	var numbers := PackedByteArray()
	var kinds := PackedStringArray()
	numbers.resize(fallen.size() * FALLEN_FIELDS * 2)
	for index in fallen.size():
		var body := fallen[index]
		kinds.append(body.kind)
		var values := [body.position.x, body.position.y, body.height, body.velocity.x, body.velocity.y, body.vertical_speed]
		for field in FALLEN_FIELDS:
			numbers.encode_s16((index * FALLEN_FIELDS + field) * 2, clampi(roundi(values[field] * SCALE), -32768, 32767))
	return {"numbers": numbers, "kinds": kinds}
