extends TestCase
## Endless's clearing and a grove aren't boxes: the jungle comes in round them by its own depth,
## wandering along each side and deepest at the corners. A liberation area keeps its rectangle.


func _shaped(seed_value := 5) -> Arena:
	var arena := Arena.new()
	arena.spawning = false
	arena.shape(seed_value)
	return arena


func test_the_same_seed_makes_the_same_clearing_and_another_seed_another() -> void:
	var one := _shaped(5)
	var again := _shaped(5)
	var other := _shaped(6)
	var same := true
	var differs := false
	for side in 4:
		for along in range(0, 30, 3):
			same = same and is_equal_approx(one.depth(side, along), again.depth(side, along))
			differs = differs or not is_equal_approx(one.depth(side, along), other.depth(side, along))
	check(same, "the same seed shaped the clearing two ways: a guest online would see another")
	check(differs, "two seeds shaped the same clearing")


func test_the_jungle_comes_in_unevenly_and_rounds_the_corners() -> void:
	var arena := _shaped()
	var deepest := 0.0
	var shallowest := INF
	for along in range(8, 48):
		deepest = maxf(deepest, arena.depth(0, along))
		shallowest = minf(shallowest, arena.depth(0, along))
	check(deepest - shallowest > 1.0, "along the top the jungle comes in from %.1f to %.1f m: a straight wall" % [shallowest, deepest])
	check(not arena.inside(Vector2(0.5, 0.5)), "the corner is still square")
	check(arena.inside(arena.size / 2.0, 5.0), "the middle isn't inside")
	check(not Arena.new().shaped(), "an arena with no shape given has one")


func test_nothing_goes_past_where_the_jungle_comes_in() -> void:
	var arena := _shaped()
	var cat := arena.add_cat(arena.size / 2.0)
	cat.health = 1.0e6
	var rat := arena.add_creature(Vector2(1.0, 1.0))
	for side in 4:
		cat.steering = [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT][side]
		for step in 60 * 12:
			arena.step()
		check(arena.inside(cat.body.position, cat.body.radius - 0.01), "he walked into the jungle at %s" % cat.body.position)
	check(arena.inside(rat.body.position, rat.body.radius - 0.01) or not rat.alive(), "a rat stood in the jungle at %s" % rat.body.position)


func test_the_horde_comes_in_from_where_the_jungle_is() -> void:
	var arena := _shaped()
	for index in 200:
		var gate := arena.edge_point()
		check(arena.inside(gate), "the horde came out of the jungle at %s, inside the trees" % gate)
		var edge := arena.edge_near(gate)
		check(edge.distance_to(gate) < 0.5, "it came in at %s, %.1f m from the jungle's edge" % [gate, edge.distance_to(gate)])
		if not arena.inside(gate) or edge.distance_to(gate) >= 0.5:
			return


func test_fleeing_they_reach_the_jungle_and_are_gone() -> void:
	var arena := _shaped()
	arena.add_cat(arena.size / 2.0)
	for index in 20:
		arena.add_creature(arena.size / 2.0 + Vector2.from_angle(index) * 6.0)
	arena.fleeing = true
	for step in 60 * 30:
		arena.step()
	check(arena.creatures.is_empty(), "%d of the horde never got out into the jungle" % arena.creatures.size())


func test_a_grove_is_shaped_and_nothing_stands_out_in_its_jungle() -> void:
	var arena := Arena.new()
	arena.begin_grove(4)
	check(arena.shaped(), "a grove is a box")
	for obstacle in arena.obstacles:
		if obstacle.kind != "water":
			check(arena.inside(obstacle.center, obstacle.radius), "a %s stands out in the jungle at %s" % [obstacle.kind, obstacle.center])
	for drain in arena.drains:
		check(arena.inside(drain.position, 1.0), "a drain is dug in the jungle at %s" % drain.position)


func test_a_liberation_area_keeps_its_rectangle() -> void:
	var arena := Arena.new()
	arena.begin_area("edge")
	check(not arena.shaped(), "the village's edge, laid out by hand, was reshaped")
