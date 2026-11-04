extends TestCase
## What's new in the village waits where it's told, under a "!", until he goes and hears it:
## Jogiboy keeps what he digs up until he's asked, and Uncle Anvil's word on starting weapons is what
## lets him choose them: one he swings and one he shoots.


func test_news_waits_where_its_told_until_heard() -> void:
	var village := Village.new()
	village.tell("smithy", "The smithy", "Forge things.")
	village.tell("smithy", "The smithy", "Forge things.")
	check(village.tidings.size() == 1, "the same news was told twice over")
	check(village.has_tidings("smithy") and not village.has_tidings("home"), "the news waits in the wrong place")
	var heard := village.hear("smithy")
	check(heard.size() == 1 and heard[0].title == "The smithy", "hearing it gave %s" % [heard])
	check(not village.has_tidings("smithy"), "the news was still waiting once heard")


func test_jogiboy_keeps_what_he_finds_until_asked() -> void:
	var village := Village.new()
	village.jogiboy_found += Village.JOGIBOY_FINDS
	check(village.salvage == 0 and village.has_tidings("jogiboy"), "Jogiboy's find went straight onto the pile, or he had nothing to say")
	village.hear("jogiboy")
	check(village.salvage == Village.JOGIBOY_FINDS and village.jogiboy_found == 0, "asked, Jogiboy handed over %d, keeping %d" % [village.salvage, village.jogiboy_found])
	check(not village.has_tidings("jogiboy"), "Jogiboy still had something once he'd handed it over")


func test_the_pack_is_the_first_draw() -> void:
	var village := Village.new()
	# Every weapon in the pack can be left home, the nunchaku and the handgun too, as long as enough
	# stay packed to draw from.
	village.forged.append("weapon:machete")
	check(village.repack("weapon:nunchaku") and not village.packed("weapon:nunchaku"), "the nunchaku couldn't be left home")
	check(not village.repack("weapon:handgun"), "the handgun was left home with too few weapons packed")
	var pool := village.packed_weapons()
	check(not "nunchaku" in pool and "machete" in pool and pool.size() == 6, "the pack dealt from %s" % [pool])
	# Uncle Anvil says so, once, at the smithy.
	village.tell("smithy", "Uncle Anvil", "Pack what you'd draw.", Village.PACK_TAUGHT)
	village.hear("smithy")
	check(Village.PACK_TAUGHT in village.told, "hearing Uncle Anvil didn't teach packing")


func test_news_comes_back_as_it_was_kept() -> void:
	var path := "user://test_village_tidings.cfg"
	var village := Village.new()
	village.tell("board", "On the map", "Choose it.")
	village.jogiboy_found = 4
	check(village.save(path), "couldn't save")
	var back := Village.new()
	back.load_from(path)
	check(back.has_tidings("board") and back.jogiboy_found == 4, "the news or Jogiboy's find didn't come back")
	# A village kept when a run started with chosen weapons still loads: what was chosen is simply
	# in the pack.
	var file := ConfigFile.new()
	file.load(path)
	file.set_value("village", "starters", ["weapon:knife", "weapon:handgun"])
	file.set_value("village", "told", ["teach:starters"])
	file.save(path)
	back.load_from(path)
	check(back.packed("weapon:knife") and not "teach:starters" in back.told, "an older village loaded wrong")
	DirAccess.remove_absolute(path)


func test_a_cleansed_grove_is_counted_and_the_great_tiger_has_a_word() -> void:
	var village := Village.new()
	village.take_earnings({"grove": true, "time": 0.0, "cleansed": true})
	check(village.groves_cleansed == 1 and village.offerings == Village.CLEANSED_OFFERINGS, "a cleansed grove wasn't counted, or gave nothing")
	check(village.has_tidings("shrine"), "the Great Tiger had nothing to say at the shrine")
	village.hear("shrine")
	for count in 5:
		village.take_earnings({"grove": true, "time": 0.0, "cleansed": true})
		village.hear("shrine")
	check(village.groves_cleansed == 6, "six cleansed groves weren't six")


func test_jogiboy_smells_green_promise_once() -> void:
	var village := Village.new()
	village.take_earnings({"grove": true, "time": 0.0, "crew_came": true})
	check(village.has_tidings("jogiboy"), "Jogiboy didn't smell the palm plantation on him")
	village.jogiboy_found = 0
	village.hear("jogiboy")
	village.take_earnings({"grove": true, "time": 0.0, "crew_came": true})
	check(not village.has_tidings("jogiboy"), "Jogiboy said it twice")
