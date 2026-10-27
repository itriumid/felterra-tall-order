extends TestCase
## Each area's ground plan: its own size, what stands where, and the way around it. Everything
## that matters can be got to, the horde goes around what it can't go through, and a round stops
## in what it hits.


func _area(area_id: String) -> Arena:
	var arena := Arena.new()
	arena.spawning = false
	arena.begin_area(area_id)
	return arena


func test_every_area_has_its_own_ground_plan() -> void:
	var sizes := {}
	for area: Dictionary in Areas.LIST:
		var arena := _area(area.id)
		check(arena.size == area.size, "%s is %s, not its own size" % [area.id, arena.size])
		sizes[area.size] = true
		check(Rect2(Vector2.ZERO, arena.size).has_point(area.start), "%s starts him outside it" % area.id)
	check(sizes.size() >= 4, "the areas come in only %d sizes" % sizes.size())
	check(not _area("sawpits").obstacles.is_empty() and not _area("offices").obstacles.is_empty(), "the sawpits or the offices stand empty")


func test_a_ground_plan_is_the_same_every_time() -> void:
	var first := _area("deep").obstacles
	var again := _area("deep").obstacles
	check(first.size() == again.size(), "the deep forest grew %d trees, then %d" % [first.size(), again.size()])
	for index in mini(first.size(), again.size()):
		check(first[index].center == again[index].center, "a tree in the deep forest moved")


func test_everything_that_matters_can_be_got_to() -> void:
	for area: Dictionary in Areas.LIST:
		var arena := _area(area.id)
		var field := FlowField.new(arena.size, arena.obstacles, Arena.NARROW)
		var spots: Array = [area.boss.at]
		spots.append_array(area.goal.get("at", []))
		for prop: Dictionary in area.get("props", []):
			spots.append(prop.at)
		var from: Array[Vector2] = [area.start]
		field.toward(from)
		check(not field.blocked(area.start), "%s starts him in something" % area.id)
		for spot: Vector2 in spots:
			check(not arena.solid_at(spot, 0.3), "something stands on %s in %s" % [spot, area.id])
			check(field.reaches(spot), "%s can't be got to in %s" % [spot, area.id])
		# And the way he walks in, from the left, is clear.
		check(arena.clear_between(area.start - Vector2(5.0, 0.0), area.start, 0.0), "the way into %s is blocked" % area.id)


func test_the_horde_goes_around_what_it_cannot_go_through() -> void:
	var arena := Arena.new()
	arena.spawning = false
	var wall: Array[Obstacle] = [Obstacle.from({"kind": "log_stack", "rect": Rect2(18.0, 8.0, 1.4, 8.0)})]
	arena.lay_out(Arena.SIZE, wall)
	var cat := arena.add_cat(Vector2(22.0, 12.0))
	cat.weapons.clear()
	cat.health = 1.0e6
	var rat := arena.add_creature(Vector2(14.0, 12.0))
	var dog := arena.add_creature(Vector2(14.0, 11.0), "dog")
	# A dog lunges past him and comes round again, so it's how close it got that counts.
	var closest := INF
	for step in 60 * 12:
		arena.step()
		closest = minf(closest, dog.body.position.distance_to(cat.body.position))
	check(rat.body.position.distance_to(cat.body.position) < 0.6, "the rat stopped behind the stack, at %s" % rat.body.position)
	check(closest < 1.0, "the dog stopped behind the stack, at %s" % dog.body.position)


func test_a_giant_goes_around_too() -> void:
	var arena := Arena.new()
	arena.spawning = false
	var wall: Array[Obstacle] = [Obstacle.from({"kind": "cabin", "rect": Rect2(18.0, 7.0, 3.0, 10.0)})]
	arena.lay_out(Arena.SIZE, wall)
	var cat := arena.add_cat(Vector2(24.0, 12.0))
	cat.weapons.clear()
	cat.health = 1.0e6
	var giant := arena.add_giant(Vector2(14.0, 12.0))
	for step in 60 * 20:
		arena.step()
		check(not wall[0].contains(giant.body.position), "the giant walked into the cabin")
	check(giant.body.position.distance_to(cat.body.position) < 1.5, "the giant stopped behind the cabin, at %s" % giant.body.position)


func test_nothing_walks_through_what_stands() -> void:
	var arena := Arena.new()
	arena.spawning = false
	var wall: Array[Obstacle] = [Obstacle.from({"kind": "cabin", "rect": Rect2(18.0, 6.0, 2.0, 12.0)})]
	arena.lay_out(Arena.SIZE, wall)
	var cat := arena.add_cat(Vector2(16.0, 12.0))
	cat.weapons.clear()
	for step in 60 * 3:
		cat.steering = Vector2.RIGHT
		arena.step()
	check(cat.body.position.x < 18.0, "he walked into the cabin, to %s" % cat.body.position)


func test_a_round_stops_in_what_it_hits_and_he_shoots_only_what_he_sees() -> void:
	var arena := Arena.new()
	arena.spawning = false
	var wall: Array[Obstacle] = [Obstacle.from({"kind": "log_stack", "rect": Rect2(19.0, 10.0, 1.4, 4.0)})]
	arena.lay_out(Arena.SIZE, wall)
	var cat := arena.add_cat(Vector2(16.0, 12.0))
	var hidden := arena.add_creature(Vector2(23.0, 12.0))
	check(arena.target_for(cat.body.position, 10.0, "nearest") == null, "he aimed at a rat behind the stack")
	check(arena.target_for(cat.body.position, 10.0, "nearest", INF) == hidden, "a lobbed round couldn't go over the stack")
	var seen := arena.add_creature(Vector2(16.0, 16.0))
	check(arena.target_for(cat.body.position, 10.0, "nearest") == seen, "he didn't aim at the rat in the open")
	var shot := Shot.new()
	shot.position = Vector2(17.0, 12.0)
	shot.height = 0.3
	shot.velocity = Vector2(40.0, 0.0)
	shot.life = 1.0
	shot.weapon = Weapon.new()
	arena.shots.append(shot)
	for step in 30:
		arena.step()
	check(hidden.alive(), "a round went through the stack")
	check(arena.shots.is_empty(), "a round kept flying in the stack")


func test_a_leap_clears_a_stump() -> void:
	var arena := Arena.new()
	var stump := Obstacle.from({"kind": "stump", "at": Vector2(20.0, 12.0), "radius": 0.4})
	var body := Body.new()
	body.position = Vector2(20.0, 12.0)
	body.radius = Cat.RADIUS
	body.height = 0.5
	var standing: Array[Obstacle] = [stump]
	arena.lay_out(Arena.SIZE, standing)
	arena._keep_inside(body)
	check(body.position == Vector2(20.0, 12.0), "a cat in the air over a stump was pushed off it")
	body.height = 0.0
	arena._keep_inside(body)
	check(not stump.contains(body.position, Cat.RADIUS - 0.01), "a cat on the ground stood in a stump")


func test_endless_stands_open_and_costs_nothing_extra() -> void:
	var arena := Arena.new()
	check(arena.size == Arena.SIZE and arena.obstacles.is_empty(), "Endless's clearing has something standing in it")
	check(arena.way(Vector2(1.0, 1.0), Vector2(5.0, 1.0)) == Vector2.RIGHT, "in the open, the way isn't straight")
