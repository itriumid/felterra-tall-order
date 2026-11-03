class_name Records
extends RefCounted
## The best run so far: longest survived, highest level, most kills, most giants felled, most
## machines broken. Kept in the player's data folder beside the settings. A crew's run, with Nine
## Lives between them, has its own best, on one screen or online: it isn't measured against one
## cat's.

const PATH := "user://records.cfg"
const KEYS: Array[String] = ["time", "level", "kills", "giants", "machines"]

var best := {"time": 0.0, "level": 0, "kills": 0, "giants": 0, "machines": 0}
var crew := {"time": 0.0, "level": 0, "kills": 0, "giants": 0, "machines": 0}
## The runs before this one, newest first, so many kept: where, how long, how far, what he took
## and what each thing did, to look back over and see what worked.
var history: Array[Dictionary] = []
const MOST_HISTORY := 20


## A run as it's kept in the history, from its arena and his cat: where it was, how it went, what
## he fought with and wore, and the damage each thing did (the most first, six at most).
static func entry_of(arena: Arena, cat: Cat, where: String, freed := false) -> Dictionary:
	var dealt: Array = cat.dealt.keys()
	dealt.sort_custom(func(a: String, b: String) -> bool: return cat.dealt[a] > cat.dealt[b])
	var damage := {}
	for key: String in dealt.slice(0, 6):
		damage[key] = snappedf(cat.dealt[key], 0.1)
	var weapons: Array[String] = []
	for weapon in cat.weapons:
		weapons.append(weapon.name)
	var gear: Array[String] = []
	for slot: String in cat.gear:
		gear.append(cat.gear[slot])
	return {
		"when": int(Time.get_unix_time_from_system()), "where": where, "crew": arena.together(), "freed": freed,
		"time": arena.time, "level": arena.level, "kills": arena.kills, "weapons": weapons, "gear": gear, "damage": damage,
	}


## Keeps a run at the top of the history, letting the oldest go past the most kept.
func remember(run: Dictionary) -> void:
	history.insert(0, run)
	if history.size() > MOST_HISTORY:
		history.resize(MOST_HISTORY)


## A run's numbers, from its arena.
static func of(arena: Arena) -> Dictionary:
	return {"time": arena.time, "level": arena.level, "kills": arena.kills, "giants": arena.giants_felled, "machines": arena.machines_broken}


## Takes a run's numbers and returns which of them beat the best, one cat's or a crew's, keeping
## those as the new best. A number the run doesn't have counts as none of it.
func record(run: Dictionary, together := false) -> Array[String]:
	var beaten: Array[String] = []
	var kept := crew if together else best
	for key in KEYS:
		if run.get(key, 0) > kept[key]:
			kept[key] = run[key]
			beaten.append(key)
	return beaten


func save(path := PATH) -> bool:
	var file := ConfigFile.new()
	for key in KEYS:
		file.set_value("best", key, best[key])
		file.set_value("crew", key, crew[key])
	file.set_value("history", "runs", history)
	return file.save(path) == OK


## Back to nothing: no best run yet.
func clear() -> void:
	best = {"time": 0.0, "level": 0, "kills": 0, "giants": 0, "machines": 0}
	crew = {"time": 0.0, "level": 0, "kills": 0, "giants": 0, "machines": 0}
	history.clear()


func load_from(path := PATH) -> void:
	var file := ConfigFile.new()
	if file.load(path) != OK:
		return
	for key in KEYS:
		var saved: Variant = file.get_value("best", key, best[key])
		if typeof(saved) == typeof(best[key]):
			best[key] = saved
		var together: Variant = file.get_value("crew", key, crew[key])
		if typeof(together) == typeof(crew[key]):
			crew[key] = together
	# The history, keeping only runs that read as runs: a hand-edited or older file loads what it can.
	history.clear()
	var runs: Variant = file.get_value("history", "runs", [])
	if runs is Array:
		for run: Variant in runs:
			if run is Dictionary and run.get("where") is String and (run.get("time") is float or run.get("time") is int) \
					and run.get("level") is int and run.get("kills") is int and run.get("damage") is Dictionary:
				history.append(run)
			if history.size() >= MOST_HISTORY:
				break
