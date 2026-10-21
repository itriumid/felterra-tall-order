extends TestCase
## Rescue and salvage: standing by a cage picks its lock, leaving lets the pick slip back, a freed
## cat runs home and is counted; what she breaks throws out salvage, and walking over it takes it.
## What a run brings home goes to the village, and stays there until progress is reset.


func _arena() -> Arena:
	var arena := Arena.new()
	arena.spawning = false
	return arena


func test_standing_by_a_cage_picks_its_lock() -> void:
	var arena := _arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	var cage := arena.add_cage(cat.body.position + Vector2(0.5, 0.0))
	for step in ceili(Cage.PICK_TIME / Arena.STEP) - 10:
		arena.step()
	check(not cage.opened, "the lock gave before its time")
	for step in 20:
		arena.step()
	check(cage.opened and arena.rescued.size() == 1, "she stood by it for %.0f seconds and it stayed shut" % Cage.PICK_TIME)
	check(arena.rescued[0].name in Cage.NAMES and arena.rescued[0].coat in Cage.COATS, "the rescued cat came out as %s" % str(arena.rescued[0]))


func test_leaving_lets_the_pick_slip_back() -> void:
	var arena := _arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	var cage := arena.add_cage(cat.body.position + Vector2(0.5, 0.0))
	for step in 60:
		arena.step()
	var picked := cage.picked
	cat.body.position += Vector2(0.0, 4.0)
	for step in 60:
		arena.step()
	check(cage.picked < picked and not cage.opened, "she walked off and the pick held at %.2f" % cage.picked)


func test_a_freed_cat_runs_home() -> void:
	var arena := _arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	var cage := arena.add_cage(cat.body.position + Vector2(0.5, 0.0))
	cage.picked = 0.999
	arena.step()
	check(cage.opened, "the lock didn't give")
	for step in 60 * 10:
		arena.step()
	check(arena.cages.is_empty(), "the freed cat never made it home")


func test_cages_turn_up_away_from_her() -> void:
	var arena := Arena.new()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.health = 1.0e9
	arena._since_cage = Arena.CAGE_INTERVAL - 0.5
	for step in 60:
		arena.step()
	check(arena.cages.size() == 1, "%d cages turned up" % arena.cages.size())
	check(arena.cages[0].body.position.distance_to(cat.body.position) >= Arena.CAGE_DISTANCE - 0.5, "a cage turned up right by her")


func test_breaking_things_throws_out_salvage_and_walking_over_it_takes_it() -> void:
	var arena := _arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	var giant := arena.add_giant(cat.body.position + Vector2(4.0, 0.0))
	arena.strike(giant, 1000.0, Vector2.RIGHT, 0.0, 0.0, "round", cat)
	check(arena.pickups.size() == Arena.SALVAGE.worker, "a felled worker threw out %d pieces" % arena.pickups.size())
	for step in 120:
		arena.step()
	for piece in arena.pickups.duplicate():
		cat.body.position = piece.body.position
		arena.step()
	check(arena.salvage == Arena.SALVAGE.worker and arena.pickups.is_empty(), "she walked over it all and took %d" % arena.salvage)


func test_what_a_run_brings_home_stays_until_reset() -> void:
	var arena := _arena()
	arena.rescued.append({"name": "Oyen", "coat": "orange"})
	arena.salvage = 7
	var village := Village.new()
	village.bring_home(arena)
	village.bring_home(arena)
	var path := "user://test_village.cfg"
	check(village.save(path), "the village didn't save")
	var loaded := Village.new()
	loaded.load_from(path)
	check(loaded.cats.size() == 2 and loaded.salvage == 14, "the village came back with %d cats and %d salvage" % [loaded.cats.size(), loaded.salvage])
	loaded.clear()
	loaded.save(path)
	var reset := Village.new()
	reset.load_from(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(reset.cats.is_empty() and reset.salvage == 0, "after a reset, the village still had %d cats" % reset.cats.size())
