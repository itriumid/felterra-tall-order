extends TestCase
## Endless hardens as it goes, so no build outgrows it for good; a liberation area doesn't. And a
## level takes more the further a run has got.


func test_nothing_is_tougher_before_the_pressure_starts() -> void:
	var arena := Arena.new()
	arena.spawning = false
	arena.time = Arena.PRESSURE_FROM
	var rat := arena.add_creature(Vector2(5.0, 5.0))
	var giant := arena.add_giant(Vector2(8.0, 8.0))
	check(is_equal_approx(rat.health, Creature.KINDS.rat.health) and is_equal_approx(rat.might, 1.0), "a rat came tougher before the pressure started")
	check(is_equal_approx(giant.health, Giant.KINDS.worker.health) and is_equal_approx(giant.might, 1.0), "a giant came tougher before the pressure started")


func test_what_comes_late_in_endless_is_tougher_and_bites_harder() -> void:
	var arena := Arena.new()
	arena.spawning = false
	arena.time = Arena.PRESSURE_FROM + 600.0
	var might := arena.pressure()
	check(might > 3.0, "ten minutes of pressure only made things %.2f times as tough" % might)
	var rat := arena.add_creature(Vector2(5.0, 5.0))
	check(is_equal_approx(rat.health, Creature.KINDS.rat.health * might), "a late rat has %.1f health" % rat.health)
	var giant := arena.add_giant(Vector2(8.0, 8.0))
	check(is_equal_approx(giant.most_health, Giant.KINDS.worker.health * might) and giant.health == giant.most_health, "a late giant has %.1f health" % giant.health)
	# Its bite, on a cat with nothing on.
	var cat := arena.add_cat(Vector2(20.0, 12.0))
	cat.max_health = 1000.0
	cat.health = 1000.0
	var biter := arena.add_creature(cat.body.position + Vector2(0.1, 0.0))
	arena.step()
	check(is_equal_approx(1000.0 - cat.health, Creature.KINDS.rat.bite * biter.might), "a late rat's bite took %.2f" % (1000.0 - cat.health))


func test_a_late_rat_is_shoved_less() -> void:
	var early := Arena.new()
	var late := Arena.new()
	late.time = Arena.PRESSURE_FROM + 600.0
	var speeds: Array[float] = []
	for arena: Arena in [early, late]:
		arena.spawning = false
		var rat := arena.add_creature(Vector2(5.0, 5.0))
		rat.health = 1000.0
		arena.strike(rat, 1.0, Vector2.RIGHT, 2.0, 0.0, "round")
		speeds.append(rat.body.velocity.x)
	check(speeds[1] < speeds[0] * 0.7, "a late rat was thrown at %.2f against an early one's %.2f" % [speeds[1], speeds[0]])


func test_a_liberation_area_never_hardens() -> void:
	var arena := Arena.new()
	arena.begin_area("edge")
	arena.time = Arena.PRESSURE_FROM + 900.0
	check(is_equal_approx(arena.pressure(), 1.0), "an area's pressure reached %.2f" % arena.pressure())


func test_a_grove_hardens_as_endless_does() -> void:
	var arena := Arena.new()
	arena.begin_grove(7)
	arena.time = Arena.PRESSURE_FROM + 600.0
	check(arena.pressure() > 3.0, "a grove's pressure only reached %.2f" % arena.pressure())


func test_a_level_takes_more_each_level_and_more_again_late() -> void:
	var last := 0
	for level in range(1, 80):
		var needed := Arena.experience_needed(level)
		check(needed > last, "level %d takes %d, no more than the one before" % [level, needed])
		last = needed
	check(Arena.experience_needed(Arena.LEVELS_STEEPEN) == 4 + Arena.LEVELS_STEEPEN * 3, "the first levels changed")
	check(Arena.experience_needed(60) > 2 * (4 + 60 * 3), "level 60 takes %d, barely more than it did" % Arena.experience_needed(60))
