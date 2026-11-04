extends TestCase
## Experience as fireflies: they rise where something fell and wait there, a cat near draws them in,
## caught they count for the crew, a tuyul swallows them, freeing an area or cleansing a grove
## calls them all in, and a guest is sent only those that changed.


func _arena() -> Arena:
	var arena := Arena.new()
	arena.spawning = false
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	cat.health = 1.0e6
	return arena


func _steps(arena: Arena, steps: int) -> void:
	for step in steps:
		arena.step()


func _kill(arena: Arena, where: Vector2, kind := "rat") -> void:
	arena.strike(arena.add_creature(where, kind), 1000.0, Vector2.ZERO, 0.0, 0.0, "round")


func test_a_kill_leaves_its_worth_as_a_firefly_that_waits() -> void:
	var arena := _arena()
	_kill(arena, Arena.SIZE / 2.0 + Vector2(6.0, 0.0), "dog")
	check(arena.experience == 0, "the kill counted before anyone caught it")
	check(arena.fireflies.count() == 1 and arena.fireflies.total() == Creature.KINDS.dog.worth, "%d fireflies worth %d" % [arena.fireflies.count(), arena.fireflies.total()])
	var at := arena.fireflies.at[0]
	_steps(arena, 60 * 20)
	check(arena.fireflies.count() == 1 and arena.fireflies.at[0] == at and arena.experience == 0, "with nobody near, the firefly moved or went")


func test_a_cat_near_draws_it_in_and_the_crew_has_it() -> void:
	var arena := _arena()
	var second := arena.add_cat(Arena.SIZE / 2.0 + Vector2(-6.0, 0.0))
	second.weapons.clear()
	_kill(arena, Arena.SIZE / 2.0 + Vector2(Fireflies.PULL * 0.8, 0.0), "dog")
	_steps(arena, 60)
	check(arena.fireflies.count() == 0, "the firefly near him wasn't caught")
	check(arena.experience == Creature.KINDS.dog.worth, "the crew has %d experience" % arena.experience)


func test_a_big_fall_rises_as_a_few_and_loses_nothing() -> void:
	var arena := _arena()
	_kill(arena, Arena.SIZE / 2.0 + Vector2(6.0, 0.0), "rat_baron")
	var worth: int = Creature.KINDS.rat_baron.worth
	check(arena.fireflies.count() == Fireflies.MOST_A_FALL, "the Baron rose as %d fireflies" % arena.fireflies.count())
	check(arena.fireflies.total() == worth, "they're worth %d of his %d" % [arena.fireflies.total(), worth])


func test_a_caught_slot_is_used_again() -> void:
	var arena := _arena()
	_kill(arena, Arena.SIZE / 2.0 + Vector2(0.5, 0.0))
	_steps(arena, 30)
	_kill(arena, Arena.SIZE / 2.0 + Vector2(6.0, 0.0))
	check(arena.fireflies.worth.size() == 1 and arena.fireflies.count() == 1, "%d slots for %d fireflies" % [arena.fireflies.worth.size(), arena.fireflies.count()])


func test_a_tuyul_swallows_them_and_gives_them_back_when_caught() -> void:
	var arena := _arena()
	var spot := Arena.SIZE / 2.0 + Vector2(6.0, 0.0)
	_kill(arena, spot, "dog")
	var tuyul := arena.add_creature(spot + Vector2(1.0, 0.0), "tuyul")
	_steps(arena, 60 * 2)
	check(arena.fireflies.count() == 0 and tuyul.glow == Creature.KINDS.dog.worth, "the tuyul swallowed %d" % tuyul.glow)
	arena.strike(tuyul, 1000.0, Vector2.ZERO, 0.0, 0.0, "round")
	check(arena.fireflies.total() == Creature.KINDS.dog.worth + Creature.KINDS.tuyul.worth, "%d came back out of him" % arena.fireflies.total())


func test_a_tuyul_full_of_them_gets_away() -> void:
	var arena := _arena()
	var tuyul := arena.add_creature(Vector2(3.0, Arena.SIZE.y / 2.0), "tuyul")
	tuyul.glow = Arena.GLOW_ENOUGH
	_steps(arena, 60 * 4)
	check(not tuyul in arena.creatures, "the tuyul is still about, at %s" % tuyul.body.position)


func test_cleansing_a_grove_calls_them_all_in() -> void:
	var arena := Arena.new()
	arena.begin_grove(5)
	arena.spawning = false
	var cat := arena.add_cat(arena.size / 2.0)
	cat.weapons.clear()
	cat.health = 1.0e6
	for index in 6:
		_kill(arena, arena.size / 2.0 + Vector2.from_angle(index) * 8.0)
	arena._cleanse()
	_steps(arena, 60 * 4)
	check(arena.fireflies.count() == 0 and arena.experience + (arena.level - 1) * 100 > 0, "%d fireflies still out" % arena.fireflies.count())


func test_a_guest_is_sent_only_the_fireflies_that_changed() -> void:
	var host := _arena()
	for index in 400:
		_kill(host, Vector2(2.0 + (index % 40) * 0.7, 2.0 + (index / 40) * 0.7))
	var guest := Arena.new()
	var sender := Snapshot.Sender.new()
	var receiver := Snapshot.Receiver.new()
	receiver.apply(sender.delta(Snapshot.take(host, [])), guest)
	check(guest.fireflies.count() == host.fireflies.count(), "%d fireflies came of %d" % [guest.fireflies.count(), host.fireflies.count()])
	check(guest.fireflies.at[17] == host.fireflies.at[17], "a firefly came to the wrong place")
	# He draws some in: they're sent once, as they start to come, and not again as they fly.
	host.cats[0].body.position = Vector2(4.0, 4.0)
	host.step()
	var world := Snapshot.take(host, [])
	var coming := 0
	for each in host.fireflies.speed:
		coming += 1 if each > 0.0 else 0
	# Those that started to come, and any caught the same step.
	var caught := host.fireflies.worth.count(0)
	check(coming > 0 and world.fireflies.slots.size() == coming + caught, "%d slots to send, %d of them coming, %d caught" % [world.fireflies.slots.size(), coming, caught])
	receiver.apply(sender.delta(world), guest)
	host.cats[0].body.position = Arena.SIZE / 2.0 + Vector2(10.0, 8.0)
	host.step()
	var flying := Snapshot.take(host, [])
	check(flying.fireflies.slots.is_empty(), "%d sent as they flew" % flying.fireflies.slots.size())
	receiver.apply(sender.delta(world), guest)
	check(guest.fireflies.count() == host.fireflies.count(), "after a step, %d fireflies of %d" % [guest.fireflies.count(), host.fireflies.count()])
	# A second guest joining now has every one sent.
	var joining := Arena.new()
	Snapshot.Receiver.new().apply(Snapshot.Sender.new().delta(Snapshot.take(host, [])), joining)
	check(joining.fireflies.count() == host.fireflies.count(), "a guest joining late has %d of %d" % [joining.fireflies.count(), host.fireflies.count()])


func test_a_crowd_of_them_in_one_spot_is_all_drawn_in() -> void:
	var arena := _arena()
	var spot := Arena.SIZE / 2.0 + Vector2(6.0, 0.0)
	for index in 30:
		arena.fireflies.rise(spot + Vector2(index * 0.01, 0.0), 1, arena.time)
	check(arena.fireflies.hanging_near(spot, 1.0).size() == 30, "the grid has %d of 30" % arena.fireflies.hanging_near(spot, 1.0).size())
	arena.cats[0].body.position = spot
	_steps(arena, 60)
	check(arena.fireflies.count() == 0 and arena.experience + (arena.level - 1) * 100 >= 30, "%d of 30 still out" % arena.fireflies.count())
