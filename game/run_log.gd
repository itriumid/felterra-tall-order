class_name RunLog
extends RefCounted
## The run log, for playtesters: with its setting on, every run that ends adds a line to a file on
## this computer, saying how it went (where, how long, what level, what got him), what he carried,
## what did the damage, and how smoothly the game ran. Nothing is sent anywhere: a playtester who
## wants to help sends the file themselves. Off unless they turn it on.
##
## One JSON object a line, so a line can be read on its own and a file cut short loses one run, not
## all of them.

const PATH := "user://run_log.jsonl"
## Past this many bytes, the oldest runs go, keeping the newest KEPT_WHEN_TRIMMED.
const MOST_BYTES := 1_000_000
const KEPT_WHEN_TRIMMED := 300


## A run as the log keeps it. `smoothness` is {lowest, average}: frames a second over the run.
static func entry_of(arena: Arena, cat: Cat, where: String, freed: bool, seed_value: int, smoothness: Dictionary) -> Dictionary:
	var dealt: Array = cat.dealt.keys()
	dealt.sort_custom(func(a: String, b: String) -> bool: return cat.dealt[a] > cat.dealt[b])
	var damage := {}
	for key: String in dealt.slice(0, 8):
		damage[key] = snappedf(cat.dealt[key], 0.1)
	var weapons: Array[Dictionary] = []
	for weapon in cat.weapons:
		weapons.append({"name": weapon.name, "level": weapon.level, "evolved": weapon.evolved, "bonuses": Array(weapon.bonuses)})
	var gear := {}
	for slot: String in cat.gear:
		gear[slot] = {"name": cat.gear[slot], "level": cat.gear_levels.get(cat.gear[slot], 1)}
	var support := {}
	for slot: String in cat.supports:
		support[slot] = {"name": (cat.supports[slot] as Support).name, "level": (cat.supports[slot] as Support).level}
	return {
		"version": ProjectSettings.get_setting("application/config/version", ""),
		"when": Time.get_datetime_string_from_system(true),
		"where": where, "seed": seed_value, "crew": arena.cats.size(),
		"outcome": "freed" if freed else ("down" if not cat.alive() else "left"),
		"got_him": cat.last_hurt_by if not cat.alive() else "",
		"seconds": snappedf(arena.time, 0.1), "level": arena.level, "kills": arena.kills,
		"giants": arena.giants_felled, "machines": arena.machines_broken, "rescued": arena.rescued.size(),
		"health": snappedf(cat.max_health, 0.1), "armor": snappedf(cat.armor, 0.01),
		"weapons": weapons, "gear": gear, "support": support, "mutations": cat.mutations.keys(),
		"damage": damage, "frames_a_second": smoothness,
	}


## Adds a run to the end of the log, trimming the oldest once it's grown past MOST_BYTES. Returns
## whether it was written.
static func append(entry: Dictionary, path := PATH) -> bool:
	var lines: PackedStringArray = []
	if FileAccess.file_exists(path):
		var existing := FileAccess.open(path, FileAccess.READ)
		if existing == null:
			return false
		if existing.get_length() > MOST_BYTES:
			lines = existing.get_as_text().strip_edges().split("\n")
			lines = lines.slice(maxi(lines.size() - KEPT_WHEN_TRIMMED + 1, 0))
		existing.close()
	if not lines.is_empty():
		var rewritten := FileAccess.open(path, FileAccess.WRITE)
		if rewritten == null:
			return false
		for line in lines:
			rewritten.store_line(line)
		rewritten.store_line(JSON.stringify(entry))
		return true
	var file := FileAccess.open(path, FileAccess.READ_WRITE if FileAccess.file_exists(path) else FileAccess.WRITE)
	if file == null:
		return false
	file.seek_end()
	file.store_line(JSON.stringify(entry))
	return true
