extends TestCase
## What each thing he fights with has done: hits land harder in steps with critical chance (past
## 100%, every hit a step up and the rest a chance of one more), each hit is tallied to what landed
## it, and every run is kept in the history to look back over.


func test_critical_past_a_hundred_keeps_stepping_up() -> void:
	var arena := Arena.new()
	check(arena.critical_tier(0.0) == 0, "no critical chance landed a critical")
	var tiers := {}
	for roll in 400:
		tiers[arena.critical_tier(1.3)] = true
	check(tiers.keys().all(func(tier: int) -> bool: return tier in [1, 2]) and tiers.size() == 2, "130%% critical landed tiers %s, not 1 and 2" % [tiers.keys()])
	for roll in 50:
		check(arena.critical_tier(3.0) == 3, "300% critical didn't always land three steps up")


func test_each_hit_is_tallied_to_what_landed_it() -> void:
	var arena := Arena.new()
	arena.spawning = false
	var cat := arena.add_cat(Vector2(10.0, 10.0))
	var rat := arena.add_creature(Vector2(11.0, 10.0))
	rat.health = 100.0
	arena.strike(rat, 3.0, Vector2.RIGHT, 0.0, 0.0, "round", cat, "handgun")
	arena.strike(rat, 2.0, Vector2.RIGHT, 0.0, 0.0, "pounce", cat)
	check(is_equal_approx(cat.dealt.get("handgun", 0.0), 3.0) and is_equal_approx(cat.dealt.get("pounce", 0.0), 2.0), "the tally read %s" % cat.dealt)
	var event: Dictionary = arena.events[-1]
	check(event.get("ours", false) and is_equal_approx(event.get("damage", 0.0), 2.0) and event.get("tier", -1) == 0, "the hit's event read %s" % event)
	# Only what it had left counts: overkill isn't damage done.
	rat.health = 1.0
	arena.strike(rat, 50.0, Vector2.RIGHT, 0.0, 0.0, "round", cat, "handgun")
	check(is_equal_approx(cat.dealt.handgun, 4.0) and cat.finished.get("handgun", 0) == 1, "the finishing hit counted %.1f, %d kills" % [cat.dealt.handgun, cat.finished.get("handgun", 0)])
	var rows := Overlay.damage_rows(cat, 10.0)
	check(rows[0].name == "Handgun" and is_equal_approx(rows[0].share, 4.0 / 6.0) and is_equal_approx(rows[0].per_second, 0.4), "the table's first row read %s" % rows[0])
	check(Overlay.source_name("pounce") == "Pounce" and Overlay.source_name("gun_drone") == "Gun drone", "sources weren't named")


func test_runs_are_kept_in_the_history_newest_first() -> void:
	var path := "user://test_records_history.cfg"
	var records := Records.new()
	var arena := Arena.new()
	var cat := arena.add_cat(Vector2(10.0, 10.0))
	cat.dealt = {"handgun": 120.0, "pounce": 30.0}
	for run in Records.MOST_HISTORY + 3:
		arena.kills = run
		records.remember(Records.entry_of(arena, cat, "Endless"))
	check(records.history.size() == Records.MOST_HISTORY and records.history[0].kills == Records.MOST_HISTORY + 2, "the history kept %d, the newest with %d kills" % [records.history.size(), records.history[0].kills])
	check(records.save(path), "couldn't save")
	var back := Records.new()
	back.load_from(path)
	check(back.history.size() == Records.MOST_HISTORY and back.history[0].damage.has("handgun"), "the history came back as %d runs" % back.history.size())
	DirAccess.remove_absolute(path)
