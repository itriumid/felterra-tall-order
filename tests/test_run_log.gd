extends TestCase
## The run log, for playtesters: off unless turned on, a line a run on this computer, saying how
## it went, what he carried and what got him.

const PATH := "user://test_run_log.jsonl"


func _finished_run() -> Array:
	var arena := Arena.new()
	arena.spawning = false
	var cat := arena.add_cat(arena.size / 2.0)
	cat.wear({"weapons": ["handgun", "ketapel"]})
	Upgrades.apply(cat, {"id": "gear:boots", "rarity": 0})
	cat.dealt = {"handgun": 120.0, "ketapel": 40.0}
	arena.time = 412.5
	var rat := arena.add_creature(cat.body.position + Vector2(0.1, 0.0))
	cat.health = 0.5
	arena.step()
	return [arena, cat]


func test_it_is_off_unless_turned_on() -> void:
	check(Settings.new().get_value("gameplay", "run_log") == false, "the run log is on for everyone")


func test_a_run_says_how_it_went_what_he_carried_and_what_got_him() -> void:
	var run := _finished_run()
	var cat: Cat = run[1]
	check(not cat.alive(), "the test wants him down")
	var entry := RunLog.entry_of(run[0], cat, "Endless", false, 39, {"lowest": 41.0, "average": 58.2})
	check(entry.outcome == "down" and entry.got_him == "rat", "it says he went %s to %s" % [entry.outcome, entry.got_him])
	check(entry.seconds == 412.5 and entry.seed == 39 and entry.crew == 1, "how long, which clearing or who was there is wrong: %s" % entry)
	check((entry.weapons as Array).size() == 2 and entry.weapons[0].name == "handgun", "what he carried isn't there: %s" % [entry.weapons])
	check(entry.gear.feet.name == "boots", "his gear isn't there: %s" % [entry.gear])
	check(entry.damage.handgun == 120.0, "what did the damage isn't there: %s" % [entry.damage])
	check(entry.frames_a_second.lowest == 41.0, "how smoothly it ran isn't there")
	var parsed: Variant = JSON.parse_string(JSON.stringify(entry))
	check(parsed is Dictionary, "it doesn't write as JSON")


func test_each_run_is_a_line_of_its_own() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	var run := _finished_run()
	for index in 3:
		check(RunLog.append(RunLog.entry_of(run[0], run[1], "Endless", false, index, {}), PATH), "a run couldn't be written")
	var lines := FileAccess.get_file_as_string(PATH).strip_edges().split("\n")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	check(lines.size() == 3, "three runs made %d lines" % lines.size())
	for index in lines.size():
		var parsed: Variant = JSON.parse_string(lines[index])
		check(parsed is Dictionary and int(parsed.seed) == index, "line %d isn't its run on its own" % index)
