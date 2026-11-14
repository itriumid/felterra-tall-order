extends SceneTree
## Plays whole Endless runs headless with Autoplay, and prints a line a minute: the level, his
## health, the horde, what's been killed, the damage a second, what a step of the world cost (on
## average, and its slowest), and what he's carrying. For the balance (how long a strong build
## lasts) and the late game's cost, without playing to it. Run with:
## timeout 900 godot --headless --path . --script tools/simulate_endless.gd -- --minutes=25
## and add --seed=<number> (or --seeds=<from>-<to> for several), --start=<weapon> for what he
## starts with (the handgun unless given), --from-minute=<count> and --level=<count> to start late,
## as the game's --minute and --level do.
##
## Autoplay is worse than a person at all of it: a run it survives, a player should.

const STEPS_A_MINUTE := 3600


func _init() -> void:
	var minutes := 20
	var seeds: Array[int] = [1]
	var start := "handgun"
	var from_minute := 0.0
	var level := 0
	for argument in OS.get_cmdline_user_args():
		var value := argument.get_slice("=", 1)
		if argument.begins_with("--minutes="):
			minutes = value.to_int()
		elif argument.begins_with("--seed="):
			seeds = [value.to_int()]
		elif argument.begins_with("--seeds="):
			seeds.clear()
			for each in range(value.get_slice("-", 0).to_int(), value.get_slice("-", 1).to_int() + 1):
				seeds.append(each)
		elif argument.begins_with("--start="):
			start = value
		elif argument.begins_with("--from-minute="):
			from_minute = value.to_float()
		elif argument.begins_with("--level="):
			level = value.to_int()
	var lasted: Array[String] = []
	for seed_value in seeds:
		lasted.append(_play(seed_value, minutes, start, from_minute, level))
	print("\nlasted: " + ", ".join(lasted))
	quit()


## One run, a line a minute; returns how long it lasted, as minutes and seconds.
func _play(seed_value: int, minutes: int, start: String, from_minute: float, level: int) -> String:
	var arena := Arena.new(seed_value)
	arena.shape(seed_value)
	var cat := arena.add_cat(arena.size / 2.0)
	cat.weapons.clear()
	cat.first_pool.assign([start])
	arena.head_start = from_minute <= 0.0 and level <= 0
	if not arena.head_start:
		cat.wear({"weapons": [start]})
	arena.time = from_minute * 60.0
	while arena.level < level:
		arena._gain_experience(Arena.experience_needed(arena.level) - arena.experience)
		Autoplay.play_all(cat)
	print("seed %d, starting with the %s%s" % [seed_value, start, (" at minute %d, level %d" % [from_minute, arena.level]) if not arena.head_start else ""])
	var hits_seen := 0
	var dealt_before := 0.0
	for minute in minutes:
		var started := Time.get_ticks_usec()
		var slowest := 0.0
		var stepped := 0
		for step in STEPS_A_MINUTE:
			if not cat.alive():
				break
			Autoplay.play_all(cat)
			cat.steering = Autoplay.steer(cat, arena)
			# Hit, it dodges: the one thing a player always does.
			if cat.hits_taken != hits_seen:
				hits_seen = cat.hits_taken
				cat.dodge()
			var before := Time.get_ticks_usec()
			arena.step()
			slowest = maxf(slowest, (Time.get_ticks_usec() - before) / 1000.0)
			stepped += 1
			arena.events.clear()
		var dealt := 0.0
		for key: String in cat.dealt:
			dealt += cat.dealt[key]
		var carrying: Array[String] = []
		for weapon in cat.weapons:
			carrying.append("%s %d" % [weapon.name, weapon.level])
		print("  minute %2d  level %3d  health %5.1f of %5.1f  horde %3d  giants %d  kills %6d  %6.1f damage a second  a step %.2f ms (slowest %.1f)  %s" % [
			int(arena.time / 60.0), arena.level, cat.health, cat.max_health, arena.creatures.size(), arena.giants.size(),
			arena.kills, (dealt - dealt_before) / maxf(stepped * Arena.STEP, 0.001), (Time.get_ticks_usec() - started) / 1000.0 / maxi(stepped, 1),
			slowest, ", ".join(carrying)])
		dealt_before = dealt
		if not cat.alive():
			print("  down at %s, to a %s" % [_clock(arena.time), cat.last_hurt_by if not cat.last_hurt_by.is_empty() else "something"])
			return _clock(arena.time)
	return _clock(arena.time) + " and standing"


static func _clock(seconds: float) -> String:
	return "%d:%02d" % [int(seconds / 60.0), int(seconds) % 60]
