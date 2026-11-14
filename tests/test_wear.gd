extends TestCase
## What a fight leaves on the giants and machines: each hit names what it struck, is marked in the
## kind of what landed it, and lands on the face turned toward it.


func test_each_kind_of_hit_leaves_its_own_mark() -> void:
	var cases := [
		[{"by": "round", "source": "handgun"}, "hole"], [{"by": "round", "source": "nail_gun"}, "nail"],
		[{"by": "round", "source": "crossbow"}, "shaft"], [{"by": "round", "source": "ketapel"}, "dent"],
		[{"by": "blade", "source": "golok"}, "gash"], [{"by": "blade", "source": "hammer"}, "dent"],
		[{"by": "fire"}, "scorch"], [{"by": "grenade_launcher"}, "blast"], [{"by": "poison"}, ""],
	]
	for each: Array in cases:
		check(Wear.kind_of(each[0]) == each[1], "%s marks as \"%s\", not \"%s\"" % [each[0], Wear.kind_of(each[0]), each[1]])


func test_a_hit_names_what_it_struck_so_a_moving_machine_is_marked() -> void:
	var arena := Arena.new()
	arena.spawning = false
	var machine := arena.add_machine(Arena.SIZE / 2.0, 0.0)
	arena.strike(machine, 1.0, Vector2.LEFT, 0.0, 0.0, "round", null, "handgun")
	var hit: Dictionary = arena.events.back()
	# It drives on before the view gets to the hit.
	machine.body.position += Vector2(3.0, 0.0)
	var wear := Wear.new()
	wear.take(arena.events, arena, 0.0)
	check(Wear.target_of(hit, arena) == machine, "the hit doesn't name the machine")
	check(wear.of(machine).size() == 1, "the machine carries %d marks" % wear.of(machine).size())


func test_a_mark_lands_on_the_face_turned_toward_the_hit() -> void:
	var arena := Arena.new()
	arena.spawning = false
	# Facing east; hit from the east, so on its front, if not on its top.
	var machine := arena.add_machine(Arena.SIZE / 2.0, 0.0)
	var wear := Wear.new()
	var events: Array[Dictionary] = []
	for index in 40:
		events.append({"by": "round", "source": "handgun", "giant": true, "kind": "machine", "direction": Vector2.LEFT, "on": machine, "position": machine.body.position})
	wear.take(events, arena, 0.0)
	var hull := Wear.hull(machine)
	for mark: Dictionary in wear.of(machine):
		var face: Vector2 = mark.face
		check(face == Vector2.ZERO or face == Vector2.RIGHT, "a hit from the front marked the %s face" % face)
		if face == Vector2.RIGHT:
			check(is_equal_approx(mark.along, hull.along + hull.length * 0.5), "a mark on its front isn't on the front of its hull")
	check(wear.of(machine).size() == Wear.MOST, "it carries %d marks, not at most %d" % [wear.of(machine).size(), Wear.MOST])


func test_fire_scorches_only_now_and_then() -> void:
	var arena := Arena.new()
	arena.spawning = false
	var giant := arena.add_giant(Arena.SIZE / 2.0)
	var wear := Wear.new()
	for tick in 10:
		var events: Array[Dictionary] = [{"by": "fire", "giant": true, "direction": Vector2.ZERO, "on": giant, "position": giant.body.position}]
		wear.take(events, arena, tick * 0.1)
	check(wear.of(giant).size() == 2, "a second of burning left %d scorches" % wear.of(giant).size())
