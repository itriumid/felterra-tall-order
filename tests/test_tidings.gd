extends TestCase
## What's new in the village waits where it's told, under a "!", until he goes and hears it:
## Jogiboy keeps what he digs up until he's asked, and Pak Besi's word on starting weapons is what
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


func test_starting_weapons_are_chosen_only_once_taught() -> void:
	var village := Village.new()
	check(not village.repack("weapon:knife") or village.starters == Village.DEFAULT_STARTERS, "the knife started a run before Pak Besi taught it")
	village.left_home.clear()
	village.tell("smithy", "Pak Besi", "Choose them.", Village.STARTERS_TAUGHT)
	village.hear("smithy")
	check(village.starters_taught(), "hearing Pak Besi didn't teach choosing")
	check(village.repack("weapon:knife") and village.starters == ["weapon:knife", "weapon:handgun"], "the knife didn't start a run: %s" % [village.starters])
	check(village.repack("weapon:ketapel") and village.starters == ["weapon:knife", "weapon:ketapel"], "the slingshot didn't start as the one he shoots: %s" % [village.starters])
	# One he swings and one he shoots: a blade never takes the gun's place.
	check(village.repack("weapon:golok") and village.starters == ["weapon:golok", "weapon:ketapel"], "the golok took the wrong place: %s" % [village.starters])
	check(village.cant_leave_home("weapon:golok") != "", "a starter could be left home")
	# Again: the village's own starts instead, and with too few packed to leave it, it's taken along.
	check(village.repack("weapon:golok") and village.starters == ["weapon:nunchaku", "weapon:ketapel"], "the golok stayed a starter: %s" % [village.starters])
	check(village.packed("weapon:golok"), "the golok was left home with too few weapons packed")
	# The village's own two are never left home.
	village.repack("weapon:handgun")
	check(not village.repack("weapon:handgun") and village.packed("weapon:handgun"), "the handgun was left home")


func test_starters_and_news_come_back_as_they_were_kept() -> void:
	var path := "user://test_village_tidings.cfg"
	var village := Village.new()
	village.told.append(Village.STARTERS_TAUGHT)
	village.repack("weapon:knife")
	village.tell("board", "On the map", "Choose it.")
	village.jogiboy_found = 4
	check(village.save(path), "couldn't save")
	var back := Village.new()
	back.load_from(path)
	check(back.starters == ["weapon:knife", "weapon:handgun"], "the starters came back as %s" % [back.starters])
	check(back.has_tidings("board") and back.jogiboy_found == 4, "the news or Jogiboy's find didn't come back")
	# Kept by hand: a starter not his, or of the wrong sort, goes back to the village's own.
	var file := ConfigFile.new()
	file.load(path)
	file.set_value("village", "starters", ["weapon:handgun", "weapon:rifle"])
	file.save(path)
	back.load_from(path)
	check(back.starters == Village.DEFAULT_STARTERS, "starters off the rules came back as %s" % [back.starters])
	DirAccess.remove_absolute(path)
