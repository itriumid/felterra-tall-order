extends TestCase
## Dodge mutations: each changes what the dodge does. No more than three a run, a card for one she
## has strengthens it, and none of them is a stat.


func _arena() -> Arena:
	var arena := Arena.new()
	arena.spawning = false
	return arena


## A cat with nothing in her paws, so only her dodge does anything, and the mutations named.
func _cat(arena: Arena, mutations: Array[String], rarity := Upgrades.Rarity.COMMON) -> Cat:
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	for mutation in mutations:
		Upgrades.apply(cat, {"id": "mutation:" + mutation, "rarity": rarity})
	return cat


func _roll_out(arena: Arena, cat: Cat, steps := 30) -> void:
	for step in steps:
		arena.step()


func test_no_more_than_three_a_run() -> void:
	var cat := _cat(_arena(), ["pounce", "riposte", "long_leap"])
	var offered := Upgrades.available(cat)
	check(not offered.any(func(id: String) -> bool: return id.begins_with("mutation:")), "a fourth mutation was offered")
	for mutation in ["pounce", "riposte", "long_leap"]:
		check("mutation_up:" + mutation in offered, "%s wasn't offered to strengthen" % mutation)


func test_a_card_for_one_she_has_strengthens_it() -> void:
	var cat := _cat(_arena(), ["pounce"])
	Upgrades.apply(cat, {"id": "mutation_up:pounce", "rarity": Upgrades.Rarity.RARE})
	check(cat.mutations.size() == 1, "strengthening took another slot")
	check(is_equal_approx(cat.strength("pounce"), 1.0 + Upgrades.AMOUNTS[Upgrades.Rarity.RARE]), "pounce is %.2f strong" % cat.strength("pounce"))


func test_mutations_are_not_stats() -> void:
	var cat := _cat(_arena(), ["rolling_slash", "more_charges", "land_on_feet"], Upgrades.Rarity.LEGENDARY)
	var stats := [cat.armor, cat.regeneration, cat.adrenaline, cat.damage_bonus, cat.attack_speed_bonus, cat.reach_bonus, cat.speed_bonus, cat.luck]
	check(stats.all(func(value: float) -> bool: return value == 0.0) and cat.max_health == Cat.MOST_HEALTH, "a mutation raised a stat: %s" % str(stats))


func test_more_charges_holds_another_dodge() -> void:
	var cat := _cat(_arena(), ["more_charges"])
	check(cat.dodge() and cat.dodge(), "two charges didn't give two dodges")
	check(not cat.dodge(), "a third dodge with two charges")


func test_a_rarer_charge_card_brings_charges_back_faster() -> void:
	var common := _cat(_arena(), ["more_charges"])
	var legendary := _cat(_arena(), ["more_charges"], Upgrades.Rarity.LEGENDARY)
	check(common.most_charges() == legendary.most_charges(), "rarity changed how many charges, not how fast")
	check(legendary.recharge_time() < common.recharge_time(), "legendary charges come back no faster")


func test_rolling_slash_cuts_each_once_on_the_way_through() -> void:
	var arena := _arena()
	var cat := _cat(arena, ["rolling_slash"])
	var rat := arena.add_creature(cat.body.position + Vector2(0.4, 0.0))
	rat.health = 100.0
	cat.steering = Vector2.RIGHT
	cat.dodge()
	_roll_out(arena, cat)
	check(is_equal_approx(rat.health, 100.0 - Cat.SLASH_DAMAGE), "the roll took %.1f off a rat it passed" % (100.0 - rat.health))
	var plain := _arena()
	var rolling := _cat(plain, [])
	var spared := plain.add_creature(rolling.body.position + Vector2(0.4, 0.0))
	rolling.steering = Vector2.RIGHT
	rolling.dodge()
	_roll_out(plain, rolling)
	check(spared.health == Creature.KINDS.rat.health, "a plain roll cut a rat")


func test_pounce_leaps_onto_the_nearest_enemy() -> void:
	var arena := _arena()
	var cat := _cat(arena, ["pounce"])
	arena.add_creature(cat.body.position + Vector2(0.5, 2.0))
	cat.steering = Vector2.RIGHT
	cat.dodge()
	cat.steering = Vector2.ZERO
	var highest := 0.0
	for step in 60:
		arena.step()
		highest = maxf(highest, cat.body.height)
	check(highest > 0.15, "the pounce never left the ground (%.2f m)" % highest)
	check(arena.kills == 1, "the pounce didn't land on the rat")


func test_ankle_cutter_cuts_a_share_of_a_giant() -> void:
	var arena := _arena()
	var cat := _cat(arena, ["ankle_cutter"])
	var giant := arena.add_giant(cat.body.position + Vector2(0.7, 0.0))
	cat.steering = Vector2.RIGHT
	cat.dodge()
	_roll_out(arena, cat, 20)
	var expected := giant.most_health * (1.0 - Cat.ANKLE_SHARE)
	check(is_equal_approx(giant.health, expected), "his health is %.1f, not %.1f" % [giant.health, expected])


func test_land_on_your_feet_rolls_out_of_a_knock_for_free() -> void:
	var arena := _arena()
	var cat := _cat(arena, ["land_on_feet"])
	cat.hurt(1.0, Vector2(2.0, 0.0))
	var rolled := false
	for step in 40:
		arena.step()
		rolled = rolled or cat.dodging_for > 0.0
	check(rolled, "knocked down, she didn't roll")
	check(cat.dodge_charges >= 1.0, "the free roll spent a charge")
	var plain := _arena()
	var knocked := _cat(plain, [])
	knocked.hurt(1.0, Vector2(2.0, 0.0))
	var plain_rolled := false
	for step in 40:
		plain.step()
		plain_rolled = plain_rolled or knocked.dodging_for > 0.0
	check(not plain_rolled, "without it, a knock still ended in a roll")


func test_long_leap_goes_further_and_over_the_saw() -> void:
	var leaping_arena := _arena()
	var leaper := _cat(leaping_arena, ["long_leap"])
	var rolling_arena := _arena()
	var roller := _cat(rolling_arena, [])
	for cat in [leaper, roller]:
		cat.dodge()
	var highest := 0.0
	for step in 60:
		leaping_arena.step()
		rolling_arena.step()
		highest = maxf(highest, leaper.body.height)
	check(highest > Giant.SAW_HEIGHT, "the leap peaked at %.2f m, under the saw" % highest)
	var start := Arena.SIZE.x / 2.0
	check(leaper.body.position.x - start > (roller.body.position.x - start) * 1.4, "the leap went no further than a roll")
	# In the air above the saw's height, it passes under her.
	var arena := _arena()
	var cat := _cat(arena, ["long_leap"])
	var giant := arena.add_giant(cat.body.position + Vector2(-1.0, 0.0), "chainsaw")
	cat.steering = Vector2.UP
	cat.dodge()
	while cat.body.height < Giant.SAW_HEIGHT:
		arena.step()
	cat.safe_for = 0.0
	var toward := (cat.body.position - giant.body.position).angle()
	arena.saw(giant, toward - 0.3, toward + 0.3)
	check(cat.health == Cat.MOST_HEALTH, "the saw cut her in the air at %.2f m" % cat.body.height)


func test_riposte_strikes_back_when_a_dodged_hit_lands() -> void:
	var arena := _arena()
	var cat := _cat(arena, ["riposte"])
	for index in 4:
		arena.add_creature(cat.body.position + Vector2.from_angle(index * TAU / 4.0) * 0.5)
	cat.dodge()
	check(not cat.hurt(1.0, Vector2.ZERO), "the hit landed mid-roll")
	arena.step()
	check(arena.kills == 4, "the riposte felled %d of the 4 around her" % arena.kills)
	# Once a roll: a second hit dodged in the same roll doesn't strike back again.
	arena.add_creature(cat.body.position + Vector2(0.3, 0.0))
	cat.hurt(1.0, Vector2.ZERO)
	arena.step()
	check(arena.kills == 4, "she struck back twice in one roll")
