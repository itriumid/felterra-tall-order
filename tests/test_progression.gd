extends TestCase
## Progression from the village: a run starts with weapons and nothing else, the smith forges more,
## freeing an area teaches its dodge mutations, and anything had can be packed or left home. Every
## thing has its story, and every story and scene line fits where it's shown. Leaving the village,
## he's seen off.

## How wide a cutscene's line can be, in pixels: the screen, less a margin either side.
const LINE_WIDTH := 640 - 16


func test_a_new_village_sends_her_out_with_six_weapons_and_five_pieces_of_gear() -> void:
	var village := Village.new()
	var cat := Cat.new()
	cat.wear({"weapons": ["knife"]})
	cat.locked.append_array(village.locked_for_run())
	var offered := Upgrades.available(cat)
	for id in offered:
		var item := Upgrades.evolves_from(id) if id.begins_with("evolve:") else id.get_slice(":", 1)
		var kind := "gear" if id.begins_with("gear") else "weapon"
		check(("%s:%s" % [kind, Upgrades._family(item) if kind == "weapon" else item]) in Village.STARTING, "%s was offered before anything was forged or taught" % id)
	var kinds := {"weapon": 0, "gear": 0}
	for id in Village.STARTING:
		kinds[id.get_slice(":", 0)] += 1
	check(kinds.weapon == Village.keep_packed("weapon") and kinds.gear >= 5, "a new village starts with %s" % str(kinds))
	check("weapon:golok" in offered and "gear:caping" in offered, "what he starts with wasn't offered")


func test_she_can_level_up_all_run_with_what_she_starts_with() -> void:
	var village := Village.new()
	var random := RandomNumberGenerator.new()
	random.seed = 39
	var cat := Cat.new()
	cat.wear({"weapons": ["knife"]})
	cat.locked.append_array(village.locked_for_run())
	for level in 60:
		var offer := Upgrades.offer(cat, random)
		check(offer.size() == Upgrades.CHOICES, "an offer came up short at level %d" % level)
		if offer.is_empty():
			return
		Upgrades.apply(cat, offer[0])


func test_too_few_packed_and_nothing_more_is_left_home() -> void:
	var village := Village.new()
	check(not village.repack("weapon:golok") and village.packed("weapon:golok"), "the golok was left home with only six weapons packed")
	check(not village.repack("weapon:nunchaku"), "the nunchaku he starts with was left home")
	village.forged.append("weapon:machete")
	check(village.repack("weapon:golok") and not village.packed("weapon:golok"), "with seven weapons, the golok couldn't be left home")
	check(not village.repack("weapon:machete"), "a weapon was left home, leaving five")
	for kind in ["weapon", "gear", "support", "mutation"]:
		check(Village.keep_packed(kind) == 3 * Village.places(kind), "%d %s kept packed, for %d places" % [Village.keep_packed(kind), kind, Village.places(kind)])
	check(Village.places("weapon") == 2 and Village.places("gear") == 7 and Village.places("support") == 2 and Village.places("mutation") == 1, "a run's places are counted wrong")


func test_freeing_an_area_teaches_its_mutations() -> void:
	var village := Village.new()
	check(village.learned().is_empty(), "he knew mutations before anyone taught him")
	check(not village.packed("mutation:rolling_slash"), "rolling slash was packed before it was taught")
	village.liberate("edge")
	check(village.learned().is_empty(), "freeing the edge taught him before anyone had said a word")
	# Its lessons wait with the cat who teaches them, one a mutation: heard, each is learned.
	village.set_lessons("edge")
	var lessons := village.tidings.filter(func(tiding: Dictionary) -> bool: return (tiding.get("teaches", "") as String).begins_with(Village.LEARN))
	check(lessons.size() == 2 and lessons.all(func(tiding: Dictionary) -> bool: return tiding.at == "elder"), "the edge's two lessons aren't waiting with the Elder: %s" % [lessons])
	check((lessons[0].text as String).contains("Roll through it") and (lessons[1].text as String).contains("fall rolling"), "each lesson doesn't carry the Elder's own words for it")
	village.hear("elder")
	check("mutation:rolling_slash" in village.learned() and "mutation:land_on_feet" in village.learned(), "hearing the Elder's lessons taught %s" % str(village.learned()))
	village.set_lessons("edge")
	check(not village.has_tidings("elder"), "a lesson learned was set to be heard again")
	var cat := Cat.new()
	cat.locked.append_array(village.locked_for_run())
	check("mutation:rolling_slash" in Upgrades.available(cat), "a taught mutation wasn't offered")
	check(not "mutation:pounce" in Upgrades.available(cat), "the pounce was offered before the deep forest was freed")


func test_every_mutation_is_taught_somewhere() -> void:
	var taught: Array[String] = []
	for id in Areas.ids():
		taught.append_array(Areas.teaches(id))
	for mutation: String in Upgrades.MUTATIONS:
		check(mutation in taught, "no area teaches %s" % mutation)


func test_what_she_has_can_be_left_home() -> void:
	var village := Village.new()
	village.salvage = 100
	village.restored.append("smithy")
	village.forge("weapon:machete")
	check(village.packed("weapon:machete"), "a forged machete wasn't packed")
	check(village.repack("weapon:machete") and not village.packed("weapon:machete"), "the machete couldn't be left home")
	var cat := Cat.new()
	cat.locked.append_array(village.locked_for_run())
	check(not "weapon:machete" in Upgrades.available(cat), "a machete left home was offered")
	check(village.repack("weapon:machete") and village.packed("weapon:machete"), "the machete couldn't be packed again")
	check(not village.repack("weapon:rifle"), "an unforged rifle was packed")


func test_gear_is_worn_from_the_start_and_put_back() -> void:
	var village := Village.new()
	village.salvage = 200
	village.restored.append("smithy")
	village.forge("gear:vest")
	village.repack("gear:vest")
	check(village.starting_piece == "gear:vest" and village.packed("gear:vest"), "the vest wasn't worn from the start")
	village.repack("gear:caping")
	check(village.starting_piece == "gear:caping" and village.packed("gear:vest"), "wearing the caping didn't put the vest back in the pack")
	# With too little gear to leave any home, worn from the start goes back to the pack.
	village.repack("gear:caping")
	check(village.packed("gear:caping") and village.starting_piece.is_empty(), "the caping was left home with too little gear packed")


func test_with_gear_enough_a_piece_is_left_home() -> void:
	var village := Village.new()
	for id: String in Upgrades.GEAR:
		if not "gear:" + id in Village.STARTING:
			village.forged.append("gear:" + id)
	# More gear than there is today: a test stands in for what's still to be built.
	var keep := Village.keep_packed("gear")
	var have := village.everything().filter(func(id: String) -> bool: return id.begins_with("gear:") and village.has(id)).size()
	if have <= keep:
		check(not village.repack("gear:caping") or village.starting_piece == "gear:caping", "gear was left home with %d packed, keeping %d" % [have, keep])
		return
	village.repack("gear:caping")
	village.repack("gear:caping")
	check(not village.packed("gear:caping"), "with gear enough, the caping wasn't left home")


func test_what_is_left_home_is_kept() -> void:
	var village := Village.new()
	village.forged.assign(["weapon:rifle", "gear:boots"])
	village.left_home.assign(["weapon:rifle", "not_a_thing"])
	var path := "user://test_village_left_home.cfg"
	village.save(path)
	var loaded := Village.new()
	loaded.load_from(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(loaded.left_home == ["weapon:rifle"], "left home came back as %s" % str(loaded.left_home))
	loaded.clear()
	check(loaded.left_home.is_empty(), "a reset kept what was left home")


func test_everything_has_its_story() -> void:
	var cards: Array[String] = Village.everything()
	for from: String in Upgrades.EVOLVES:
		for grown: String in Upgrades.EVOLVES[from]:
			cards.append("weapon:" + grown)
	for id in cards:
		var story := Lore.of(id.get_slice(":", 0), id.get_slice(":", 1))
		check(not story.is_empty(), "%s has no story" % id)
		var does: String = Upgrades.describe({"id": id, "rarity": 0}).does
		check(not does.is_empty(), "%s doesn't say what it does" % id)
		check(Overlay.wrapped(does, 320 - 24).size() + Overlay.wrapped(story, 320 - 24).size() <= Overlay.STORY_LINES, "%s's story and what it does are too long for the smithy" % id)
	for id: String in Lore.STORIES:
		check(id in cards, "a story for %s, which isn't anything" % id)


func test_every_card_carries_its_story() -> void:
	check(not (Upgrades.describe({"id": "evolve:knife", "rarity": 0}).story as String).is_empty(), "the keris's card has no story")
	check(not (Upgrades.describe({"id": "mutation:pounce", "rarity": 0}).story as String).is_empty(), "the pounce's card has no story")


func test_every_line_of_the_story_fits_the_screen() -> void:
	var lines: Array = []
	for area in Areas.LIST:
		lines.append_array(area.before)
		lines.append_array(area.after)
		lines.append_array(area.send_off)
		lines.append_array(area.get("again", []))
		lines.append_array(area.get("teaches", {}).get("lines", []))
	lines.append_array(load("res://game/main.gd").INTRO)
	for line: Variant in lines:
		if line is Dictionary:
			check(Overlay.wrapped(line.text, Overlay.BUBBLE_WIDTH).size() <= 3, "too long for a bubble: %s" % line.text)
		else:
			check(PixelFont.width(line) <= LINE_WIDTH, "too wide for the screen: %s" % line)
	for pool: String in Cage.SAYS:
		for line: String in Cage.SAYS[pool]:
			check(Overlay.wrapped(line, Overlay.BUBBLE_WIDTH).size() <= 3, "too long for a bubble: %s" % line)


func test_whoever_speaks_is_in_the_village_by_then() -> void:
	var village := Village.new()
	for area in Areas.LIST:
		# Who's home before he leaves for it, and before he's taught what freeing it teaches. The
		# Elder and Jogiboy always are.
		var home := ["elder", "jogiboy"]
		for cat: Dictionary in village.cats:
			home.append(cat.name)
		for line: Variant in area.send_off:
			if line is Dictionary:
				check(line.by in home, "%s sees him off to %s before coming home" % [line.by, area.name])
		village.liberate(area.id)
		home = ["elder", "jogiboy"]
		for cat: Dictionary in village.cats:
			home.append(cat.name)
		for line: Variant in area.get("teaches", {}).get("lines", []):
			if line is Dictionary:
				check(line.by in home, "%s teaches after %s, but isn't home" % [line.by, area.name])


func test_every_area_has_a_send_off() -> void:
	for area in Areas.LIST:
		check(not (area.send_off as Array).is_empty(), "nobody sees him off to %s" % area.name)


func test_she_is_seen_off_out_of_sight() -> void:
	var cats: Array = []
	for index in 5:
		cats.append({"name": Cage.NAMES[index], "coat": "gray"})
	var map := VillageMap.new(cats)
	map.cat.body.position = Vector2(VillageMap.EXIT_FROM + 0.1, VillageMap.RETURN_SPOT.y)
	check(map.leaving(), "he wasn't leaving through the gate")
	var amble_to := map._amble_to.duplicate()
	map.see_off(["elder", Cage.NAMES[1]])
	check(map._amble_to[0] == amble_to[0], "a villager with nothing to say came to see him off")
	for step in 60 * 20:
		map.step(Arena.STEP)
	check(map.gone(), "he was seen off and never left, stopping at %s" % map.cat.body.position)
	var speaker := map.villagers[1]
	check(speaker.body.position.distance_to(VillageMap.SEE_OFF_SPOT) < 0.5, "the villager with a word for him didn't come to the gate, stopping at %s" % speaker.body.position)
	check(speaker.facing.x > 0.0, "the villager at the gate looked away as he left")
	check(map.elder.body.position.distance_to(VillageMap.ELDER_AT_THE_GATE) < 0.5, "the Elder didn't walk him to the gate")


func test_everyone_who_speaks_in_a_cutscene_has_a_portrait() -> void:
	var lines: Array = []
	for area in Areas.LIST:
		lines.append_array(area.send_off)
		lines.append_array(area.get("teaches", {}).get("lines", []))
	lines.append_array(load("res://game/main.gd").INTRO)
	for line: Variant in lines:
		if line is Dictionary:
			check(Portraits.has(line.by), "%s speaks, but has no portrait" % line.by)
			check(line.get("mood", "neutral") in Portraits.MOODS, "%s says a line in a mood there isn't: %s" % [line.by, line.get("mood")])


func test_every_portrait_is_the_same_size_in_every_mood() -> void:
	for who: String in Portraits.CAST.keys() + ["jogiboy"]:
		for mood in Portraits.MOODS:
			check(Sprites.image(Portraits.art(who, mood)).get_size() == Vector2i(40, 40), "%s's %s portrait isn't 40 by 40" % [who, mood])



func test_a_run_starts_empty_pawed_and_its_first_level_deals_a_weapon_from_the_pack() -> void:
	var arena := Arena.new()
	arena.spawning = false
	var cat := arena.add_cat(Vector2(10.0, 10.0))
	cat.wear({"weapons": []})
	cat.first_pool.assign(["golok", "slingshot", "machete", "ketapel"])
	cat.first_pool.erase("slingshot")
	arena.head_start = true
	# Experience trickles in from the start: the first level comes in its own time, no sooner.
	for step in roundi(Arena.HEAD_START_TIME * 60.0 * 0.5):
		arena.step()
	check(arena.level == 1 and arena.experience > 0, "halfway through the head start, level %d with %d experience" % [arena.level, arena.experience])
	for step in roundi(Arena.HEAD_START_TIME * 60.0 * 0.5) + 2:
		arena.step()
	check(arena.level == 2 and not arena.head_start, "the head start ended at level %d" % arena.level)
	check(cat.offers.size() == 1, "the first level dealt %d hands" % cat.offers.size())
	var hand: Array = cat.offers[0]
	for choice: Dictionary in hand:
		check(choice.id.trim_prefix("weapon:") in cat.first_pool and choice.rarity == Upgrades.Rarity.COMMON and choice.get("first", false),
			"the first hand dealt %s, not a common weapon from the pack" % choice)
	check(hand.size() == 3, "the first hand held %d" % hand.size())
	# Its redraw is its own: the run's rerolls are left alone.
	var rerolls := cat.rerolls
	check(cat.reroll(arena.random) and cat.rerolls == rerolls and cat.first_redraws == 0, "the first redraw spent the run's rerolls")
	check(cat.play(0) and cat.weapons.size() == 1, "playing the first hand gave him no weapon")


func test_the_papers_and_the_endings_fit_the_screen_too() -> void:
	var lines: Array = Areas.SIGN_LATER.duplicate()
	for area in Areas.LIST:
		lines.append_array(area.get("after_written", []))
		lines.append_array(area.get("send_off_written", []))
		if area.has("paper"):
			lines.append(area.paper.book)
			check(Overlay.wrapped(area.paper.found, Overlay.BUBBLE_WIDTH).size() <= 3, "too long for a bubble: %s" % area.paper.found)
	for line: Variant in lines:
		if line is Dictionary:
			check(Overlay.wrapped(line.text, Overlay.BUBBLE_WIDTH).size() <= 3, "too long for a bubble: %s" % line.text)
			check(Portraits.has(line.by), "%s speaks, but has no portrait" % line.by)
		else:
			check(PixelFont.width(line) <= LINE_WIDTH, "too wide for the screen: %s" % line)
	check(PixelFont.width("Five words, in their own letters: %s" % Areas.SIGN) <= LINE_WIDTH, "the five words don't fit the book's page")


func test_what_the_old_cats_say_fits_the_summary_and_is_heard_in_order() -> void:
	var titles := {}
	for saying in Lore.SAYINGS:
		check(not titles.has(saying.title), "two sayings are called %s" % saying.title)
		titles[saying.title] = true
		check(Overlay.wrapped(saying.text, 240.0).size() <= 3, "too long for the summary: %s" % saying.text)
	var village := Village.new()
	check(village.hear_saying().title == Lore.SAYINGS[0].title and village.hear_saying().title == Lore.SAYINGS[1].title, "the sayings don't come in their order")
	for index in Lore.SAYINGS.size() - 2:
		village.hear_saying()
	check(village.sayings.size() == Lore.SAYINGS.size(), "hearing them all kept %d of %d" % [village.sayings.size(), Lore.SAYINGS.size()])
	check(village.hear_saying().title == Lore.SAYINGS[0].title, "once they're all heard, they don't come round again")
	check(village.sayings.size() == Lore.SAYINGS.size(), "a saying heard again was kept twice")


## Freed, a place doesn't heal while he watches: it grows back a quarter a run, wherever the runs
## go, and is whole in four. One freed in a village kept before regrowth was is whole.
func test_a_freed_place_grows_back_over_runs_and_is_kept() -> void:
	var village := Village.new()
	check(village.healed("edge") == 0.0, "the company's ground has grown back")
	village.liberate("edge")
	check(village.healed("edge") == 0.0, "the edge grew back the moment it was freed")
	village.time_passes()
	check(is_equal_approx(village.healed("edge"), 0.25), "a run on, the edge has grown back %.2f" % village.healed("edge"))
	var path := "user://test_village_regrowing.cfg"
	village.save(path)
	var loaded := Village.new()
	loaded.load_from(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(is_equal_approx(loaded.healed("edge"), 0.25), "kept, the edge came back %.2f grown" % loaded.healed("edge"))
	for run in Village.HEALS_IN:
		loaded.time_passes()
	check(loaded.healed("edge") == 1.0 and loaded.regrowing.is_empty(), "four runs on, the edge is %.2f grown and still listed" % loaded.healed("edge"))
	var older := Village.new()
	older.liberated.append("deep")
	check(older.healed("deep") == 1.0, "a place freed before regrowth isn't whole")
	loaded.clear()
	check(loaded.regrowing.is_empty(), "a reset kept what's growing back")


func test_regrowth_is_the_share_it_asks_for_and_grows_on_from_where_it_was() -> void:
	var size := Vector2i(400, 240)
	var quarter := GroundView.regrowth(size, 5, 0.25)
	var half := GroundView.regrowth(size, 5, 0.5)
	var grown_quarter := 0
	var grown_half := 0
	var lost := 0
	for y in range(0, size.y, 2):
		for x in range(0, size.x, 2):
			var early := quarter.get_pixel(x, y).a > 0.5
			var later := half.get_pixel(x, y).a > 0.5
			grown_quarter += 1 if early else 0
			grown_half += 1 if later else 0
			lost += 1 if early and not later else 0
	var cells := (size.x / 2) * (size.y / 2)
	check(absf(grown_quarter / float(cells) - 0.25) < 0.02 and absf(grown_half / float(cells) - 0.5) < 0.02, "grew back %.2f and %.2f" % [grown_quarter / float(cells), grown_half / float(cells)])
	check(lost == 0, "%d patches grown back by a quarter were bare again at a half" % lost)
