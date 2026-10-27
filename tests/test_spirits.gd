extends TestCase
## The forest's spirits: what each of the horde does, the siege's fires, Inyiak Balang, the peace
## after it, and Endless as cleansing a sick grove.


func _arena() -> Arena:
	var arena := Arena.new()
	arena.spawning = false
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	cat.health = 1.0e6
	return arena


func _siege() -> Arena:
	var arena := Arena.new()
	arena.begin_area("siege")
	arena.spawning = false
	var cat := arena.add_cat(arena.area.start)
	cat.weapons.clear()
	cat.health = 1.0e6
	return arena


func _steps(arena: Arena, steps: int) -> void:
	for step in steps:
		arena.step()


func test_a_wisp_floats_and_still_bites() -> void:
	var arena := _arena()
	var wisp := arena.add_creature(arena.cats[0].body.position + Vector2(3.0, 0.0), "wisp")
	var lowest := INF
	for step in 60 * 4:
		arena.step()
		lowest = minf(lowest, wisp.body.height)
	check(lowest >= Creature.KINDS.wisp.hovers - 0.001, "the wisp came down to %.2f m" % lowest)
	check(arena.cats[0].hits_taken > 0, "the wisp never bit him")


func test_a_spirit_leaves_nothing_lying() -> void:
	var arena := _arena()
	for kind: String in ["wisp", "tuyul", "sapling", "monkey", "pocong"]:
		var spirit := arena.add_creature(arena.cats[0].body.position + Vector2(4.0, 0.0), kind)
		arena.strike(spirit, 1000.0, Vector2.RIGHT, 1.0, 0.0, "round")
	check(arena.creatures.is_empty() and arena.fallen.is_empty(), "%d fallen lie where the spirits went out" % arena.fallen.size())
	check(arena.kills == 5, "%d kills counted for five spirits" % arena.kills)


func test_a_tuyul_bites_off_salvage_and_drops_it_when_caught() -> void:
	var arena := _arena()
	arena.salvage = 3
	var tuyul := arena.add_creature(arena.cats[0].body.position + Vector2(0.15, 0.0), "tuyul")
	_steps(arena, 10)
	check(arena.salvage == 2 and tuyul.carrying == 1, "salvage %d, the tuyul carrying %d" % [arena.salvage, tuyul.carrying])
	arena.strike(tuyul, 1000.0, Vector2.RIGHT, 0.0, 0.0, "round")
	check(arena.pickups.size() == 1, "the tuyul dropped %d pieces" % arena.pickups.size())


func test_a_tuyul_left_alone_gets_away_with_it() -> void:
	var arena := _arena()
	var tuyul := arena.add_creature(Vector2(3.0, Arena.SIZE.y / 2.0), "tuyul")
	tuyul.carrying = 1
	_steps(arena, 60 * 4)
	check(not tuyul in arena.creatures, "the tuyul is still about, at %s" % tuyul.body.position)


func test_a_tuyul_goes_for_salvage_lying_about() -> void:
	var arena := _arena()
	var tuyul := arena.add_creature(Vector2(5.0, 5.0), "tuyul")
	var piece := Pickup.new()
	piece.body.position = Vector2(8.0, 5.0)
	arena.pickups.append(piece)
	_steps(arena, 60 * 3)
	check(arena.pickups.is_empty() and tuyul.carrying == 1, "the salvage lies there still, the tuyul carrying %d" % tuyul.carrying)


func test_a_pocong_only_hops_and_a_hard_hit_knocks_it_flat() -> void:
	var arena := _arena()
	var pocong := arena.add_creature(arena.cats[0].body.position + Vector2(5.0, 0.0), "pocong")
	var in_the_air := 0
	var on_the_ground := 0
	for step in 60 * 2:
		arena.step()
		if pocong.body.airborne():
			in_the_air += 1
		else:
			on_the_ground += 1
	check(in_the_air > 20 and on_the_ground > 10, "in the air %d steps, on the ground %d" % [in_the_air, on_the_ground])
	check(pocong.body.position.distance_to(arena.cats[0].body.position) < 4.5, "the pocong got no nearer")
	arena.strike(pocong, 1.0, Vector2.RIGHT, 3.0, 0.0, "round")
	check(pocong.tripped(), "a hard hit didn't knock the pocong flat")
	var soft := arena.add_creature(Vector2(3.0, 3.0), "pocong")
	arena.strike(soft, 1.0, Vector2.RIGHT, 0.5, 0.0, "round")
	check(not soft.tripped(), "a soft hit knocked the pocong flat")


func test_a_smoke_monkey_leaps_and_hides_in_its_smoke() -> void:
	var arena := _arena()
	var monkey := arena.add_creature(arena.cats[0].body.position + Vector2(2.0, 0.0), "monkey")
	var smoked := false
	for step in 60 * 3:
		arena.step()
		if not arena.smoke.is_empty():
			smoked = true
			break
	check(smoked, "the monkey never landed in smoke")
	monkey.state = Creature.State.RECOVERING
	monkey.body.position = arena.smoke[0].position
	monkey.body.velocity = Vector2.ZERO
	var from_far := monkey.body.position + Vector2(5.0, 0.0)
	check(arena.target_for(from_far, 10.0, "nearest") != monkey, "the monkey was made out in its smoke from 5 m")
	check(arena.target_for(monkey.body.position + Vector2(0.6, 0.0), 10.0, "nearest") == monkey, "the monkey couldn't be made out right beside it")


func test_spirits_come_in_their_mix_and_packs() -> void:
	var arena := Arena.new()
	arena.begin_grove(7)
	arena.add_cat(arena.size / 2.0).health = 1.0e9
	var kinds := {}
	for step in 60 * 75:
		arena.step()
		for creature in arena.creatures:
			kinds[creature.kind] = true
	for kind: String in ["wisp", "tuyul", "pocong", "sapling", "monkey"]:
		check(kinds.has(kind), "no %s came in 75 seconds" % kind)
	check(not kinds.has("rat") and not kinds.has("dog"), "the company's creatures came to a grove: %s" % str(kinds.keys()))
	check(arena.giants.is_empty(), "a worker came to a grove")


func test_a_grove_is_laid_out_from_its_seed() -> void:
	var first := Arena.new()
	first.begin_grove(1234)
	var again := Arena.new()
	again.begin_grove(1234)
	check(first.size == again.size and first.obstacles.size() == again.obstacles.size(), "the same seed laid out two groves")
	for index in first.obstacles.size():
		check(first.obstacles[index].center == again.obstacles[index].center, "obstacle %d moved" % index)
	var themes := {}
	for seed_value in 12:
		themes[Areas.grove(seed_value).id] = true
	check(themes.size() == Areas.GROVES.size(), "twelve seeds laid out only %s" % str(themes.keys()))


func test_nothing_walks_into_the_river() -> void:
	var arena := Arena.new()
	var seed_value := Areas.GROVES.find(Areas.GROVES.filter(func(grove: Dictionary) -> bool: return grove.id == "riverbank")[0])
	arena.begin_grove(seed_value)
	var cat := arena.add_cat(Vector2(arena.size.x / 2.0, arena.size.y - 3.0))
	cat.health = 1.0e9
	cat.weapons.clear()
	cat.steering = Vector2.DOWN
	_steps(arena, 60 * 3)
	check(cat.body.position.y < arena.size.y - 1.75, "he walked into the river, to %.2f" % cat.body.position.y)


func test_the_siege_is_fought_among_the_houses() -> void:
	var arena := _siege()
	check(arena.size == VillageMap.SIZE, "the siege is %s, not the village" % arena.size)
	check(arena.solid_at(VillageMap.LONGHOUSE.get_center()), "the longhouse doesn't stand in the siege")
	check(not arena.solid_at(arena.area.start), "he starts in a wall")


func test_the_roofs_catch_one_after_another() -> void:
	var arena := _siege()
	arena.step()
	check(arena.roofs.filter(func(roof: Dictionary) -> bool: return roof.lit).size() == 2, "two roofs aren't alight at the start")
	_steps(arena, int(60 * (Areas.named("siege").goal.light_every * 2 + 1)))
	check(arena.roofs.all(func(roof: Dictionary) -> bool: return roof.lit), "a roof never caught")


func test_a_burning_roof_throws_out_embers() -> void:
	var arena := _siege()
	arena.cats[0].body.position = Vector2(30.0, 9.0)
	_steps(arena, int(60 * (Arena.EMBER_EVERY + 0.5)))
	check(arena.creatures.filter(func(creature: Creature) -> bool: return creature.kind == "wisp").size() >= 2, "no embers came off the burning roofs")


func test_water_from_the_well_puts_a_fire_out() -> void:
	var arena := _siege()
	var cat := arena.cats[0]
	cat.body.position = Vector2(arena.well.get_center().x, arena.well.end.y + 0.3)
	_steps(arena, int(60 * (Arena.FILL_TIME + 0.2)))
	check(cat.water, "no bucket filled at the well")
	var roof: Dictionary = arena.roofs[0]
	cat.body.position = roof.door
	_steps(arena, int(60 * (Arena.DOUSE_TIME + 0.2)))
	check(roof.out and not cat.water, "the fire's still burning, or the bucket's still full")
	check(arena.goal_progress() == Vector2(1, 4), "the goal stands at %s" % arena.goal_progress())


func test_without_water_a_fire_burns_on() -> void:
	var arena := _siege()
	var cat := arena.cats[0]
	cat.body.position = arena.roofs[0].door
	_steps(arena, 60 * 3)
	check(not arena.roofs[0].out, "a fire went out with no water")


func test_every_fire_out_brings_inyiak_balang() -> void:
	var arena := _siege()
	arena.step()
	for roof in arena.roofs:
		roof.lit = true
		roof.out = true
	arena.step()
	check(arena.goal_done and arena.boss is Guardian, "the fires are out and the guardian didn't come")


func _guardian(at := Vector2(10.0, 12.0)) -> Arena:
	var arena := _arena()
	var guardian := Guardian.new()
	guardian.body.position = at
	guardian.roar_in = 1.0e6
	arena.giants.append(guardian)
	return arena


## Steps until it crouches to pounce, holding him where he is.
func _until_it_crouches(arena: Arena, guardian: Guardian, at: Vector2) -> void:
	for step in 60 * 4:
		arena.cats[0].body.position = at
		arena.step()
		if guardian.move == Guardian.Move.CROUCHING:
			return


func test_its_pounce_lands_where_he_stood() -> void:
	var arena := _guardian()
	var cat := arena.cats[0]
	var guardian: Guardian = arena.giants[0]
	_until_it_crouches(arena, guardian, Vector2(14.0, 12.0))
	check(guardian.move == Guardian.Move.CROUCHING, "it didn't crouch with him in reach, but %d" % guardian.move)
	var marked := guardian.pounce_to
	var health := cat.health
	_steps(arena, 90)
	check(guardian.body.position.distance_to(marked) < 0.4, "it landed %.2f m from where it marked" % guardian.body.position.distance_to(marked))
	check(cat.health < health, "landing on him didn't hurt")


func test_out_from_under_a_pounce_is_safe() -> void:
	var arena := _guardian()
	var cat := arena.cats[0]
	var guardian: Guardian = arena.giants[0]
	_until_it_crouches(arena, guardian, Vector2(14.0, 12.0))
	check(guardian.move == Guardian.Move.CROUCHING, "it didn't crouch")
	cat.body.position = Vector2(14.0, 16.0)
	var health := cat.health
	for step in 90:
		arena.step()
		if guardian.move == Guardian.Move.GATHERING:
			break
	check(cat.health == health, "it hurt him out from under the pounce")


func test_hits_land_double_while_it_gathers_itself() -> void:
	var guardian := Guardian.new()
	guardian.take(10.0, Vector2.RIGHT)
	var plain := Guardian.HEALTH - guardian.health
	guardian.move = Guardian.Move.GATHERING
	var before := guardian.health
	guardian.take(10.0, Vector2.RIGHT)
	check(is_equal_approx(before - guardian.health, plain * 2.0), "gathering, a hit took %.1f, not %.1f" % [before - guardian.health, plain * 2.0])


func test_its_roar_throws_him_back_and_calls_embers() -> void:
	var arena := _guardian()
	var cat := arena.cats[0]
	var guardian: Guardian = arena.giants[0]
	cat.body.position = guardian.body.position + Vector2(1.6, 0.0)
	guardian.roar_in = 0.0
	arena.step()
	check(guardian.move == Guardian.Move.ROARING, "it didn't roar")
	check(cat.body.velocity.x > 1.0, "the roar didn't throw him back")
	check(arena.creatures.filter(func(creature: Creature) -> bool: return creature.kind == "wisp").size() == Guardian.ROAR_CALLS, "the roar called no embers")


func test_beaten_it_lies_down_and_the_village_is_safe() -> void:
	var arena := _siege()
	arena.goal_done = true
	arena._bring_in_the_boss()
	var guardian: Guardian = arena.boss
	arena.strike(guardian, 1.0e6, Vector2.RIGHT, 0.0, 0.0, "round")
	_steps(arena, 60 * 2)
	check(guardian.move == Guardian.Move.LYING and guardian in arena.giants, "it didn't lie down where it was beaten")
	check(arena.liberated, "beating it didn't end the siege")


func test_peace_with_the_forest_raises_the_shrine_and_moves_endless_there() -> void:
	var village := Village.new()
	for id in Areas.ids():
		if id != "siege":
			village.liberate(id)
	check(village.next_area() == "siege", "after the airstrip, the next run is %s" % village.next_area())
	check(not village.truce(), "peace before the siege")
	village.liberate("siege")
	village.catch_up()
	check(village.truce() and village.is_restored("shrine"), "no peace, or no shrine, after the siege")
	check(village.next_area() == "endless", "after the siege, the next run is %s" % village.next_area())
	var map := VillageMap.new([], village.restored)
	check(map.buildings.any(func(building: Dictionary) -> bool: return building.name == "shrine"), "the shrine doesn't stand in the village")


func test_the_shrine_can_be_reached() -> void:
	var map := VillageMap.new([], ["shrine"])
	map.cat.body.position = VillageMap.HOME_SPOT
	map.walk_to(VillageMap.door_step(VillageMap.SHRINE))
	for step in 60 * 20:
		map.step(Arena.STEP)
	check(map.at_door() == "shrine", "he couldn't get to the shrine's door, stuck at %s" % map.cat.body.position)
