extends TestCase
## Playing together: the crew's Nine Lives, getting a crewmate up, a life spent when nobody comes,
## the horde a bigger crew draws, and the leash that keeps one screen's crew on it.


## A crew of cats standing still with nothing to fight with, so nothing is decided by a kill.
func _crew(count: int) -> Arena:
	var arena := Arena.new()
	arena.spawning = false
	for index in count:
		var cat := arena.add_cat(Arena.SIZE / 2.0 + Vector2(index * 4.0, 0.0))
		cat.weapons.clear()
		cat.player = index
	return arena


func _run(arena: Arena, seconds: float) -> void:
	for step in int(seconds / Arena.STEP):
		arena.step()


func test_alone_down_is_the_end() -> void:
	var arena := _crew(1)
	arena.cats[0].health = 0.0
	arena.step()
	check(arena.over(), "he's down alone and the run goes on")
	check(arena.lives == Arena.LIVES, "a life was spent alone: %d left" % arena.lives)


func test_together_down_is_not_the_end() -> void:
	var arena := _crew(2)
	arena.cats[1].health = 0.0
	arena.step()
	check(arena.cats[1].downed, "the cat isn't down")
	check(not arena.over(), "the run ended with a crewmate standing")


func test_a_crewmate_standing_by_gets_them_up() -> void:
	var arena := _crew(2)
	var down := arena.cats[1]
	down.health = 0.0
	arena.cats[0].body.position = down.body.position + Vector2(0.3, 0.0)
	_run(arena, Arena.REVIVE_TIME + 0.2)
	check(down.alive(), "still down after a crewmate stood by for %.1f s" % (Arena.REVIVE_TIME + 0.2))
	check(is_equal_approx(down.health, down.max_health * Arena.REVIVED_HEALTH), "up with %.1f health" % down.health)
	check(arena.lives == Arena.LIVES, "getting up cost a life: %d left" % arena.lives)


func test_nobody_coming_spends_a_life() -> void:
	var arena := _crew(2)
	var down := arena.cats[1]
	down.health = 0.0
	_run(arena, Arena.DOWN_TIME - 0.5)
	check(not down.alive(), "up before the time ran out, with nobody by them")
	_run(arena, 1.0)
	check(down.alive() and down.health == down.max_health, "not up whole once a life was spent")
	check(arena.lives == Arena.LIVES - 1, "%d lives left after one was spent" % arena.lives)
	var apart := down.body.position.distance_to(arena.cats[0].body.position)
	check(apart < 1.0, "up %.1f m from the crewmate standing" % apart)


func test_with_no_lives_left_the_run_is_lost() -> void:
	var arena := _crew(2)
	arena.lives = 0
	arena.cats[1].health = 0.0
	_run(arena, Arena.DOWN_TIME + 0.5)
	check(arena.over(), "the run goes on with no lives left and nobody come")


func test_everyone_down_with_no_lives_is_lost_at_once() -> void:
	var arena := _crew(3)
	arena.lives = 0
	for cat in arena.cats:
		cat.health = 0.0
	arena.step()
	check(arena.over(), "the run goes on with the whole crew down and no lives")


func test_everyone_down_with_lives_left_gets_up() -> void:
	var arena := _crew(2)
	for cat in arena.cats:
		cat.health = 0.0
	_run(arena, Arena.DOWN_TIME + 0.5)
	check(not arena.over(), "the run ended with lives left")
	check(arena.cats.all(func(cat: Cat) -> bool: return cat.alive()), "not everyone got up on a life")
	check(arena.lives == Arena.LIVES - 2, "%d lives left after two were spent" % arena.lives)


func test_a_bigger_crew_draws_more_but_not_a_crew_more() -> void:
	check(_crew(1).crew_scale() == 1.0, "one cat draws %.1f times the horde" % _crew(1).crew_scale())
	check(is_equal_approx(_crew(4).crew_scale(), 2.5), "four draw %.1f times the horde" % _crew(4).crew_scale())
	var alone := _crew(1)
	var four := _crew(4)
	for arena: Arena in [alone, four]:
		arena.spawning = true
		arena.plan = {"rats": Arena.ENDLESS.rats}
		_run(arena, 20.0)
	check(four.creatures.size() > alone.creatures.size() * 2, "four drew %d to one's %d" % [four.creatures.size(), alone.creatures.size()])


func test_the_leash_holds_the_one_walking_off() -> void:
	var arena := _crew(2)
	arena.leash = Vector2(8.0, 5.0)
	var staying := arena.cats[0]
	var walking := arena.cats[1]
	var stayed_at := staying.body.position
	walking.steering = Vector2.RIGHT
	_run(arena, 6.0)
	var apart := walking.body.position.x - staying.body.position.x
	check(apart <= arena.leash.x + 0.01, "walked %.1f m off, past a leash of %.1f" % [apart, arena.leash.x])
	check(staying.body.position.distance_to(stayed_at) < 0.01, "the one standing still was dragged along")


func test_a_runs_earnings_go_home_to_any_village() -> void:
	var arena := Arena.new()
	arena.begin_grove(3)
	arena.salvage = 12
	arena.time = 300.0
	arena.rescued.append({"name": "Mbok", "coat": "gray"})
	var earnings := Village.earnings_of(arena)
	var host := Village.new()
	var guest := Village.new()
	host.bring_home(arena)
	guest.take_earnings(earnings)
	for village: Village in [host, guest]:
		check(village.salvage == 12 and village.offerings == 5 and village.cats.size() == 1, "a village took home %d salvage, %d offerings, %d cats" % [village.salvage, village.offerings, village.cats.size()])


func test_dropping_in_comes_in_beside_the_crew_with_the_cards_missed() -> void:
	var arena := _crew(1)
	arena.level = 6
	var late := Cat.new()
	late.weapons.clear()
	arena.drop_in(late)
	check(late in arena.cats, "the late cat isn't in the run")
	check(late.offers.size() == 5, "dealt %d cards for the 5 level-ups missed" % late.offers.size())
	check(late.body.position.distance_to(arena.cats[0].body.position) < 1.0, "came in %.1f m from the crew" % late.body.position.distance_to(arena.cats[0].body.position))
	check(late.safe_for > 0.0, "nothing keeps them out of harm's way as they come in")


func test_coming_back_from_a_dropped_connection_deals_nothing_again() -> void:
	var arena := _crew(2)
	arena.level = 4
	var back := arena.cats[1]
	arena.cats.erase(back)
	arena.drop_in(back, true)
	check(back.offers.is_empty() and back in arena.cats, "came back with %d cards dealt again" % back.offers.size())
