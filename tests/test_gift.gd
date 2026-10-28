extends TestCase
## The spirits' gift: the cub at his heel, its pounce and its elements, its levels on the cards,
## and at the shrine, its ranks and elements paid for in offerings from the groves.


func _arena(element := "ember") -> Arena:
	var arena := Arena.new()
	arena.spawning = false
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	cat.health = 1.0e6
	cat.charm = Companion.new(element)
	cat.charm.body.position = cat.body.position + cat.charm.facing_offset(cat)
	return arena


## Steps until the cub has landed a pounce, or the time's up. Whether it did.
func _until_it_lands(arena: Arena, seconds := 4.0) -> bool:
	var cub: Companion = arena.cats[0].charm
	for step in int(seconds / Arena.STEP):
		arena.step()
		if cub.pounces > 0:
			return true
	return false


## A rat too tough to die of one pounce, close enough to him that the cub goes after it.
func _tough_rat(arena: Arena) -> Creature:
	var rat := arena.add_creature(arena.cats[0].body.position + Vector2(2.5, 0.0))
	rat.health = 1000.0
	return rat


func test_the_cub_keeps_to_his_heel() -> void:
	var arena := _arena()
	var cat := arena.cats[0]
	cat.steering = Vector2.RIGHT
	for step in int(3.0 / Arena.STEP):
		arena.step()
	var apart := cat.charm.body.position.distance_to(cat.body.position)
	check(apart < 1.5, "the cub is %.2f m from him after he walked off" % apart)


func test_the_cub_pounces_on_what_comes_near_him() -> void:
	var arena := _arena()
	var rat := arena.add_creature(arena.cats[0].body.position + Vector2(2.5, 0.0))
	check(_until_it_lands(arena), "the cub never pounced")
	check(not rat.alive(), "the rat lived through the cub's pounce with %.1f health" % rat.health)


func test_the_cub_lets_be_what_is_far_from_him() -> void:
	var arena := _arena()
	var far_off := arena.cats[0].body.position + Vector2(Companion.WATCH + 3.0, 0.0)
	var far := arena.add_creature(far_off)
	# Held where it is, however it runs at him.
	for step in int(2.0 / Arena.STEP):
		far.body.position = far_off
		arena.step()
	check(arena.cats[0].charm.pounces == 0, "the cub went after something %.1f m from him" % (Companion.WATCH + 3.0))


func test_ember_sets_what_it_lands_on_burning() -> void:
	var arena := _arena("ember")
	var rat := _tough_rat(arena)
	check(_until_it_lands(arena), "the cub never pounced")
	check(rat.afflictions.has("burn"), "the rat isn't burning")


func test_smoke_slows_the_horde_round_where_it_lands() -> void:
	var arena := _arena("smoke")
	var rat := _tough_rat(arena)
	check(_until_it_lands(arena), "the cub never pounced")
	check(rat.pace() < 1.0, "the rat keeps its whole pace")


func test_root_holds_what_it_lands_on() -> void:
	var arena := _arena("root")
	var rat := _tough_rat(arena)
	check(_until_it_lands(arena), "the cub never pounced")
	check(rat.tripped(), "the rat isn't held")


func test_river_throws_the_horde_off() -> void:
	var arena := _arena("river")
	var rat := _tough_rat(arena)
	check(_until_it_lands(arena), "the cub never pounced")
	var cub: Companion = arena.cats[0].charm
	var thrown := rat.body.velocity.dot((rat.body.position - cub.body.position).normalized())
	check(thrown > 1.0 or rat.body.airborne(), "the rat was thrown off at %.2f m/s" % thrown)


func test_a_rank_at_the_shrine_hits_harder() -> void:
	var arena := _arena()
	var cat := arena.cats[0]
	var first := cat.charm.share(cat)
	cat.charm = Companion.new("ember", 5)
	check(cat.charm.share(cat) > first, "rank 5 hits as hard as rank 1")


func test_the_cub_levels_on_the_cards_only_when_he_wears_it() -> void:
	var cat := Cat.new()
	check(not "charm_level:cub" in Upgrades.available(cat), "the cub's card came without the cub")
	cat.charm = Companion.new()
	check("charm_level:cub" in Upgrades.available(cat), "no card for the cub he wears")
	Upgrades.apply(cat, {"id": "charm_level:cub", "rarity": Upgrades.Rarity.COMMON})
	check(cat.charm.level == 2 and cat.charm.power > 0.0, "the cub's card left it at level %d" % cat.charm.level)
	var card := Upgrades.describe({"id": "charm_level:cub", "rarity": Upgrades.Rarity.COMMON})
	check(card.kind == "charm" and not (card.lines as Array).is_empty(), "the cub's card shows nothing")


func test_the_cub_is_given_only_after_the_truce() -> void:
	var village := Village.new()
	check(not village.give_cub(), "the cub was given before there was peace")
	village.liberated.append("siege")
	check(village.give_cub() and village.gifted(), "the cub wasn't given after the truce")
	check(not village.give_cub(), "the cub was given twice")


func test_offerings_come_only_from_the_groves() -> void:
	var village := Village.new()
	var clearing := Arena.new()
	clearing.time = 600.0
	village.bring_home(clearing)
	check(village.offerings == 0, "%d offerings from a clearing" % village.offerings)
	var grove := Arena.new()
	grove.begin_grove(7)
	grove.time = 600.0
	village.bring_home(grove)
	check(village.offerings == 10, "%d offerings for ten minutes in a grove" % village.offerings)


func test_ranks_and_elements_cost_offerings_and_switching_back_is_free() -> void:
	var village := Village.new()
	village.liberated.append("siege")
	village.give_cub()
	village.offerings = Village.RANK_COSTS[0] - 1
	check(not village.rank_cub(), "a rank for too few offerings")
	village.offerings = Village.RANK_COSTS[0] + Village.ELEMENT_COSTS.river
	check(village.rank_cub() and village.cub_rank == 2, "no rank for its offerings")
	check(village.take_element("river") and village.offerings == 0, "river woke and left %d offerings" % village.offerings)
	check(village.take_element("ember") and village.take_element("river"), "changing back to a woken element cost something")
	check(not village.take_element("smoke"), "smoke woke for nothing")


func test_the_whole_way_up_is_slow() -> void:
	var total := 0
	for cost in Village.RANK_COSTS:
		total += cost
	for element: String in Village.ELEMENT_COSTS:
		total += Village.ELEMENT_COSTS[element]
	# A ten-minute grove gives ten: everything is thirty runs or more of them.
	check(total >= 300, "everything costs only %d offerings" % total)
	check(Village.RANK_COSTS.size() == Companion.MOST_RANK - 1, "%d rank costs for %d ranks" % [Village.RANK_COSTS.size(), Companion.MOST_RANK])


func test_the_gift_is_kept() -> void:
	var village := Village.new()
	village.liberated.append("siege")
	village.give_cub()
	village.offerings = 100
	village.rank_cub()
	village.take_element("root")
	var path := "user://test_village_gift.cfg"
	village.save(path)
	var loaded := Village.new()
	loaded.load_from(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(loaded.cub_rank == 2 and loaded.cub_element == "root" and "root" in loaded.elements, "came back rank %d, %s, %s" % [loaded.cub_rank, loaded.cub_element, str(loaded.elements)])
	check(loaded.offerings == village.offerings, "%d offerings came back of %d" % [loaded.offerings, village.offerings])
