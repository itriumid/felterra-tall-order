extends TestCase
## Level-up cards: kills fill the crew's experience, each level hands every cat an offer of three,
## rarity changes only how much a choice gives, and what's offered fits what he carries.


func _quiet() -> Arena:
	var arena := Arena.new()
	arena.spawning = false
	return arena


func test_kills_level_the_crew_up_and_each_cat_gets_an_offer() -> void:
	var arena := _quiet()
	var first := arena.add_cat(Arena.SIZE / 2.0)
	var second := arena.add_cat(Arena.SIZE / 2.0 + Vector2(1.0, 0.0))
	for index in Arena.experience_needed(1):
		arena._gain_experience(1)
	check(arena.level == 2, "the crew is level %d" % arena.level)
	check(first.offers.size() == 1 and second.offers.size() == 1, "offers: %d and %d" % [first.offers.size(), second.offers.size()])
	check((first.offers[0] as Array).size() == Upgrades.CHOICES, "an offer of %d choices" % (first.offers[0] as Array).size())


func test_offers_wait_until_played() -> void:
	var arena := _quiet()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.offers.append(Upgrades.offer(cat, arena.random))
	cat.offers.append(Upgrades.offer(cat, arena.random))
	for step in 60 * 30:
		arena.step()
	check(cat.offers.size() == 2, "offers expired: %d left" % cat.offers.size())
	check(cat.play(0), "couldn't play an offer")
	check(cat.offers.size() == 1, "playing didn't take the oldest offer")


func test_rarity_changes_how_much_never_what() -> void:
	var common := Cat.new()
	var legendary := Cat.new()
	Upgrades.apply(common, {"id": "gear:gloves", "rarity": Upgrades.Rarity.COMMON})
	Upgrades.apply(legendary, {"id": "gear:gloves", "rarity": Upgrades.Rarity.LEGENDARY})
	check(common.attack_speed_bonus > 0.0, "common gloves did nothing")
	check(is_equal_approx(legendary.attack_speed_bonus / common.attack_speed_bonus, Upgrades.AMOUNTS[3]), "legendary gave %.2f times common" % (legendary.attack_speed_bonus / common.attack_speed_bonus))
	check(is_equal_approx(legendary.damage_bonus / common.damage_bonus, Upgrades.AMOUNTS[3]), "rarity scaled one stat and not the other")
	check(legendary.armor == 0.0 and legendary.luck == 0.0, "legendary gloves gave stats gloves don't give")


func test_stats_only_come_from_gear() -> void:
	var cat := Cat.new()
	for id in Upgrades.available(cat):
		check(id.begins_with("gear:") or id.begins_with("level:") or id.begins_with("weapon:") or id.begins_with("mutation:") or id.begins_with("support:"), "%s is offered on its own" % id)


func test_the_same_gear_again_levels_it_up() -> void:
	var cat := Cat.new()
	Upgrades.apply(cat, {"id": "gear:boots", "rarity": Upgrades.Rarity.COMMON})
	check("gear_level:boots" in Upgrades.available(cat), "boots worn weren't offered a level")
	check(not Upgrades.available(cat).any(func(id: String) -> bool: return id == "gear:boots"), "boots were offered twice")
	var speed := cat.speed_bonus
	Upgrades.apply(cat, {"id": "gear_level:boots", "rarity": Upgrades.Rarity.COMMON})
	check(cat.gear_levels.boots == 2 and cat.speed_bonus > speed, "a level of boots gave nothing")


func test_one_item_per_slot() -> void:
	var cat := Cat.new()
	Upgrades.apply(cat, {"id": "gear:caping", "rarity": Upgrades.Rarity.COMMON})
	check(not "gear:hard_hat" in Upgrades.available(cat), "a second hat was offered over the caping")


func test_unfamiliar_stats_are_explained() -> void:
	var card := Upgrades.describe({"id": "gear:jamu_flask", "rarity": Upgrades.Rarity.COMMON})
	check(card.unfamiliar, "adrenaline wasn't marked as worth reading")
	check(card.explain.any(func(line: String) -> bool: return line.begins_with("Adrenaline:")), "adrenaline wasn't explained")


func test_luck_makes_rarer_cards_likelier() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 7
	var plain := 0
	var lucky := 0
	for roll in 4000:
		plain += 1 if Upgrades.roll_rarity(random, 0.0) >= Upgrades.Rarity.RARE else 0
		lucky += 1 if Upgrades.roll_rarity(random, 2.0) >= Upgrades.Rarity.RARE else 0
	check(lucky > plain * 1.5, "luck barely helped: %d rare against %d" % [lucky, plain])


func test_weapons_are_only_offered_if_the_paws_are_free() -> void:
	var cat := Cat.new()
	cat.wear({"weapons": ["knife", "handgun"]})
	var offered := Upgrades.available(cat)
	check(not offered.any(func(id: String) -> bool: return id.begins_with("weapon:")), "a third weapon was offered for two full paws")
	var one := Cat.new()
	one.wear({"weapons": ["knife"]})
	check("weapon:handgun" in Upgrades.available(one), "a free tail wasn't offered a handgun")
	check(not "weapon:knife" in Upgrades.available(one), "he was offered the knife he holds")


func test_gear_is_worn_when_chosen_and_not_offered_again() -> void:
	var cat := Cat.new()
	Upgrades.apply(cat, {"id": "gear:vest", "rarity": Upgrades.Rarity.COMMON})
	check(cat.gear.get("body", "") == "vest", "the vest wasn't worn")
	check(cat.armor > 0.0, "the vest gave no armor")
	check(not "gear:vest" in Upgrades.available(cat), "the vest was offered again")


func test_a_banished_choice_never_comes_back() -> void:
	var arena := _quiet()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.offers.append(Upgrades.offer(cat, arena.random))
	var gone: String = cat.offers[0][0].id
	check(cat.banish(0, arena.random), "couldn't banish")
	check((cat.offers[0] as Array).size() == Upgrades.CHOICES, "banishing left the offer short")
	for index in 50:
		var offer := Upgrades.offer(cat, arena.random)
		check(not offer.any(func(choice: Dictionary) -> bool: return choice.id == gone), "%s came back" % gone)


func test_rerolls_run_out() -> void:
	var arena := _quiet()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.offers.append(Upgrades.offer(cat, arena.random))
	for index in cat.rerolls:
		check(cat.reroll(arena.random), "a reroll was refused")
	check(not cat.reroll(arena.random), "rerolled with none left")


func test_stats_do_what_they_say() -> void:
	var arena := _quiet()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.raise("armor", 0.5)
	cat.hurt(1.0, Vector2.ZERO)
	check(is_equal_approx(cat.health, Cat.MOST_HEALTH - 0.5), "armor 0.5 let %.2f of a 1 through" % (Cat.MOST_HEALTH - cat.health))
	cat.raise("regeneration", 1.0)
	for step in 30:
		arena.step()
	check(cat.health > Cat.MOST_HEALTH - 0.5, "regeneration gave nothing back")
	var fast := Cat.new()
	fast.raise("attack_speed", 1.0)
	check(is_equal_approx(fast.weapons[0].interval_for(fast), fast.weapons[0].interval / 2.0), "double attack speed didn't halve the interval")


func test_adrenaline_gives_back_a_share_of_damage_dealt() -> void:
	var arena := _quiet()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.health = 5.0
	cat.raise("adrenaline", 0.1)
	var rat := arena.add_creature(cat.body.position + Vector2(3.0, 0.0))
	rat.health = 100.0
	arena.strike(rat, 2.0, Vector2.RIGHT, 0.0, 0.0, "round", cat)
	check(is_equal_approx(cat.health, 5.2), "dealing 2 at a tenth adrenaline healed to %.2f" % cat.health)


func test_adrenaline_gives_back_only_so_much_a_second() -> void:
	var arena := _quiet()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.health = 1.0
	cat.raise("adrenaline", 1.0)
	var rat := arena.add_creature(cat.body.position + Vector2(3.0, 0.0))
	rat.health = 1000.0
	for hit in 20:
		arena.strike(rat, 5.0, Vector2.RIGHT, 0.0, 0.0, "round", cat)
	var most := cat.max_health * Cat.ADRENALINE_MOST
	check(is_equal_approx(cat.health, 1.0 + most), "a burst of hits gave back %.2f, not a second's most of %.2f" % [cat.health - 1.0, most])
	# A second on, it has another second's worth to give.
	for step in 60:
		rat.body.position = cat.body.position + Vector2(3.0, 0.0)
		cat.step(Arena.STEP, arena)
	var before := cat.health
	arena.strike(rat, 50.0, Vector2.RIGHT, 0.0, 0.0, "round", cat)
	check(is_equal_approx(cat.health, before + most), "a second later it gave back %.2f" % (cat.health - before))


func _play_levels(cat: Cat, random: RandomNumberGenerator, levels: int) -> Array[int]:
	var sizes: Array[int] = []
	for level in levels:
		var offer := Upgrades.offer(cat, random)
		sizes.append(offer.size())
		if offer.is_empty():
			break
		Upgrades.apply(cat, offer[random.randi_range(0, offer.size() - 1)])
	return sizes


func test_a_long_run_never_runs_out_of_upgrades() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 3
	var cat := Cat.new()
	cat.wear({"weapons": ["knife"]})
	var sizes := _play_levels(cat, random, 200)
	check(sizes.size() == 200 and sizes.all(func(size: int) -> bool: return size == Upgrades.CHOICES), "an offer came up short: %s" % str(sizes.filter(func(size: int) -> bool: return size < Upgrades.CHOICES)))


func test_power_keeps_growing_past_every_top_level() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 4
	var cat := Cat.new()
	cat.wear({"weapons": ["knife", "handgun"]})
	# Damage a second, not a hit: an evolution can trade a heavy hit for many lighter ones.
	_play_levels(cat, random, 80)
	var damage_at_80 := cat.weapons.map(func(weapon: Weapon) -> float: return weapon.hit_for(cat) / weapon.interval_for(cat))
	_play_levels(cat, random, 80)
	var damage_at_160 := cat.weapons.map(func(weapon: Weapon) -> float: return weapon.hit_for(cat) / weapon.interval_for(cat))
	check(damage_at_160.reduce(func(a: float, b: float) -> float: return a + b) > damage_at_80.reduce(func(a: float, b: float) -> float: return a + b), "eighty more levels made him no stronger")


## Plays every card a weapon's offered in turn, choosing the first bonus whenever it evolves:
## up to a level. Returns the ids played.
func _grow(cat: Cat, weapon_name: String, to_level: int) -> Array[String]:
	var played: Array[String] = []
	var random := RandomNumberGenerator.new()
	while cat.weapons[0].level < to_level:
		var mine := Upgrades.available(cat).filter(func(id: String) -> bool: return not id.begins_with("weapon:") and id.get_slice(":", 1).get_slice(">", 0) == cat.weapons[0].name)
		var id: String = mine[0]
		var choice := {"id": id, "rarity": Upgrades.Rarity.COMMON}
		if id.begins_with("evolve:"):
			choice.bonuses = Upgrades.bonus_choices(cat.weapons[0], random)
		Upgrades.apply(cat, choice)
		played.append(id)
		# An evolution deals its bonus hand first: the first of it is chosen.
		while not cat.offers.is_empty() and (cat.offers[0][0].id as String).begins_with("bonus:"):
			var bonus: Dictionary = cat.offers.pop_front()[0]
			Upgrades.apply(cat, bonus)
			played.append(bonus.id)
	return played


func test_every_weapon_evolves_at_five_and_ten_choosing_a_bonus_each_time() -> void:
	for weapon_name: String in Upgrades.WEAPONS:
		var cat := Cat.new()
		cat.wear({"weapons": [weapon_name]})
		var played := _grow(cat, weapon_name, 12)
		var evolutions := played.filter(func(id: String) -> bool: return id.begins_with("evolve:"))
		var bonuses := played.filter(func(id: String) -> bool: return id.begins_with("bonus:"))
		var weapon := cat.weapons[0]
		check(evolutions.size() == 2 and bonuses.size() == 2 and weapon.evolved == 2, "the %s evolved %d times with %d bonuses" % [weapon_name, evolutions.size(), bonuses.size()])
		check(weapon.bonuses.size() == 2 and weapon.bonuses[0] != weapon.bonuses[1], "the %s took bonuses %s" % [weapon_name, weapon.bonuses])
		check(not weapon.nickname_first.is_empty() and not weapon.nickname_second.is_empty(), "the %s earned no nicknames: %s" % [weapon_name, Upgrades.title_of(weapon)])
		check(Upgrades.title_of(weapon).contains('"'), "the %s is called %s" % [weapon_name, Upgrades.title_of(weapon)])
		# Past level 10, mastery, without limit.
		check(("mastery:" + weapon.name) in Upgrades.available(cat), "the %s wasn't offered mastery at level %d" % [weapon.name, weapon.level])


func test_a_knife_grows_into_a_kris_then_a_karambit_keeping_all_it_had() -> void:
	var cat := Cat.new()
	cat.wear({"weapons": ["knife"]})
	_grow(cat, "knife", 5)
	check(cat.weapons[0].name == "keris" and cat.weapons[0].level == 5, "at level 5 the knife was a %s at level %d" % [cat.weapons[0].name, cat.weapons[0].level])
	var taken := cat.weapons[0].bonuses.duplicate()
	var nickname := cat.weapons[0].nickname_first
	_grow(cat, "keris", 10)
	check(cat.weapons[0].name == "kerambit" and cat.weapons[0].bonuses.size() == 2 and cat.weapons[0].bonuses[0] == taken[0], "the karambit kept %s" % [cat.weapons[0].bonuses])
	check(cat.weapons[0].nickname_first == nickname, "the karambit lost its nickname")
	check(not "weapon:knife" in Upgrades.available(cat), "a knife was offered beside his karambit")


func test_an_evolution_offers_only_what_suits_how_it_fights() -> void:
	var random := RandomNumberGenerator.new()
	for weapon_name: String in Upgrades.WEAPONS:
		var weapon := Weapon.named(weapon_name)
		for draw in 20:
			var offered := Upgrades.bonus_choices(weapon, random)
			check(offered.size() == 3, "the %s was offered %s" % [weapon_name, offered])
			for bonus in offered:
				var fits: bool = bonus in Upgrades.BONUS_POOLS[Upgrades.form_of(weapon)] or (bonus in Upgrades.ELEMENTS and not bonus in Upgrades.elements_of(weapon))
				check(fits, "the %s (%s) was offered %s" % [weapon_name, Upgrades.form_of(weapon), bonus])


func test_full_health_never_reads_as_more_than_the_most() -> void:
	var cat := Cat.new()
	# Gear gives fractions of a point of health: an uncommon vest, a rare batik shirt.
	Upgrades.apply(cat, {"id": "gear:vest", "rarity": Upgrades.Rarity.UNCOMMON})
	Upgrades.apply(cat, {"id": "gear:batik_shirt", "rarity": Upgrades.Rarity.RARE})
	check(not is_equal_approx(cat.max_health, roundf(cat.max_health)), "the most health came out whole, %.2f, so this checks nothing" % cat.max_health)
	check(is_equal_approx(cat.health, cat.max_health), "he wasn't at full health")
	var shown := Overlay.health_text(cat.health, cat.max_health, "/").split("/")
	check(shown[0] == shown[1], "full health reads as %s" % "/".join(shown))
	check(Overlay.health_text(0.3, cat.max_health, "/").begins_with("1/"), "a sliver of health didn't read as one")
	# And only full health reads as full: a little short of it reads one short.
	check(Overlay.health_text(9.1, 10.0, "/") == "9/10", "9.1 of 10 reads as %s" % Overlay.health_text(9.1, 10.0, "/"))
	check(Overlay.health_text(9.99, 10.0, "/") == "9/10", "9.99 of 10 reads as %s" % Overlay.health_text(9.99, 10.0, "/"))
	check(Overlay.health_text(0.0, 10.0, "/") == "0/10", "no health left reads as %s" % Overlay.health_text(0.0, 10.0, "/"))
	check(Overlay.health_text(10.0, 10.0, "/") == "10/10", "full health reads as %s" % Overlay.health_text(10.0, 10.0, "/"))
	check(Overlay.health_text(41.2, 41.4, "/") == "41/42", "41.2 of 41.4 reads as %s" % Overlay.health_text(41.2, 41.4, "/"))
	# And healing never goes past the most: adrenaline and regeneration heal the same way.
	cat.adrenaline = 1.0
	cat.heal(1000.0)
	check(cat.health <= cat.max_health, "healing went past the most, to %.2f of %.2f" % [cat.health, cat.max_health])


## The room a card has for a line beside its picture, in pixels.
const CARD_LINE := 110


func test_a_weapon_card_says_what_it_does_in_numbers_and_fits() -> void:
	for weapon_name: String in Upgrades.WEAPON_NAMES:
		var weapon := Weapon.named(weapon_name)
		for rarity in Upgrades.RARITY_NAMES.size():
			var card := Upgrades.describe({"id": "weapon:" + weapon_name, "rarity": rarity})
			var lines: Array = card.lines
			check(lines.size() >= 2 and lines.size() <= 3, "the %s's card has %d lines" % [weapon_name, lines.size()])
			check((lines[0] as String).contains("m reach") and (lines[1] as String).contains("damage"), "the %s's card doesn't give its reach and damage: %s" % [weapon_name, lines])
			for line: String in lines:
				check(PixelFont.width(line) <= CARD_LINE, 'the %s\'s card line "%s" is %d pixels wide' % [weapon_name, line, PixelFont.width(line)])
		# What sets it apart is on the card, and explained when it's read in full.
		var card := Upgrades.describe({"id": "weapon:" + weapon_name, "rarity": 0})
		for trait_name in Upgrades.traits_of(weapon):
			check((card.lines as Array).size() == 3, "the %s's card leaves out what sets it apart" % weapon_name)
			if trait_name != "two_handed":
				check(Upgrades.TRAIT_MEANS.has(trait_name), 'nothing explains "%s"' % trait_name)


func test_a_card_says_what_a_weapon_s_numbers_are() -> void:
	var sickle := Upgrades.describe({"id": "weapon:celurit", "rarity": 0})
	check(sickle.lines == ["Swung, 0.6 m reach", "2.8 damage, 2.2 a second", "Trips 1.2 s"], "the sickle's card says %s" % [sickle.lines])
	check(sickle.ribbon == "Common, new", 'its ribbon says "%s"' % sickle.ribbon)
	var found := Upgrades.describe({"id": "weapon:shotgun", "rarity": 2})
	check(found.lines == ["Shot, 5 m reach", "1.6 damage, 1.1 a second", "Two-handed, 7 pellets"], "the shotgun's card says %s" % [found.lines])
	check(found.ribbon == "Rare, new, level 3", 'its ribbon says "%s"' % found.ribbon)


func test_a_bonus_card_says_what_it_does_to_this_weapon_and_fits() -> void:
	for weapon_name: String in Upgrades.WEAPON_NAMES:
		var weapon := Weapon.named(weapon_name)
		for bonus: String in Upgrades.BONUSES:
			var line := Upgrades.bonus_line(bonus, weapon)
			check(PixelFont.width(line) <= CARD_LINE, 'the bonus line "%s" is %d pixels wide' % [line, PixelFont.width(line)])
	check(Upgrades.bonus_line("more", Weapon.named("petasan")) == "One more pop", "one more, for firecrackers, isn't a pop")
	check(Upgrades.bonus_line("more", Weapon.named("ketapel")) == "One more bounce", "one more, for a slingshot, isn't a bounce")
	check(Upgrades.bonus_line("arc", Weapon.named("golok")) == "Arc 30% wider", "wider, for a blade, isn't its arc")
	check(Upgrades.bonus_line("arc", Weapon.named("lamp_oil")) == "Burst 30% wider", "wider, for lamp oil, isn't where it lands")
	# What an element does is what the card says it does.
	var blade := Weapon.named("golok")
	blade.take_bonus("bleed", false)
	check(Upgrades.bonus_line("bleed", blade) == "Bleeds: %.1f a second, 3 s" % blade.bleed, "the bleed on the card isn't the bleed it gives")
